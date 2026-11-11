import 'dart:convert';

class NewsModel {
  final int id;
  final String date;
  final String dateGmt;
  final RenderedText guid;
  final String modified;
  final String modifiedGmt;
  final String slug;
  final String status;
  final String type;
  final String link;
  final RenderedText title;
  final Content content;
  final Content excerpt;
  final int author;
  final int featuredMedia;
  final String commentStatus;
  final String pingStatus;
  final bool sticky;
  final String template;
  final String format;
  final Meta meta;
  final List<int> categories;
  final List<dynamic> tags;
  final List<String> classList;
  final String imageFeature;
  final String authorName;
  final PureTaxonomies? pureTaxonomies;
  final String? jetpackFeaturedMediaUrl;
  final bool? jetpackSharingEnabled;
  final Links? links;
  final Embedded? embedded;

  NewsModel({
    required this.id,
    required this.date,
    required this.dateGmt,
    required this.guid,
    required this.modified,
    required this.modifiedGmt,
    required this.slug,
    required this.status,
    required this.type,
    required this.link,
    required this.title,
    required this.content,
    required this.excerpt,
    required this.author,
    required this.featuredMedia,
    required this.commentStatus,
    required this.pingStatus,
    required this.sticky,
    required this.template,
    required this.format,
    required this.meta,
    required this.categories,
    required this.tags,
    required this.classList,
    required this.imageFeature,
    required this.authorName,
    this.pureTaxonomies,
    this.jetpackFeaturedMediaUrl,
    this.jetpackSharingEnabled,
    this.links,
    this.embedded,
  });

  // Helper Methods to get data easily
  String get displayTitle => title.rendered;
  String get displayContent => content.rendered;
  String get displayExcerpt => excerpt.rendered;
  String get displayImageUrl => imageFeature.isNotEmpty ? imageFeature : (jetpackFeaturedMediaUrl ?? '');
  String get categoryName => (pureTaxonomies?.categories?.isNotEmpty ?? false) 
      ? pureTaxonomies!.categories!.first.name 
      : 'Uncategorized';

  factory NewsModel.fromJson(Map<String, dynamic> json) {
    return NewsModel(
      id: json['id'] ?? 0,
      date: json['date'] ?? '',
      dateGmt: json['date_gmt'] ?? '',
      guid: RenderedText.fromJson(json['guid'] ?? {}),
      modified: json['modified'] ?? '',
      modifiedGmt: json['modified_gmt'] ?? '',
      slug: json['slug'] ?? '',
      status: json['status'] ?? '',
      type: json['type'] ?? '',
      link: json['link'] ?? '',
      title: RenderedText.fromJson(json['title'] ?? {}),
      content: Content.fromJson(json['content'] ?? {}),
      excerpt: Content.fromJson(json['excerpt'] ?? {}),
      author: json['author'] ?? 0,
      featuredMedia: json['featured_media'] ?? 0,
      commentStatus: json['comment_status'] ?? '',
      pingStatus: json['ping_status'] ?? '',
      sticky: json['sticky'] ?? false,
      template: json['template'] ?? '',
      format: json['format'] ?? '',
      meta: Meta.fromJson(json['meta'] ?? {}),
      categories: List<int>.from(json['categories'] ?? []),
      tags: List<dynamic>.from(json['tags'] ?? []),
      classList: List<String>.from(json['class_list'] ?? []),
      imageFeature: json['image_feature'] ?? '',
      authorName: json['author_name'] ?? '',
      pureTaxonomies: json['pure_taxonomies'] != null ? PureTaxonomies.fromJson(json['pure_taxonomies']) : null,
      jetpackFeaturedMediaUrl: json['jetpack_featured_media_url'],
      jetpackSharingEnabled: json['jetpack_sharing_enabled'],
      links: json['_links'] != null ? Links.fromJson(json['_links']) : null,
      embedded: json['_embedded'] != null ? Embedded.fromJson(json['_embedded']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'date_gmt': dateGmt,
      'guid': guid.toJson(),
      'modified': modified,
      'modified_gmt': modifiedGmt,
      'slug': slug,
      'status': status,
      'type': type,
      'link': link,
      'title': title.toJson(),
      'content': content.toJson(),
      'excerpt': excerpt.toJson(),
      'author': author,
      'featured_media': featuredMedia,
      'comment_status': commentStatus,
      'ping_status': pingStatus,
      'sticky': sticky,
      'template': template,
      'format': format,
      'meta': meta.toJson(),
      'categories': categories,
      'tags': tags,
      'class_list': classList,
      'image_feature': imageFeature,
      'author_name': authorName,
      'pure_taxonomies': pureTaxonomies?.toJson(),
      'jetpack_featured_media_url': jetpackFeaturedMediaUrl,
      'jetpack_sharing_enabled': jetpackSharingEnabled,
      '_links': links?.toJson(),
      '_embedded': embedded?.toJson(),
    };
  }
}

class RenderedText {
  final String rendered;
  RenderedText({required this.rendered});
  factory RenderedText.fromJson(Map<String, dynamic> json) => RenderedText(rendered: json['rendered'] ?? '');
  Map<String, dynamic> toJson() => {'rendered': rendered};
}

class Content {
  final String rendered;
  final bool protected;
  Content({required this.rendered, required this.protected});
  factory Content.fromJson(Map<String, dynamic> json) => Content(
        rendered: json['rendered'] ?? '',
        protected: json['protected'] ?? false,
      );
  Map<String, dynamic> toJson() => {'rendered': rendered, 'protected': protected};
}

class Meta {
  final bool jetpackMembershipsContainsPaidContent;
  final String footnotes;
  Meta({required this.jetpackMembershipsContainsPaidContent, required this.footnotes});
  factory Meta.fromJson(Map<String, dynamic> json) => Meta(
        jetpackMembershipsContainsPaidContent: json['_jetpack_memberships_contains_paid_content'] ?? false,
        footnotes: json['footnotes'] ?? '',
      );
  Map<String, dynamic> toJson() => {
        '_jetpack_memberships_contains_paid_content': jetpackMembershipsContainsPaidContent,
        'footnotes': footnotes,
      };
}

class PureTaxonomies {
  final List<CategoryItem>? categories;
  PureTaxonomies({this.categories});
  factory PureTaxonomies.fromJson(Map<String, dynamic> json) => PureTaxonomies(
        categories: json['categories'] != null 
            ? (json['categories'] as List).map((i) => CategoryItem.fromJson(i)).toList() 
            : null,
      );
  Map<String, dynamic> toJson() => {'categories': categories?.map((e) => e.toJson()).toList()};
}

class CategoryItem {
  final int termId;
  final String name;
  final String slug;
  CategoryItem({required this.termId, required this.name, required this.slug});
  factory CategoryItem.fromJson(Map<String, dynamic> json) => CategoryItem(
        termId: json['term_id'] ?? 0,
        name: json['name'] ?? '',
        slug: json['slug'] ?? '',
      );
  Map<String, dynamic> toJson() => {'term_id': termId, 'name': name, 'slug': slug};
}

class Links {
  final List<LinkItem>? self;
  final List<LinkItem>? collection;
  final List<LinkItem>? author;
  Links({this.self, this.collection, this.author});
  factory Links.fromJson(Map<String, dynamic> json) => Links(
        self: json['self'] != null ? (json['self'] as List).map((i) => LinkItem.fromJson(i)).toList() : null,
        collection: json['collection'] != null ? (json['collection'] as List).map((i) => LinkItem.fromJson(i)).toList() : null,
        author: json['author'] != null ? (json['author'] as List).map((i) => LinkItem.fromJson(i)).toList() : null,
      );
  Map<String, dynamic> toJson() => {
        'self': self?.map((e) => e.toJson()).toList(),
        'collection': collection?.map((e) => e.toJson()).toList(),
        'author': author?.map((e) => e.toJson()).toList(),
      };
}

class LinkItem {
  final String href;
  LinkItem({required this.href});
  factory LinkItem.fromJson(Map<String, dynamic> json) => LinkItem(href: json['href'] ?? '');
  Map<String, dynamic> toJson() => {'href': href};
}

class Embedded {
  final List<EmbeddedAuthor>? author;
  final List<EmbeddedMedia>? featuredMedia;
  final List<List<EmbeddedTerm>>? terms;

