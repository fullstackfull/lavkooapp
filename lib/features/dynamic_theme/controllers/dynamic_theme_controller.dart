import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:syriapharmacy/data/model/api_response.dart';
import 'package:syriapharmacy/data/services/analytics_reporter.dart';
import 'package:syriapharmacy/features/dynamic_theme/domain/models/theme_schema.dart';
import 'package:syriapharmacy/features/dynamic_theme/domain/services/dynamic_theme_service_interface.dart';
import 'package:syriapharmacy/features/dynamic_theme/theme_preview.dart';
import 'package:syriapharmacy/features/storefront/storefront_change_notifier.dart';
import 'package:syriapharmacy/features/storefront/storefront_scope.dart';

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
class DynamicThemeController extends ChangeNotifier
    with WidgetsBindingObserver, StorefrontChangeAware {
  DynamicThemeController({
    required this.dynamicThemeServiceInterface,
    StorefrontChangeNotifier? storefrontChangeNotifier,
  }) {
    followStorefrontChanges(storefrontChangeNotifier);
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

  /// Bumped whenever the shopper's language or storefront changes. A page fetch that started under
  /// the old one must not populate [_pages] after the switch: the payload it carries is spelled in
  /// the language the shopper just left, or is another storefront's page.
  int _contentEpoch = 0;

  /// A language switch that arrived while a sync was in flight; honored the moment it ends.
  bool _pendingLanguageRefresh = false;

  /// A storefront change that arrived while a sync was in flight; honored the moment it ends.
  bool _pendingStorefrontRefresh = false;

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
    final epoch = _contentEpoch;

    try {
      final response = await dynamicThemeServiceInterface.getPayload(page: slug);

      // A fetch that started before a language switch carries the old language; the switch
      // already cleared the map, and this result must not sneak back in.
      if (epoch != _contentEpoch) return;

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
      if (epoch == _contentEpoch) _pagesFailed.add(slug);
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

  /// Whether what is on screen is an unpublished DRAFT and not the shop (J-V1).
  ///
  /// Read off the page the server actually answered, not off the token this app sent: a token the
  /// server refused — expired, forged, or minted for another storefront's theme — is answered with
  /// the published page, and a notice over the real shop saying it is a draft would be a lie in the
  /// one place a merchant is deciding what to publish.
  bool get isShowingADraft => _payload.isDraft;

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

    // Everything this sync learns is about the storefront it started on. If the shopper moves to
    // another while it runs, what it has fetched is theirs no longer: it is not shown, and the
    // refresh that [onStorefrontChanged] asked for runs when this one ends.
    final String? storefront = StorefrontScope.current;

    // A draft is asked for by force, and never seeded from the cache. The version endpoint carries
    // no preview, so it answers the PUBLISHED revision: a version check would truthfully say
    // nothing had moved and the merchant would be shown the shop instead of the draft they asked
    // to see. And the cache only ever holds published pages, so seeding from it would put the shop
    // on screen under a notice saying it was a draft.
    final bool askingForADraft = ThemePreview.isAskingForADraft;

    try {
      // The cached page goes on screen before anything touches the network, and only on the first
      // sync of a session — after that, what is already in memory is at least as fresh.
      if (!_hasSyncedThisSession && !_payload.isRenderable && !askingForADraft) {
        final cached = await dynamicThemeServiceInterface.getCachedPayload(page: page);
        final cachedHeader =
            await dynamicThemeServiceInterface.getCachedPayload(page: 'header');
        if (cached != null && StorefrontScope.isCurrent(storefront)) {
          _payload = cached;
          _header = cachedHeader ?? ThemePayload.none;
          notifyListeners();
        }
      }

      try {
        await _revalidate(
            page: page,
            force: force || askingForADraft,
            storefront: storefront);
      } catch (error) {
        // A sync that dies mid-air (a parse, an unexpected null) is a failed sync, not an
        // unhandled exception: the shopper keeps whatever renders, and the next resume retries.
        _lastError = '$error';
        if (kDebugMode) debugPrint('[theme] sync crashed: $error');
      }
      if (StorefrontScope.isCurrent(storefront)) _hasSyncedThisSession = true;
    } finally {
      _isLoading = false;
      notifyListeners();

      // A language switch or a storefront change that landed while this sync ran was deferred,
      // not dropped.
      if (_pendingLanguageRefresh || _pendingStorefrontRefresh) {
        _pendingLanguageRefresh = false;
        _pendingStorefrontRefresh = false;
        await refresh();
      }
    }
  }

  Future<void> _revalidate({
    required String page,
    required bool force,
    required String? storefront,
  }) async {
    if (!force) {
      final revision = await dynamicThemeServiceInterface.getRevision();
      if (!StorefrontScope.isCurrent(storefront)) return;

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
    if (!StorefrontScope.isCurrent(storefront)) return;

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
    if (headerResponse.isSuccess && StorefrontScope.isCurrent(storefront)) {
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
    final String? storefront = StorefrontScope.current;

    try {
      final response = await dynamicThemeServiceInterface.getSectionData(source);

      // A section's data is the storefront's: what the one the shopper has left answered is not kept.
      if (!StorefrontScope.isCurrent(storefront)) return;

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
    _contentEpoch++;
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

  /// Show the unpublished draft a signed preview token names, on this phone, now (J-V1).
  ///
  /// Everything held is dropped FIRST, and before any await, exactly as a change of storefront
  /// drops it: half a published page beside half a draft is the one thing a merchant deciding what
  /// to publish must never be shown. The draft is then fetched by force.
  ///
  /// False, and nothing dropped or fetched, when this build accepts no preview token or the link
  /// carried none — so a build without the define, and a link without a token, behave exactly as
  /// they do today. [enabled] defaults to what this build accepts and is named only by a test, the
  /// way `OrderMarket` already takes the storefront switch, so that both answers are exercised by
  /// one build.
  Future<bool> showDraft(String? token,
      {bool enabled = ThemePreview.enabledInThisBuild}) async {
    if (!ThemePreview.show(token, enabled: enabled)) {
      return false;
    }

    await _startOver();

    return true;
  }

  /// Stop showing a draft and put the shop back, by force: the cache and the revision check both
  /// speak for the published page, which is precisely what has to come back.
  Future<void> stopShowingADraft() async {
    if (!ThemePreview.isAskingForADraft) {
      return;
    }

    ThemePreview.stop();

    await _startOver();
  }

  /// Drop every page, header and section this controller holds and fetch again by force.
  ///
  /// Shared by the two preview entry points above and by [onStorefrontChanged], which all three
  /// change what the theme endpoint will answer without changing any revision number the version
  /// check could notice. Everything is dropped BEFORE the first await, so the app's own home goes
  /// on screen at once rather than the page that is no longer the right one, and a sync already in
  /// flight is not trusted: it finishes without keeping what it fetched, and the refresh runs when
  /// it ends.
  Future<void> _startOver() async {
    _contentEpoch++;
    _pages.clear();
    _pagesFailed.clear();
    _sectionData.clear();
    _sectionFailedAt.clear();
    _sectionsLoading.clear();
    _payload = ThemePayload.none;
    _header = ThemePayload.none;
    _hasSyncedThisSession = false;
    _lastError = null;
    notifyListeners();

    if (_isLoading) {
      _pendingStorefrontRefresh = true;
      return;
    }

    await refresh();
  }

  /// The shopper moved to another storefront.
  ///
  /// The home page, its header, every page opened since and the data each section fetched all describe the storefront they left, and the
  /// version check on this build's revision knows nothing about it: the same revision number can be another storefront's page. So all of
  /// it is dropped, which is what puts the app's own home on screen at once instead of the other storefront's, and the page of the new
  /// storefront is read from the cache or fetched by force. A sync already in flight is not trusted either: it finishes without
  /// keeping what it fetched, and the refresh runs when it ends.
  @override
  Future<void> onStorefrontChanged(StorefrontChange change) => _startOver();
}
