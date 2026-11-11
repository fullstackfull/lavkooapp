import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:syriapharmacy/data/model/api_response.dart';
import 'package:syriapharmacy/data/services/analytics_reporter.dart';
import 'package:syriapharmacy/features/dynamic_theme/domain/models/theme_schema.dart';
import 'package:syriapharmacy/features/dynamic_theme/domain/services/dynamic_theme_service_interface.dart';

/// Holds the published home page, and keeps it fresh without ever showing a blank one.
///
/// The order matters more than any single step:
///
///   1. read the cache and render it immediately — the shopper sees a home page on the first
///      frame, offline or not;
///   2. ask the cheap version endpoint whether anything changed;
///   3. download the page only when it did;
///   4. keep what is already on screen if any of that fails.
///
/// Step 4 is the rule the whole class is built around. There is no state in which a network
/// problem empties the home page: a failed sync leaves the cached payload exactly where it was,
/// and a first run with no cache reports "no theme" so the caller can render the app's built-in
/// home instead of an empty scroll.
class DynamicThemeController extends ChangeNotifier with WidgetsBindingObserver {
  DynamicThemeController({required this.dynamicThemeServiceInterface}) {
    // The controller owns its own resume trigger, so no screen has to remember to wire one: a
    // merchant who publishes while the shopper has the app backgrounded is picked up on the next
    // look, whichever home screen happens to be showing. Guarded because unit tests — and any
    // headless context — construct this before a widgets binding exists.
    try {
      WidgetsBinding.instance.addObserver(this);
    } catch (_) {}
  }

