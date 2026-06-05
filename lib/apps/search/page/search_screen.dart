import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:petpee_mobile/apps/product/page/product_detail_screen.dart';
import 'package:petpee_mobile/apps/search/api/search_service.dart';
import 'package:petpee_mobile/apps/search/model/search_models.dart';
import 'package:petpee_mobile/apps/service/page/service_detail_screen.dart';
import 'package:petpee_mobile/apps/shop/page/shop_detail_screen.dart';
import 'package:petpee_mobile/common/auth/store/auth_provider.dart';
import 'package:petpee_mobile/common/store/app_state.dart';
import 'package:petpee_mobile/common/utils/image_url_util.dart';
import 'package:petpee_mobile/common/utils/price_formatter.dart';
import 'package:provider/provider.dart';

const double _searchGridCardExtent = 248;
const double _searchCardImageHeight = 116;
const Color _shopeeOrange = Color(0xFFFF4D33);
const Color _searchResultBackground = Color(0xFFF3F3F3);
const int _recommendedPageStep = 20;
const int _recommendedMaxSize = 100;

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final SearchService _searchService = SearchService();
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _initialScrollController = ScrollController();
  final ScrollController _resultScrollController = ScrollController();

  Timer? _debounce;
  SearchInitialResponse _initial = SearchInitialResponse.empty();
  List<String> _suggestions = [];
  List<SearchItem> _results = [];

  String _activeKeyword = '';
  final String _type = 'ALL';
  String _sort = 'RELEVANT';
  int _page = 0;
  bool _hasNext = false;
  bool _ignoreTextChange = false;
  int _searchRequestId = 0;

  bool _initialLoading = false;
  bool _suggestionLoading = false;
  bool _searchLoading = false;
  bool _loadMoreLoading = false;
  bool _recommendedLoadMoreLoading = false;
  bool _recommendedHasMore = true;
  bool _hasSearched = false;
  bool _showSuggestions = false;
  int _recommendedSize = _recommendedPageStep;
  String? _initialError;
  String? _searchError;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleTextChanged);
    _initialScrollController.addListener(_handleInitialScroll);
    _resultScrollController.addListener(_handleResultScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _focusNode.requestFocus();
      _loadInitial();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.removeListener(_handleTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    _initialScrollController.removeListener(_handleInitialScroll);
    _initialScrollController.dispose();
    _resultScrollController.removeListener(_handleResultScroll);
    _resultScrollController.dispose();
    super.dispose();
  }

  void _handleTextChanged() {
    if (_ignoreTextChange) return;

    final keyword = _controller.text.trim();
    _debounce?.cancel();

    if (keyword.isEmpty) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
        _hasSearched = false;
        _searchError = null;
      });
      return;
    }

    setState(() {
      _showSuggestions = true;
      _hasSearched = false;
      _searchError = null;
    });

    _debounce = Timer(const Duration(milliseconds: 400), () {
      _loadSuggestions(keyword);
    });
  }

  void _handleInitialScroll() {
    if (!_initialScrollController.hasClients ||
        _hasSearched ||
        _showSuggestions ||
        _controller.text.trim().isNotEmpty) {
      return;
    }

    _maybeLoadMoreRecommended(_initialScrollController.position);
  }

  void _maybeLoadMoreRecommended(ScrollMetrics metrics) {
    if (_hasSearched ||
        _showSuggestions ||
        _controller.text.trim().isNotEmpty ||
        metrics.axis != Axis.vertical) {
      return;
    }

    if (metrics.pixels >= metrics.maxScrollExtent - 360) {
      _loadMoreRecommended();
    }
  }

  void _handleResultScroll() {
    if (!_resultScrollController.hasClients || !_hasSearched) return;
    final position = _resultScrollController.position;
    if (position.pixels >= position.maxScrollExtent - 280) {
      _loadMore();
    }
  }

  Future<void> _loadInitial({bool resetRecommendedSize = true}) async {
    final location = _currentLocation();
    final requestedSize = resetRecommendedSize
        ? _recommendedPageStep
        : _recommendedSize;
    setState(() {
      if (resetRecommendedSize) {
        _recommendedSize = _recommendedPageStep;
        _recommendedHasMore = true;
      }
      _initialLoading = true;
      _initialError = null;
    });

    try {
      final response = await _searchService.getInitial(
        lat: location.lat,
        lng: location.lng,
        recommendedSize: requestedSize,
      );
      if (!mounted) return;
      setState(() => _initial = response);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _initialError = 'Không thể tải dữ liệu tìm kiếm';
      });
    } finally {
      if (mounted) {
        setState(() => _initialLoading = false);
      }
    }
  }

  Future<void> _loadMoreRecommended() async {
    if (_initialLoading ||
        _recommendedLoadMoreLoading ||
        !_recommendedHasMore ||
        _recommendedSize >= _recommendedMaxSize ||
        _initial.recommendedItems.isEmpty) {
      return;
    }

    final location = _currentLocation();
    final previousCount = _initial.recommendedItems.length;
    final nextSize = (_recommendedSize + _recommendedPageStep).clamp(
      _recommendedPageStep,
      _recommendedMaxSize,
    );

    setState(() => _recommendedLoadMoreLoading = true);

    try {
      final response = await _searchService.getInitial(
        lat: location.lat,
        lng: location.lng,
        recommendedSize: nextSize,
      );
      if (!mounted) return;
      setState(() {
        _initial = response;
        _recommendedSize = nextSize;
        _recommendedHasMore =
            response.recommendedItems.length > previousCount &&
            response.recommendedItems.length >= nextSize;
      });
    } catch (_) {
      if (!mounted) return;
      _showSnackBar('Không thể tải thêm gợi ý');
    } finally {
      if (mounted) {
        setState(() => _recommendedLoadMoreLoading = false);
      }
    }
  }

  Future<void> _loadSuggestions(String keyword) async {
    if (!mounted || keyword != _controller.text.trim()) return;

    final location = _currentLocation();
    setState(() => _suggestionLoading = true);

    try {
      final response = await _searchService.getSuggestions(
        keyword: keyword,
        lat: location.lat,
        lng: location.lng,
        radiusKm: location.radiusKm,
        size: 10,
      );
      if (!mounted || keyword != _controller.text.trim()) return;
      setState(() => _suggestions = response.keywords);
    } catch (_) {
      if (!mounted || keyword != _controller.text.trim()) return;
      setState(() => _suggestions = []);
    } finally {
      if (mounted && keyword == _controller.text.trim()) {
        setState(() => _suggestionLoading = false);
      }
    }
  }

  Future<void> _performSearch(String rawKeyword) async {
    final keyword = rawKeyword.trim();
    if (keyword.isEmpty) return;

    _debounce?.cancel();
    FocusScope.of(context).unfocus();
    final location = _currentLocation();
    final requestedSort = _sort;
    final requestId = ++_searchRequestId;

    setState(() {
      _activeKeyword = keyword;
      _hasSearched = true;
      _showSuggestions = false;
      _searchLoading = true;
      _loadMoreLoading = false;
      _searchError = null;
      _results = [];
      _page = 0;
      _hasNext = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_resultScrollController.hasClients) {
        _resultScrollController.jumpTo(0);
      }
    });

    try {
      final response = await _searchService.search(
        keyword: keyword,
        type: _type,
        lat: location.lat,
        lng: location.lng,
        radiusKm: location.radiusKm,
        sort: requestedSort,
        page: 0,
        size: 20,
      );
      if (!mounted || requestId != _searchRequestId || requestedSort != _sort) {
        return;
      }
      setState(() {
        _results = _sortItems(response.content, requestedSort);
        _page = response.page;
        _hasNext = response.hasNext;
      });
      _saveHistoryIfLoggedIn(keyword);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _searchError = 'Không thể tìm kiếm, vui lòng thử lại';
      });
    } finally {
      if (mounted) {
        setState(() => _searchLoading = false);
      }
    }
  }

  Future<void> _loadMore() async {
    if (_loadMoreLoading ||
        _searchLoading ||
        !_hasNext ||
        _activeKeyword.isEmpty) {
      return;
    }

    final location = _currentLocation();
    final requestedSort = _sort;
    final requestId = _searchRequestId;
    setState(() => _loadMoreLoading = true);

    try {
      final response = await _searchService.search(
        keyword: _activeKeyword,
        type: _type,
        lat: location.lat,
        lng: location.lng,
        radiusKm: location.radiusKm,
        sort: requestedSort,
        page: _page + 1,
        size: 20,
      );
      if (!mounted || requestId != _searchRequestId || requestedSort != _sort) {
        return;
      }
      setState(() {
        _results = _sortItems([
          ..._results,
          ...response.content,
        ], requestedSort);
        _page = response.page;
        _hasNext = response.hasNext;
      });
    } catch (_) {
      if (!mounted) return;
      _showSnackBar('Không thể tải thêm kết quả');
    } finally {
      if (mounted) {
        setState(() => _loadMoreLoading = false);
      }
    }
  }

  List<SearchItem> _sortItems(List<SearchItem> items, String sort) {
    final sorted = [...items];
    switch (sort) {
      case 'PRICE_ASC':
        sorted.sort(_comparePriceAscending);
        break;
      case 'PRICE_DESC':
        sorted.sort(_comparePriceDescending);
        break;
      case 'SOLD_DESC':
        sorted.sort((a, b) {
          final soldCompare = (b.soldCount ?? 0).compareTo(a.soldCount ?? 0);
          if (soldCompare != 0) return soldCompare;
          return (b.rating ?? 0).compareTo(a.rating ?? 0);
        });
        break;
    }
    return sorted;
  }

  int _comparePriceAscending(SearchItem a, SearchItem b) {
    final aPrice = a.price;
    final bPrice = b.price;
    if (aPrice == null && bPrice == null) return 0;
    if (aPrice == null) return 1;
    if (bPrice == null) return -1;
    final priceCompare = aPrice.compareTo(bPrice);
    if (priceCompare != 0) return priceCompare;
    return a.id.compareTo(b.id);
  }

  int _comparePriceDescending(SearchItem a, SearchItem b) {
    final aPrice = a.price;
    final bPrice = b.price;
    if (aPrice == null && bPrice == null) return 0;
    if (aPrice == null) return 1;
    if (bPrice == null) return -1;
    final priceCompare = bPrice.compareTo(aPrice);
    if (priceCompare != 0) return priceCompare;
    return a.id.compareTo(b.id);
  }

  void _submitKeyword(String keyword) {
    final trimmed = keyword.trim();
    if (trimmed.isEmpty) return;

    _ignoreTextChange = true;
    _controller.value = TextEditingValue(
      text: trimmed,
      selection: TextSelection.collapsed(offset: trimmed.length),
    );
    _ignoreTextChange = false;
    _performSearch(trimmed);
  }

  void _clearText() {
    _debounce?.cancel();
    _controller.clear();
    setState(() {
      _suggestions = [];
      _showSuggestions = false;
      _hasSearched = false;
      _searchError = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  void _changeSort(String value) {
    final nextValue = value == 'PRICE' && _sort == 'PRICE_ASC'
        ? 'PRICE_DESC'
        : value == 'PRICE'
        ? 'PRICE_ASC'
        : value;
    if (_sort == nextValue) return;
    setState(() => _sort = nextValue);
    if (_activeKeyword.isNotEmpty) {
      _performSearch(_activeKeyword);
    }
  }

  void _saveHistoryIfLoggedIn(String keyword) {
    final token = context.read<AuthProvider>().token;
    if (token == null || token.isEmpty) return;

    _searchService
        .saveHistory(keyword)
        .then((_) {
          if (!mounted) return;
          final recent = [
            keyword,
            ..._initial.recentKeywords.where(
              (item) => item.toLowerCase() != keyword.toLowerCase(),
            ),
          ].take(10).toList(growable: false);
          setState(() {
            _initial = SearchInitialResponse(
              recentKeywords: recent,
              suggestedKeywords: _initial.suggestedKeywords,
              recommendedItems: _initial.recommendedItems,
            );
          });
        })
        .catchError((_) {});
  }

  Future<void> _deleteHistory({String? keyword}) async {
    final token = context.read<AuthProvider>().token;
    final previous = _initial;
    final nextRecent = keyword == null
        ? <String>[]
        : _initial.recentKeywords
              .where((item) => item.toLowerCase() != keyword.toLowerCase())
              .toList(growable: false);

    setState(() {
      _initial = SearchInitialResponse(
        recentKeywords: nextRecent,
        suggestedKeywords: _initial.suggestedKeywords,
        recommendedItems: _initial.recommendedItems,
      );
    });

    if (token == null || token.isEmpty) return;

    try {
      await _searchService.deleteHistory(keyword: keyword);
    } catch (_) {
      if (!mounted) return;
      setState(() => _initial = previous);
      _showSnackBar('Không thể xóa lịch sử tìm kiếm');
    }
  }

  void _openItem(SearchItem item) {
    if (item.isProduct) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ProductDetailScreen(productId: item.id.toString()),
        ),
      );
      return;
    }

    if (item.isShop) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ShopDetailScreen(
            shopId: item.shopId ?? item.id,
            shopName: item.shopName ?? item.name,
            shopAvatarUrl: item.image,
          ),
        ),
      );
      return;
    }

    if (item.isService) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ServiceDetailScreen(
            serviceId: item.id,
            name: item.name,
            image: item.image,
            price: item.price,
            shopId: item.shopId,
            shopName: item.shopName,
            rating: item.rating,
            soldCount: item.soldCount,
            address: item.address,
            distanceKm: item.distanceKm,
          ),
        ),
      );
      return;
    }

    _showSnackBar('Loại kết quả chưa được hỗ trợ');
  }

  _SearchLocation _currentLocation() {
    final state = context.read<AppState>();
    if (state.serviceUserLat == null || state.serviceUserLng == null) {
      return const _SearchLocation();
    }
    return _SearchLocation(
      lat: state.serviceUserLat,
      lng: state.serviceUserLng,
      radiusKm: state.serviceRadiusKm,
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD5F4FF),
      body: SafeArea(
        child: Column(
          children: [
            _SearchHeader(
              controller: _controller,
              focusNode: _focusNode,
              showSearchAction: !_hasSearched,
              onBack: () {
                FocusManager.instance.primaryFocus?.unfocus();
                Navigator.pop(context);
              },
              onClear: _clearText,
              onSearch: () => _performSearch(_controller.text),
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_hasSearched) {
      return _buildResultBody();
    }

    if (_showSuggestions && _controller.text.trim().isNotEmpty) {
      return _buildSuggestionBody();
    }

    return _buildInitialBody();
  }

  Widget _buildInitialBody() {
    if (_initialLoading && _initial.recommendedItems.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_initialError != null && _initial.recommendedItems.isEmpty) {
      return _ErrorState(message: _initialError!, onRetry: _loadInitial);
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        _maybeLoadMoreRecommended(notification.metrics);
        return false;
      },
      child: RefreshIndicator(
        onRefresh: _loadInitial,
        child: ListView(
          controller: _initialScrollController,
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 28),
          children: [
            if (_initial.recentKeywords.isNotEmpty)
              _KeywordSection(
                title: 'Lịch sử tìm kiếm',
                keywords: _initial.recentKeywords,
                onTapKeyword: _submitKeyword,
                onDeleteKeyword: (keyword) => _deleteHistory(keyword: keyword),
                trailing: IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _deleteHistory(),
                  icon: const Icon(
                    LucideIcons.trash2,
                    size: 17,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ),
            if (_initial.suggestedKeywords.isNotEmpty)
              _KeywordSection(
                title: 'Gợi ý tìm kiếm',
                keywords: _initial.suggestedKeywords,
                onTapKeyword: _submitKeyword,
              ),
            if (_initial.recommendedItems.isNotEmpty) ...[
              _SectionTitle(
                title: _currentLocation().lat == null
                    ? 'Có thể bạn quan tâm'
                    : 'Gợi ý gần bạn',
              ),
              _SearchItemGrid(
                items: _initial.recommendedItems,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                onTapItem: _openItem,
              ),
            ],
            if (_initial.recentKeywords.isEmpty &&
                _initial.suggestedKeywords.isEmpty &&
                _initial.recommendedItems.isEmpty)
              const _EmptyState(
                icon: LucideIcons.search,
                title: 'Chưa có gợi ý tìm kiếm',
                message:
                    'Nhập từ khóa để bắt đầu tìm dịch vụ, sản phẩm hoặc shop.',
              ),
            if (_recommendedLoadMoreLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionBody() {
    final keyword = _controller.text.trim();
    return Container(
      color: const Color(0xFFF3F3F3),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          if (_suggestionLoading)
            const LinearProgressIndicator(
              minHeight: 2,
              color: Color(0xFFFF4D33),
              backgroundColor: Color(0xFFFFE1DC),
            ),
          if (!_suggestionLoading && _suggestions.isEmpty)
            _SuggestionTile(
              keyword: keyword,
              subtitle: 'Tìm kiếm chính xác từ khóa này',
              onTap: () => _submitKeyword(keyword),
            ),
          ..._suggestions.map(
            (item) => _SuggestionTile(
              keyword: item,
              onTap: () => _submitKeyword(item),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultBody() {
    if (_searchLoading) {
      return Column(
        children: [
          _FilterBar(sort: _sort, onSortChanged: _changeSort),
          const Expanded(child: Center(child: CircularProgressIndicator())),
        ],
      );
    }

    if (_searchError != null) {
      return Column(
        children: [
          _FilterBar(sort: _sort, onSortChanged: _changeSort),
          Expanded(
            child: _ErrorState(
              message: _searchError!,
              onRetry: () => _performSearch(_activeKeyword),
            ),
          ),
        ],
      );
    }

    if (_results.isEmpty) {
      return Column(
        children: [
          _FilterBar(sort: _sort, onSortChanged: _changeSort),
          const Expanded(
            child: _EmptyState(
              icon: LucideIcons.packageSearch,
              title: 'Không tìm thấy kết quả',
              message: 'Thử từ khóa ngắn hơn hoặc đổi bộ lọc tìm kiếm.',
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        _FilterBar(sort: _sort, onSortChanged: _changeSort),
        Expanded(
          child: Container(
            color: _searchResultBackground,
            child: GridView.builder(
              controller: _resultScrollController,
              padding: EdgeInsets.fromLTRB(8, 8, 8, _loadMoreLoading ? 84 : 18),
              itemCount: _results.length + (_loadMoreLoading ? 1 : 0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 6,
                mainAxisSpacing: 8,
                mainAxisExtent: _searchGridCardExtent,
              ),
              itemBuilder: (context, index) {
                if (index >= _results.length) {
                  return const Center(child: CircularProgressIndicator());
                }
                return _SearchItemCard(
                  item: _results[index],
                  onTap: () => _openItem(_results[index]),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _SearchHeader extends StatelessWidget {
  const _SearchHeader({
    required this.controller,
    required this.focusNode,
    required this.showSearchAction,
    required this.onBack,
    required this.onClear,
    required this.onSearch,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool showSearchAction;
  final VoidCallback onBack;
  final VoidCallback onClear;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 8, 8, 8),
      decoration: const BoxDecoration(color: Colors.white),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            visualDensity: VisualDensity.compact,
            icon: const Icon(
              LucideIcons.arrowLeft,
              color: Color(0xFFFF4D33),
              size: 24,
            ),
          ),
          Expanded(
            child: Container(
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFF4D33), width: 1),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      autofocus: true,
                      onTapOutside: (_) {
                        FocusManager.instance.primaryFocus?.unfocus();
                      },
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => onSearch(),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Tìm kiếm',
                        hintStyle: GoogleFonts.inter(
                          color: const Color(0xFF9CA3AF),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        isCollapsed: true,
                      ),
                      style: GoogleFonts.inter(
                        color: const Color(0xFF111827),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Container(
                    width: 42,
                    height: 34,
                    decoration: const BoxDecoration(
                      border: Border(
                        left: BorderSide(color: Color(0xFFFFD1C8)),
                      ),
                    ),
                    child: const Icon(
                      LucideIcons.camera,
                      color: Color(0xFF737373),
                      size: 19,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (showSearchAction)
            SizedBox(
              width: 43,
              height: 34,
              child: FilledButton(
                onPressed: onSearch,
                style: FilledButton.styleFrom(
                  backgroundColor: _shopeeOrange,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                  ),
                ),
                child: const Icon(
                  LucideIcons.search,
                  color: Colors.white,
                  size: 19,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _KeywordSection extends StatelessWidget {
  const _KeywordSection({
    required this.title,
    required this.keywords,
    required this.onTapKeyword,
    this.onDeleteKeyword,
    this.trailing,
  });

  final String title;
  final List<String> keywords;
  final ValueChanged<String> onTapKeyword;
  final ValueChanged<String>? onDeleteKeyword;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(title: title, trailing: trailing),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: keywords
                .map(
                  (keyword) => _KeywordChip(
                    keyword: keyword,
                    onTap: () => onTapKeyword(keyword),
                    onDeleted: onDeleteKeyword == null
                        ? null
                        : () => onDeleteKeyword!(keyword),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.inter(
                color: const Color(0xFF1F2937),
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class _KeywordChip extends StatelessWidget {
  const _KeywordChip({
    required this.keyword,
    required this.onTap,
    this.onDeleted,
  });

  final String keyword;
  final VoidCallback onTap;
  final VoidCallback? onDeleted;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: EdgeInsets.fromLTRB(12, 8, onDeleted == null ? 12 : 8, 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                keyword,
                style: GoogleFonts.inter(
                  color: const Color(0xFF334155),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (onDeleted != null) ...[
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: onDeleted,
                  child: const Icon(
                    LucideIcons.x,
                    size: 13,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  const _SuggestionTile({
    required this.keyword,
    required this.onTap,
    this.subtitle,
  });

  final String keyword;
  final VoidCallback onTap;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: BoxConstraints(minHeight: subtitle == null ? 47 : 58),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Color(0xFFEDEDED), width: 1),
            ),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  keyword,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF111111),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: const Color(0xFF8A8A8A),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.sort, required this.onSortChanged});

  final String sort;
  final ValueChanged<String> onSortChanged;

  @override
  Widget build(BuildContext context) {
    final priceSelected = sort == 'PRICE_ASC' || sort == 'PRICE_DESC';
    final priceLabel = sort == 'PRICE_DESC'
        ? 'Giá ↓'
        : sort == 'PRICE_ASC'
        ? 'Giá ↑'
        : 'Giá ↕';

    return Column(
      children: [
        Container(
          height: 40,
          color: Colors.white,
          child: Row(
            children: [
              _ResultSortTab(
                label: 'Liên quan',
                selected: sort == 'RELEVANT',
                onTap: () => onSortChanged('RELEVANT'),
              ),
              const _FilterSeparator(),
              _ResultSortTab(
                label: 'Bán chạy',
                selected: sort == 'SOLD_DESC',
                onTap: () => onSortChanged('SOLD_DESC'),
              ),
              const _FilterSeparator(),
              _ResultSortTab(
                label: priceLabel,
                selected: priceSelected,
                onTap: () => onSortChanged('PRICE'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FilterSeparator extends StatelessWidget {
  const _FilterSeparator();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 16, color: const Color(0xFFE8E8E8));
  }
}

class _ResultSortTab extends StatelessWidget {
  const _ResultSortTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            Center(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: selected ? _shopeeOrange : const Color(0xFF4B5563),
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
            if (selected)
              const Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SizedBox(
                  height: 2,
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: _shopeeOrange),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SearchItemGrid extends StatelessWidget {
  const _SearchItemGrid({
    required this.items,
    required this.onTapItem,
    this.shrinkWrap = false,
    this.physics,
  });

  final List<SearchItem> items;
  final ValueChanged<SearchItem> onTapItem;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: shrinkWrap,
      physics: physics,
      padding: EdgeInsets.zero,
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        mainAxisExtent: _searchGridCardExtent,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return _SearchItemCard(item: item, onTap: () => onTapItem(item));
      },
    );
  }
}

class _SearchItemCard extends StatelessWidget {
  const _SearchItemCard({required this.item, required this.onTap});

  final SearchItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final imageUrl = ImageUrlUtil.buildPublicUrl(item.image);
    final showDistanceBadge =
        item.isService && item.distanceKm != null && item.distanceKm! < 15;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                SizedBox(
                  height: _searchCardImageHeight,
                  width: double.infinity,
                  child: imageUrl != null
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const _CardImageFallback(),
                        )
                      : const _CardImageFallback(),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: _SearchItemTypeBadge(item: item),
                ),
                if (showDistanceBadge)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF8A34),
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Text(
                        '${item.distanceKm!.toStringAsFixed(1)} km',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: const Color(0xFF0F172A),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        height: 1.24,
                      ),
                    ),
                    const SizedBox(height: 7),
                    if (item.shopName?.isNotEmpty == true) ...[
                      Text(
                        item.shopName!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: const Color(0xFF64748B),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                    Visibility(
                      visible: false,
                      child: Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 13),
                          const SizedBox(width: 3),
                          Text(
                            (item.rating ?? 0).toStringAsFixed(1),
                            style: GoogleFonts.inter(
                              color: const Color(0xFF475569),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (item.soldCount != null) ...[
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                'Đã bán ${item.soldCount}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF94A3B8),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 0),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            PriceFormatter.formatVnd(
                              item.price,
                              fallback: 'Liên hệ',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: const Color(0xFFFF4D4F),
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              height: 1.05,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _SearchItemRatingMeta(item: item),
                      ],
                    ),
                    Visibility(
                      visible: false,
                      child: Text(
                        PriceFormatter.formatVnd(
                          item.price,
                          fallback: 'Liên hệ',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: const Color(0xFFFF4D4F),
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          height: 1.05,
                        ),
                      ),
                    ),
                    if (item.address?.isNotEmpty == true) ...[
                      const SizedBox(height: 7),
                      Row(
                        children: [
                          const Icon(
                            LucideIcons.mapPin,
                            size: 11,
                            color: Color(0xFF94A3B8),
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              item.address!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                color: const Color(0xFF94A3B8),
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchItemRatingMeta extends StatelessWidget {
  const _SearchItemRatingMeta({required this.item});

  final SearchItem item;

  @override
  Widget build(BuildContext context) {
    final count = item.soldCount;
    final countLabel = count == null
        ? null
        : item.isService
        ? 'đã dùng $count'
        : 'đã bán $count';

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 92),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const Icon(Icons.star, color: Colors.amber, size: 13),
          const SizedBox(width: 3),
          Text(
            (item.rating ?? 0).toStringAsFixed(1),
            style: GoogleFonts.inter(
              color: const Color(0xFF475569),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (countLabel != null) ...[
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                countLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: GoogleFonts.inter(
                  color: const Color(0xFF94A3B8),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SearchItemTypeBadge extends StatelessWidget {
  const _SearchItemTypeBadge({required this.item});

  final SearchItem item;

  @override
  Widget build(BuildContext context) {
    final style = _resolveTypeStyle(item);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: style.color,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        style.label,
        style: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
  }

  ({String label, Color color}) _resolveTypeStyle(SearchItem item) {
    if (item.isService) {
      return (label: 'Dịch vụ', color: const Color(0xFFFF8A34));
    }
    if (item.isProduct) {
      return (label: 'Sản phẩm', color: const Color(0xFF3B82F6));
    }
    if (item.isShop) {
      return (label: 'Shop', color: const Color(0xFF0EA5A4));
    }
    return (label: item.type, color: const Color(0xFF64748B));
  }
}

class _CardImageFallback extends StatelessWidget {
  const _CardImageFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFE5E7EB),
      child: const Icon(LucideIcons.image, color: Color(0xFF94A3B8), size: 34),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.wifiOff, size: 42, color: Color(0xFF94A3B8)),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: const Color(0xFF334155),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFF5A4E),
              ),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: const Color(0xFF94A3B8)),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: const Color(0xFF1F2937),
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: const Color(0xFF64748B),
                fontSize: 12,
                fontWeight: FontWeight.w500,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchLocation {
  const _SearchLocation({this.lat, this.lng, this.radiusKm});

  final double? lat;
  final double? lng;
  final double? radiusKm;
}
