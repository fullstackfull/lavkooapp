/// The theme schema as it arrives from `/api/v1/theme/home`.
///
/// Every field is optional and every parse is total: this data crosses a network from a system an
/// admin edits by hand, and a home page that throws on an unexpected key is a home page that
/// disappears the first time somebody publishes something unusual. Where a value cannot be read,
/// the model falls back rather than failing, and the section that owns it decides whether it can
/// still render.
///
/// The models are deliberately dumb — parsing and defaults only, no widgets, no navigation, no
/// network. That is what lets the parser be tested without a Flutter binding.
library;

/// One tap destination, resolved by the server into something a native client can route.
///
/// The server parses the merchant's storefront URL once and sends both: `type` plus its parameters
/// for the app, and `url` for anything the app cannot route natively.
class ThemeAction {
  const ThemeAction({
    required this.type,
    this.url,
    this.slug,
    this.id,
    this.query,
    this.collection,
    this.campaign,
    this.label,
  });

  final String type;
  final String? url;
  final String? slug;
  final int? id;
  final String? query;
  final String? collection;
  final String? campaign;

  /// The subject's display name, resolved by the shop — what the opened screen titles itself.
  /// Absent when the destination has no subject, or when the shop could not name it.
  final String? label;

  static const ThemeAction none = ThemeAction(type: 'none');

  bool get isNone => type == 'none';

  factory ThemeAction.fromJson(Map<String, dynamic>? json) {
    if (json == null) return none;

    final type = _asString(json['type']);
    if (type == null || type.isEmpty) return none;

    return ThemeAction(
      type: type,
      url: _asString(json['url']),
      slug: _asString(json['slug']),
      id: _asInt(json['id']),
      query: _asString(json['query']),
      collection: _asString(json['collection']),
      campaign: _asString(json['campaign']),
      label: _asString(json['label']),
    );
  }
}

/// Where a section's data lives: inline in this payload, behind an API, or nowhere yet.
class SectionSource {
  const SectionSource({
    required this.kind,
    this.endpoint,
    this.params = const {},
    this.note,
    this.endsAt,
    this.tabs = const [],
  });

  final String kind;
  final String? endpoint;
  final Map<String, dynamic> params;
  final String? note;

  /// When this source's urgency expires — a flash deal's end. Null for everything timeless.
  final DateTime? endsAt;

  /// One source per tab, for a tabbed section — in tab order.
  final List<SectionSource> tabs;

  static const SectionSource inline = SectionSource(kind: 'inline');

  bool get isApi => kind == 'api' && (endpoint?.isNotEmpty ?? false);
  bool get isInline => kind == 'inline';

  /// The endpoint with its query parameters applied, ready for the Dio client.
  String? get requestPath {
    final path = endpoint;
    if (path == null || path.isEmpty) return null;
    if (params.isEmpty) return path;

    final query = params.entries
        .where((entry) => entry.value != null && '${entry.value}'.isNotEmpty)
        .map((entry) =>
            '${Uri.encodeQueryComponent(entry.key)}=${Uri.encodeQueryComponent('${entry.value}')}')
        .join('&');

    if (query.isEmpty) return path;
    return path.contains('?') ? '$path&$query' : '$path?$query';
  }

  factory SectionSource.fromJson(Map<String, dynamic>? json) {
    if (json == null) return inline;

    return SectionSource(
      kind: _asString(json['kind']) ?? 'inline',
      endpoint: _asString(json['endpoint']),
      params: _asMap(json['params']),
      note: _asString(json['note']),
      endsAt: DateTime.tryParse(_asString(json['deal_ends_at']) ?? ''),
      tabs: _asList(json['tabs'])
          .map((tab) => SectionSource.fromJson(_asMap(tab)))
          .toList(growable: false),
    );
  }
}

/// A repeatable child of a section: a hero slide, a promo tile, a footer column, an FAQ entry.
class ThemeBlock {
  const ThemeBlock({
    required this.id,
    required this.type,
    required this.settings,
  });

  final int id;
  final String type;
  final ThemeSettings settings;

  factory ThemeBlock.fromJson(Map<String, dynamic> json) => ThemeBlock(
        id: _asInt(json['id']) ?? 0,
        type: _asString(json['type']) ?? '',
        settings: ThemeSettings(_asMap(json['settings'])),
      );
}

