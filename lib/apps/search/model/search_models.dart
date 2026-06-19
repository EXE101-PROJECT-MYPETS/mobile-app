import 'package:pawly_mobile/common/utils/image_url_util.dart';

class SearchInitialResponse {
  const SearchInitialResponse({
    required this.recentKeywords,
    required this.suggestedKeywords,
    required this.recommendedItems,
  });

  final List<String> recentKeywords;
  final List<String> suggestedKeywords;
  final List<SearchItem> recommendedItems;

  factory SearchInitialResponse.empty() {
    return const SearchInitialResponse(
      recentKeywords: [],
      suggestedKeywords: [],
      recommendedItems: [],
    );
  }

  factory SearchInitialResponse.fromJson(Map<String, dynamic> json) {
    return SearchInitialResponse(
      recentKeywords: _stringList(json['recentKeywords']),
      suggestedKeywords: _stringList(json['suggestedKeywords']),
      recommendedItems: _itemList(json['recommendedItems']),
    );
  }
}

class SearchSuggestionsResponse {
  const SearchSuggestionsResponse({required this.keywords});

  final List<String> keywords;

  factory SearchSuggestionsResponse.fromJson(Map<String, dynamic> json) {
    return SearchSuggestionsResponse(keywords: _stringList(json['keywords']));
  }
}

class SearchPageResponse {
  const SearchPageResponse({
    required this.content,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
    required this.hasNext,
  });

  final List<SearchItem> content;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;
  final bool hasNext;

  factory SearchPageResponse.fromJson(Map<String, dynamic> json) {
    return SearchPageResponse(
      content: _itemList(json['content']),
      page: _toInt(json['page']) ?? 0,
      size: _toInt(json['size']) ?? 0,
      totalElements: _toInt(json['totalElements']) ?? 0,
      totalPages: _toInt(json['totalPages']) ?? 0,
      hasNext: json['hasNext'] == true,
    );
  }
}

class SearchItem {
  const SearchItem({
    required this.id,
    required this.type,
    required this.name,
    this.image,
    this.price,
    this.originalPrice,
    this.shopId,
    this.shopName,
    this.rating,
    this.soldCount,
    this.address,
    this.distanceKm,
  });

  final int id;
  final String type;
  final String name;
  final String? image;
  final num? price;
  final num? originalPrice;
  final int? shopId;
  final String? shopName;
  final double? rating;
  final int? soldCount;
  final String? address;
  final double? distanceKm;

  bool get isService => type.toUpperCase() == 'SERVICE';
  bool get isProduct => type.toUpperCase() == 'PRODUCT';
  bool get isShop => type.toUpperCase() == 'SHOP';

  factory SearchItem.fromJson(Map<String, dynamic> json) {
    return SearchItem(
      id: _toInt(json['id']) ?? 0,
      type: (json['type'] as String? ?? '').toUpperCase(),
      name: (json['name'] as String? ?? '').trim(),
      image: ImageUrlUtil.buildPublicUrl((json['image'] as String?)?.trim()),
      price: json['price'] as num?,
      originalPrice: json['originalPrice'] as num?,
      shopId: _toInt(json['shopId']),
      shopName: (json['shopName'] as String?)?.trim(),
      rating: (json['rating'] as num?)?.toDouble(),
      soldCount: _toInt(json['soldCount']),
      address: (json['address'] as String?)?.trim(),
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
    );
  }
}

List<String> _stringList(dynamic value) {
  if (value is! List) return const [];
  return value
      .whereType<String>()
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}

List<SearchItem> _itemList(dynamic value) {
  if (value is! List) return const [];
  return value
      .whereType<Map<String, dynamic>>()
      .map(SearchItem.fromJson)
      .where((item) => item.id != 0 && item.name.isNotEmpty)
      .toList(growable: false);
}

int? _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}