  final DynamicThemeServiceInterface dynamicThemeServiceInterface;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // One version request per resume; only a moved revision costs a download.
    if (state == AppLifecycleState.resumed) sync();
  }

  @override
  void dispose() {
    try {
      WidgetsBinding.instance.removeObserver(this);
    } catch (_) {}
    super.dispose();
  }

  ThemePayload _payload = ThemePayload.none;

  /// The header page's sections — where the builder puts the announcement bar. Fetched with the
  /// home page because they render as one screen; a merchant who adds a bar "above the header"
  /// expects it above the app's home too.
  ThemePayload _header = ThemePayload.none;

  bool _isLoading = false;
  bool _hasSyncedThisSession = false;
  String? _lastError;

  /// Section data fetched from each section's own source, keyed by section uuid.
  final Map<String, ApiResponseModel> _sectionData = {};
  final Set<String> _sectionsLoading = {};

  /// When a section's fetch last failed. Retries wait out a cooldown, because renderers ask on
  /// every build: without it, a dead endpoint would be re-requested on every scroll frame.
  final Map<String, DateTime> _sectionFailedAt = {};
  static const Duration _sectionRetryAfter = Duration(seconds: 30);

  /// Pages other than home, kept by slug.
  ///
  /// Separate from [_payload] on purpose: the home page is fetched on launch and syncs on resume,
  /// and a page a shopper opened once should not compete with it for that slot. Each of these is
  /// fetched when its screen opens and kept for as long as the app runs, which is the right
  /// lifetime for something a merchant republishes rarely and a shopper revisits often.
  final Map<String, ThemePayload> _pages = {};
  final Set<String> _pagesLoading = {};
  final Set<String> _pagesFailed = {};

  /// Bumped whenever the shopper's language changes. A page fetch that started under the old
  /// language must not populate [_pages] after the switch: the payload it carries is spelled in
  /// the language the shopper just left.
  int _languageEpoch = 0;

  /// A language switch that arrived while a sync was in flight; honored the moment it ends.
  bool _pendingLanguageRefresh = false;

  ThemePayload get payload => _payload;
  List<ThemeSectionSchema> get sections => _payload.sections;
  List<ThemeSectionSchema> get headerSections => _header.sections;

  /// A composed page other than home, or null while it is still being fetched.
  ThemePayload? page(String slug) => _pages[slug];

  bool isPageLoading(String slug) => _pagesLoading.contains(slug);

  /// Whether the last fetch of this page ended without a page — the screen shows a retry
  /// instead of a spinner that spins forever over a dead request.
  bool pageFailed(String slug) => _pagesFailed.contains(slug);

  /// Fetch a composed page by slug, once.
  ///
  /// Failure leaves the page absent AND marked, so the screen can say "couldn't load" with a
  /// retry — an empty page would tell the shopper something untrue about the shop, and an
  /// eternal spinner tells them nothing at all.
  Future<void> loadPage(String slug) async {
    if (_pages.containsKey(slug) || _pagesLoading.contains(slug)) return;

    _pagesLoading.add(slug);
    _pagesFailed.remove(slug);
    final epoch = _languageEpoch;

    try {
      final response = await dynamicThemeServiceInterface.getPayload(page: slug);

      // A fetch that started before a language switch carries the old language; the switch
      // already cleared the map, and this result must not sneak back in.
      if (epoch != _languageEpoch) return;

      if (response.isSuccess && response.response != null) {
        _pages[slug] = response.response!;
      } else if ('${response.error}' == 'page_gone') {
        // The server said 404: the page was removed or disabled. That is an answer, not a
        // failure — the screen shows "no content" instead of offering a retry that can never win.
        _pages[slug] = ThemePayload.none;
      } else {
        _pagesFailed.add(slug);
      }
    } catch (_) {
      if (epoch == _languageEpoch) _pagesFailed.add(slug);
    } finally {
      _pagesLoading.remove(slug);
      notifyListeners();
    }
  }

  /// Try a failed page again — the screen's retry button.
  Future<void> retryPage(String slug) {
    _pagesFailed.remove(slug);
    _pages.remove(slug);
    return loadPage(slug);
  }
  ThemeTokens get tokens => _payload.tokens;
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;

  /// Whether the server-driven page should replace the app's built-in home.
  ///
  /// False on a first run with no network, on a shop that has never published a theme, and on a
  /// published theme whose sections this build cannot draw — all three are cases where the
  /// hardcoded home is the better page, and none of them is an error.
  bool get hasPublishedTheme => _payload.isRenderable;

  /// Section types the server withheld from this build. Read by the diagnostics view; a
  /// non-empty map means an app update would show more of the merchant's page.
  Map<String, String> get withheldTypes => _payload.withheld;

  // -------------------------------------------------------------------------------------------

  /// Render whatever is cached, then check for something newer.
  ///
  /// Safe to call on every cold start, resume and pull-to-refresh. [force] skips the version check
  /// and downloads unconditionally, which is what a manual refresh means.
  Future<void> sync({String page = 'home', bool force = false}) async {
    if (_isLoading) return;

    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      // The cached page goes on screen before anything touches the network, and only on the first
      // sync of a session — after that, what is already in memory is at least as fresh.
      if (!_hasSyncedThisSession && !_payload.isRenderable) {
        final cached = await dynamicThemeServiceInterface.getCachedPayload(page: page);
        final cachedHeader =
            await dynamicThemeServiceInterface.getCachedPayload(page: 'header');
        if (cached != null) {
          _payload = cached;
          _header = cachedHeader ?? ThemePayload.none;
          notifyListeners();
        }
      }

      try {
        await _revalidate(page: page, force: force);
      } catch (error) {
        // A sync that dies mid-air (a parse, an unexpected null) is a failed sync, not an
        // unhandled exception: the shopper keeps whatever renders, and the next resume retries.
        _lastError = '$error';
        if (kDebugMode) debugPrint('[theme] sync crashed: $error');
      }
      _hasSyncedThisSession = true;
    } finally {
      _isLoading = false;
      notifyListeners();

      // A language switch that landed while this sync ran was deferred, not dropped.
      if (_pendingLanguageRefresh) {
        _pendingLanguageRefresh = false;
        await refresh();
      }
    }
  }

  Future<void> _revalidate({required String page, required bool force}) async {
    if (!force) {
      final revision = await dynamicThemeServiceInterface.getRevision();

      if (revision.revision == 0) {
        // Revision 0 has TWO faces, and confusing them is catastrophic either way. The SERVER
        // answering zero (schemaVersion travels, so it is >= 1) means the merchant unpublished:
        // the cache must go, or a withdrawn theme returns on every cold start forever. The
        // version check FAILING (offline — everything zero) means nothing at all: the cache is
        // exactly what a shopper with no signal should keep seeing.
        final serverSaidNothingPublished = revision.schemaVersion > 0;

        if (serverSaidNothingPublished) {
          _sectionData.clear();
          _sectionFailedAt.clear();
          _pages.clear();
          _payload = ThemePayload.none;
          _header = ThemePayload.none;
          await dynamicThemeServiceInterface.dropCachedPayloads();
        } else if (!_payload.isRenderable) {
          _payload = ThemePayload.none;
        }

        return;
      }
      if (!revision.isNewerThan(_payload)) return;
    }

    final response = await dynamicThemeServiceInterface.getPayload(
      page: page,
      // Sent even when the revision moved: a rollback can republish content this client already
      // holds, and the ETag is what turns that into a 304 instead of a wasted download.
      knownChecksum: _payload.checksum,
    );

    if (!response.isSuccess) {
      _lastError = '${response.error}';
      if (kDebugMode) debugPrint('[theme] sync failed: ${response.error}');
      return;
    }

    // A null payload on success is a 304: what is held is current.
    final fresh = response.response;
    if (fresh == null) return;

    if (!fresh.isRenderable && _payload.isRenderable) {
      // The server now has nothing to show this build. Keeping the page already on screen is the
      // wrong call — the merchant may have unpublished it deliberately — so it is dropped, and
      // the caller falls back to the built-in home.
      _sectionData.clear();
      _sectionFailedAt.clear();
      _payload = ThemePayload.none;
      _header = ThemePayload.none;
      return;
    }

    if (fresh.checksum != _payload.checksum) {
      // Section data is keyed by uuid and a republish can change what a section shows without
      // changing its uuid, so the fetched data is dropped and re-resolved against the new page.
      _sectionData.clear();
      _sectionFailedAt.clear();
      _sectionsLoading.clear();
      // Other pages were published in the same operation; holding yesterday's copy of one would
      // be the only stale thing in an otherwise fresh app.
      _pages.clear();
      // A new arrangement is a new thing to have been seen: what this session already counted was
      // counted against the page the merchant has just replaced.
      AnalyticsReporter.resetSectionViews();
    }

    _payload = fresh;

    // The header rides the same publish, so it is only refetched when the home page moved — and
    // its own checksum still turns an unchanged header into a 304. A header fetch failing costs
    // the announcement bar, never the page: the home payload above is already committed.
    final headerResponse = await dynamicThemeServiceInterface.getPayload(
      page: 'header',
      knownChecksum: _header.checksum,
    );
    if (headerResponse.isSuccess) {
      _header = headerResponse.response ?? _header;
    }
  }

  // -------------------------------------------------------------------------------------------

  /// The data a section's own source produced, or null while it is still being fetched.
  ApiResponseModel? dataFor(ThemeSectionSchema section) => _sectionData[section.uuid];

  bool isSectionLoading(ThemeSectionSchema section) =>
      _sectionsLoading.contains(section.uuid);

  /// Fetch one section's data, once.
  ///
  /// Called by a renderer the first time it builds. Idempotent: a rebuild, a scroll back, or two
  /// renderers sharing a section will not fetch twice.
  Future<void> loadSectionData(ThemeSectionSchema section) =>
      loadKeyedData(section.uuid, section.source);

  /// The same idempotent fetch, addressed by an explicit key — for sections that hold several
  /// sources at once (product_tabs keeps one result per tab: `uuid#0`, `uuid#1`, …).
  Future<void> loadKeyedData(String key, SectionSource source) async {
    if (!source.isApi) return;
    // A SUCCESSFUL answer is kept for the run; a failure is not an answer. Remembering an error
    // forever meant one dropped request left a section empty until the next publish — now the
    // failure renders once, and the next rebuild that asks for this section simply retries.
    final held = _sectionData[key];
    if (held != null && held.isSuccess) return;
    if (_sectionsLoading.contains(key)) return;

    final failedAt = _sectionFailedAt[key];
    if (failedAt != null && DateTime.now().difference(failedAt) < _sectionRetryAfter) return;

    _sectionsLoading.add(key);

    try {
      final response = await dynamicThemeServiceInterface.getSectionData(source);

      _sectionData[key] = response;

      if (response.isSuccess) {
        _sectionFailedAt.remove(key);
      } else {
        _sectionFailedAt[key] = DateTime.now();
      }
    } catch (_) {
      // A thrown fetch is a failure like any other: without this, the section stayed marked
      // "loading" for the rest of the run and could never retry.
      _sectionFailedAt[key] = DateTime.now();
    } finally {
      _sectionsLoading.remove(key);
      notifyListeners();
    }
  }

  ApiResponseModel? keyedData(String key) => _sectionData[key];

  bool isKeyLoading(String key) => _sectionsLoading.contains(key);

  /// Drop everything and re-sync — the pull-to-refresh path.
  Future<void> refresh({String page = 'home'}) async {
    _sectionData.clear();
    _sectionFailedAt.clear();
    _sectionsLoading.clear();
    await sync(page: page, force: true);
  }

  /// The shopper switched language.
  ///
  /// The server folds every section's text to the `lang` header, so this is a content change the
  /// revision number knows nothing about: the same publish, different strings. Held pages are
  /// dropped first — they were fetched under the old header and would reopen in it — and the home
  /// page is refetched by force, because a version check would truthfully say nothing was
  /// republished.
  Future<void> onLanguageChanged() async {
    _languageEpoch++;
    _pages.clear();
    _pagesFailed.clear();

    // A sync already in flight swallows refresh() (sync returns early while loading) — the
    // switch would be silently dropped and the home page would stay in the old language. Flag
    // it instead; the running sync honors the flag the moment it ends.
    if (_isLoading) {
      _pendingLanguageRefresh = true;
      return;
    }

    await refresh();
  }
}