/// A banner-backed card, already merged with its live Banner Setup row by the server.
class ThemeCard {
  const ThemeCard({
    required this.settings,
    required this.action,
  });

  final ThemeSettings settings;
  final ThemeAction action;

  String? get image => settings.string('image');
  String? get mobileImage => settings.string('image_mobile') ?? image;

  /// Every visual the card carries, the phone-preferred one first. A card with extra frames
  /// crossfades through them the way the storefront does; most cards have exactly one.
  List<String> get frames => [
        mobileImage,
        settings.string('image_2'),
        settings.string('image_3'),
      ].whereType<String>().toList();
  String? get title => settings.string('title');
  String? get subtitle => settings.string('subtitle');
  String? get eyebrow => settings.string('eyebrow');
  String? get buttonText => settings.string('button_text');
  String? get badge => settings.string('badge');
  String? get icon => settings.string('icon');
  String? get textColor => settings.string('text_color');
  String? get background => settings.string('background');
  String get span => settings.string('span') ?? 'small';

  /// The banner row this card came from, where it came from one. A card typed straight into the
  /// builder has no banner behind it and reports nothing rather than being counted against a
  /// banner it did not come from.
  int? get bannerId => settings.integer('banner_id', 0) > 0
      ? settings.integer('banner_id', 0)
      : null;

  factory ThemeCard.fromJson(Map<String, dynamic> json) => ThemeCard(
        settings: ThemeSettings(json),
        action: ThemeAction.fromJson(_asMap(json['action'])),
      );
}

/// A section's settings bag, with typed reads that never throw.
///
/// The builder stores whatever the merchant typed, and an import or a hand-edited row can put a
/// string where a number belongs. Every accessor coerces and falls back, so a renderer can read
/// `settings.integer('columns', 2)` and be certain of an integer.
class ThemeSettings {
  const ThemeSettings(this._values);

  final Map<String, dynamic> _values;

  static const ThemeSettings empty = ThemeSettings({});

  Map<String, dynamic> get raw => _values;

  bool has(String key) => _values.containsKey(key);

  String? string(String key) {
    final value = _values[key];
    if (value == null) return null;
    final text = '$value'.trim();
    return text.isEmpty ? null : text;
  }

  int integer(String key, int fallback) => _asInt(_values[key]) ?? fallback;

  double decimal(String key, double fallback) =>
      _asDouble(_values[key]) ?? fallback;

  bool flag(String key, bool fallback) {
    final value = _values[key];
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final text = value.trim().toLowerCase();
      if (text == 'true' || text == '1' || text == 'yes') return true;
      if (text == 'false' || text == '0' || text == 'no' || text.isEmpty) {
        return false;
      }
    }
    return fallback;
  }

  ThemeAction get action => ThemeAction.fromJson(_asMap(_values['action']));
}

/// One section of a page: its type, its look, its children, and where its data comes from.
String? _experimentTag(Map<String, dynamic> experiment) {
  final key = _asString(experiment['key']);
  final variant = _asString(experiment['variant']);

  return (key == null || key.isEmpty || variant == null || variant.isEmpty)
      ? null
      : '$key:$variant';
}

class ThemeSectionSchema {
  const ThemeSectionSchema({
    required this.uuid,
    required this.id,
    required this.type,
    required this.variant,
    required this.componentVersion,
    required this.settings,
    required this.blocks,
    required this.cards,
    required this.source,
    required this.viewAll,
    this.experimentTag,
  });

  /// Identity that survives a publish. Use this — not [id] — to key per-section client state.
  final String uuid;

  /// The database row id, which changes when a version is duplicated.
  final int id;

  final String type;

  /// The layout the merchant chose, lifted out of the settings bag by the server.
  ///
  /// Read this rather than `settings.string('style')`: most types store it under `style` and one
  /// stores it under `layout`, and a renderer should not have to know which. Null means the type
  /// has one look, so there is nothing to branch on.
  final String? variant;

  /// The contract generation this section arrived under. Kept so a renderer can refuse a shape it
  /// predates rather than drawing it wrongly; unknown to older payloads, which report 1.
  final int componentVersion;

  final ThemeSettings settings;
  final List<ThemeBlock> blocks;