  Embedded({this.author, this.featuredMedia, this.terms});

  factory Embedded.fromJson(Map<String, dynamic> json) {
    return Embedded(
      author: json['author'] != null ? (json['author'] as List).map((i) => EmbeddedAuthor.fromJson(i)).toList() : null,
      featuredMedia: json['wp:featuredmedia'] != null ? (json['wp:featuredmedia'] as List).map((i) => EmbeddedMedia.fromJson(i)).toList() : null,
      terms: json['wp:term'] != null ? (json['wp:term'] as List).map((list) => (list as List).map((term) => EmbeddedTerm.fromJson(term)).toList()).toList() : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'author': author?.map((e) => e.toJson()).toList(),
        'wp:featuredmedia': featuredMedia?.map((e) => e.toJson()).toList(),
        'wp:term': terms?.map((list) => list.map((e) => e.toJson()).toList()).toList(),
      };
}

class EmbeddedAuthor {
  final int id;
  final String name;
  final String url;
  final Map<String, String>? avatarUrls;
  EmbeddedAuthor({required this.id, required this.name, required this.url, this.avatarUrls});
  factory EmbeddedAuthor.fromJson(Map<String, dynamic> json) => EmbeddedAuthor(
        id: json['id'] ?? 0,
        name: json['name'] ?? '',
        url: json['url'] ?? '',
        avatarUrls: json['avatar_urls'] != null ? Map<String, String>.from(json['avatar_urls']) : null,
      );
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'url': url, 'avatar_urls': avatarUrls};
}

class EmbeddedMedia {
  final int id;
  final String sourceUrl;
  final RenderedText? title;
  EmbeddedMedia({required this.id, required this.sourceUrl, this.title});
  factory EmbeddedMedia.fromJson(Map<String, dynamic> json) => EmbeddedMedia(
        id: json['id'] ?? 0,
        sourceUrl: json['source_url'] ?? '',
        title: json['title'] != null ? RenderedText.fromJson(json['title']) : null,
      );
  Map<String, dynamic> toJson() => {'id': id, 'source_url': sourceUrl, 'title': title?.toJson()};
}

class EmbeddedTerm {
  final int id;
  final String name;
  final String slug;
  final String taxonomy;
  EmbeddedTerm({required this.id, required this.name, required this.slug, required this.taxonomy});
  factory EmbeddedTerm.fromJson(Map<String, dynamic> json) => EmbeddedTerm(
        id: json['id'] ?? 0,
        name: json['name'] ?? '',
        slug: json['slug'] ?? '',
        taxonomy: json['taxonomy'] ?? '',
      );
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'slug': slug, 'taxonomy': taxonomy};
}