  /// Present only for banner-backed sections; null means "this section has no cards".
  final List<ThemeCard>? cards;

  final SectionSource source;

  /// Where the heading's "view all" leads, decided by the server from what the section shows.
  ///
  /// The destination used to be derived on each client from the section type alone, which is how a
  /// rail scoped to one category offered "view all" and opened the entire catalogue. Older servers
  /// send nothing here and the local derivation still stands in.
  final ThemeAction viewAll;

  /// `experimentKey:variantKey` when this section is an experiment variant, else null.
  ///
  /// Travels with the section's impression so the shop can count who actually SAW each variant —
  /// the same tag the web beacon sends, spelled once by the server for both clients.
  final String? experimentTag;

  String? get title => settings.string('title');
  String? get subtitle => settings.string('subtitle');
  String? get eyebrow => settings.string('eyebrow');

  factory ThemeSectionSchema.fromJson(Map<String, dynamic> json) {
    final cardsRaw = json['cards'];

    return ThemeSectionSchema(
      // A payload from a server that predates section identity still has to render, so the row id
      // stands in — unstable across publishes, but never null.
      uuid: _asString(json['uuid']) ?? 'section-${_asInt(json['id']) ?? 0}',
      id: _asInt(json['id']) ?? 0,
      type: _asString(json['type']) ?? '',
      // Falls back to the settings key a payload from an older server still carries, so a build
      // that reads variants works against both.
      variant: _asString(json['variant'])
          ?? _asString(_asMap(json['settings'])['style'])
          ?? _asString(_asMap(json['settings'])['layout']),
      componentVersion: _asInt(json['component_version']) ?? 1,
      experimentTag: _experimentTag(_asMap(json['experiment'])),
      settings: ThemeSettings(_asMap(json['settings'])),
      blocks: _asList(json['blocks'])
          .map((block) => ThemeBlock.fromJson(_asMap(block)))
          .where((block) => block.type.isNotEmpty)
          .toList(growable: false),
      cards: cardsRaw == null
          ? null
          : _asList(cardsRaw)
              .map((card) => ThemeCard.fromJson(_asMap(card)))
              .toList(growable: false),
      source: SectionSource.fromJson(_asMap(json['source'])),
      viewAll: ThemeAction.fromJson(_asMap(json['view_all'])),
    );
  }
}

/// The design tokens both renderers consume — the same values the web writes as CSS properties.
class ThemeTokens {
  const ThemeTokens({
    this.colors = const {},
    this.typography = const {},
    this.layout = const {},
    this.branding = const {},
  });

  final Map<String, dynamic> colors;
  final Map<String, dynamic> typography;
  final Map<String, dynamic> layout;
  final Map<String, dynamic> branding;

  static const ThemeTokens empty = ThemeTokens();

  bool get isEmpty => colors.isEmpty && layout.isEmpty && typography.isEmpty;

  factory ThemeTokens.fromJson(Map<String, dynamic>? json) {
    if (json == null) return empty;

    return ThemeTokens(
      colors: _asMap(json['colors']),
      typography: _asMap(json['typography']),
      layout: _asMap(json['layout']),
      branding: _asMap(json['branding']),
    );
  }

  Map<String, dynamic> toJson() => {
        'colors': colors,
        'typography': typography,
        'layout': layout,
        'branding': branding,
      };
}

/// The whole published page, plus the contract a client syncs against.
class ThemePayload {
  const ThemePayload({
    required this.page,
    required this.revision,
    required this.schemaVersion,
    required this.engineVersion,
    required this.checksum,
    required this.contentStamp,
    required this.publishedAt,
    required this.tokens,
    required this.sections,
    required this.withheld,
  });

  final String page;

  /// Monotonic, one step per publish. `0` means nothing has ever been published.
  final int revision;

  final int schemaVersion;
  final int engineVersion;
  final String? checksum;

  /// The same value /theme/version serves as its checksum — the pair matching is what lets
  /// the cheap sync check answer "nothing changed". Older servers omit it; the field stays null
  /// and the revision comparison falls back to the per-client checksum (always-download, as
  /// before).
  final String? contentStamp;
  final String? publishedAt;
  final ThemeTokens tokens;
  final List<ThemeSectionSchema> sections;

  /// Section types the server withheld from this build, mapped to why — surfaced in diagnostics.
  final Map<String, String> withheld;

  static const ThemePayload none = ThemePayload(
    page: 'home',
    revision: 0,
    schemaVersion: 0,
    engineVersion: 0,
    checksum: null,
    contentStamp: null,
    publishedAt: null,
    tokens: ThemeTokens.empty,
    sections: [],
    withheld: {},
  );

  /// Whether this payload can drive a home page at all. A published revision with no renderable
  /// section is not a home page — the app's built-in one is a better answer than a blank scroll.
  bool get isRenderable => revision > 0 && sections.isNotEmpty;

  factory ThemePayload.fromJson(Map<String, dynamic> json) {
    final compatibility = _asMap(json['compatibility']);

    return ThemePayload(
      page: _asString(json['page']) ?? 'home',
      revision: _asInt(json['revision']) ?? 0,
      schemaVersion: _asInt(json['schema_version']) ?? 0,
      engineVersion: _asInt(json['engine_version']) ?? 0,
      checksum: _asString(json['checksum']),
        contentStamp: _asString(json['content_stamp']),
      publishedAt: _asString(json['published_at']),
      tokens: ThemeTokens.fromJson(_asMap(json['tokens'])),
      sections: _asList(json['sections'])
          .map((section) => ThemeSectionSchema.fromJson(_asMap(section)))
          .where((section) => section.type.isNotEmpty)
          .toList(growable: false),
      withheld: _asMap(compatibility['withheld'])
          .map((key, value) => MapEntry(key, '$value')),
    );
  }
}

/// The cheap sync answer from `/api/v1/theme/version`.
class ThemeRevision {
  const ThemeRevision({
    required this.revision,
    required this.checksum,
    required this.schemaVersion,
    required this.engineVersion,
  });

  final int revision;
  final String? checksum;
  final int schemaVersion;
  final int engineVersion;

  static const ThemeRevision none = ThemeRevision(
    revision: 0,
    checksum: null,
    schemaVersion: 0,
    engineVersion: 0,
  );

  /// Whether a client holding [current] should download the page again.
  ///
  /// The revision alone is not enough: a rollback republishes older content under a HIGHER
  /// revision, so a client comparing only "is theirs bigger" would keep the newer page it already
  /// has. Any difference in either field means refetch.
  bool isNewerThan(ThemePayload current) {
    if (revision <= 0) return false;
    if (revision != current.revision) return true;

    // The version endpoint's checksum and the payload's per-client checksum are DIFFERENT hash
    // spaces — comparing them can never say "unchanged". content_stamp is the payload's echo of
    // the version checksum; when the server sends it, the comparison is finally meaningful.
    if (current.contentStamp != null) return checksum != current.contentStamp;

    // Older payload in hand: fall back to the old always-download behavior (the ETag still
    // turns the download into a 304).
    return checksum != current.checksum;
  }

  factory ThemeRevision.fromJson(Map<String, dynamic> json) => ThemeRevision(
        revision: _asInt(json['revision']) ?? 0,
        checksum: _asString(json['checksum']),
        schemaVersion: _asInt(json['schema_version']) ?? 0,
        engineVersion: _asInt(json['engine_version']) ?? 0,
      );
}

// ---------------------------------------------------------------------------------------------
// Coercion helpers. Shared by every model above so one unexpected type cannot take down a page.

String? _asString(dynamic value) {
  if (value == null) return null;
  final text = value is String ? value : '$value';
  final trimmed = text.trim();
  return trimmed.isEmpty || trimmed == 'null' ? null : trimmed;
}

int? _asInt(dynamic value) {
  if (value is int) return value;
  // toInt() THROWS on NaN and Infinity — a payload value of "NaN" must coerce to null like any
  // other unusable input, never take a section's build down.
  if (value is num) return value.isFinite ? value.toInt() : null;
  if (value is String) {
    final parsed = int.tryParse(value.trim());
    if (parsed != null) return parsed;
    final asDouble = _asDouble(value);
    return (asDouble != null && asDouble.isFinite) ? asDouble.toInt() : null;
  }
  return null;
}

double? _asDouble(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value.trim());
  return null;
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.map((key, item) => MapEntry('$key', item));
  return const {};
}

List<dynamic> _asList(dynamic value) {
  if (value is List) return value;
  return const [];
}
