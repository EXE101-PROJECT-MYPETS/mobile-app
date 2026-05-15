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
  String _type = 'ALL';
  String _sort = 'RELEVANT';
  int _page = 0;
  int _totalElements = 0;
  bool _hasNext = false;
  bool _ignoreTextChange = false;

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
      _totalElements = 0;
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
        sort: _sort,
        page: 0,
        size: 20,
      );
      if (!mounted) return;
      setState(() {
        _results = response.content;
        _page = response.page;
        _hasNext = response.hasNext;
        _totalElements = response.totalElements;
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
    setState(() => _loadMoreLoading = true);

    try {
      final response = await _searchService.search(
        keyword: _activeKeyword,
        type: _type,
        lat: location.lat,
        lng: location.lng,
        radiusKm: location.radiusKm,
        sort: _sort,
        page: _page + 1,
        size: 20,
      );
      if (!mounted) return;
      setState(() {
        _results = [..._results, ...response.content];
        _page = response.page;
        _hasNext = response.hasNext;
        _totalElements = response.totalElements;
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

  void _changeType(String value) {
    if (_type == value) return;
    setState(() => _type = value);
    if (_activeKeyword.isNotEmpty) {
      _performSearch(_activeKeyword);
    }
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
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      children: [
        if (_suggestionLoading) const LinearProgressIndicator(minHeight: 2),
        if (!_suggestionLoading && _suggestions.isEmpty)
          _SuggestionTile(
            keyword: keyword,
            subtitle: 'Tìm kiếm chính xác từ khóa này',
            onTap: () => _submitKeyword(keyword),
          ),
        ..._suggestions.map(
          (item) =>
              _SuggestionTile(keyword: item, onTap: () => _submitKeyword(item)),
        ),
      ],
    );
  }

  Widget _buildResultBody() {
    if (_searchLoading) {
      return Column(
        children: [
          _FilterBar(
            type: _type,
            sort: _sort,
            totalElements: _totalElements,
            onTypeChanged: _changeType,
            onSortChanged: _changeSort,
          ),
          const Expanded(child: Center(child: CircularProgressIndicator())),
        ],
      );
    }

    if (_searchError != null) {
      return Column(
        children: [
          _FilterBar(
            type: _type,
            sort: _sort,
            totalElements: _totalElements,
            onTypeChanged: _changeType,
            onSortChanged: _changeSort,
          ),
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
          _FilterBar(
            type: _type,
            sort: _sort,
            totalElements: _totalElements,
            onTypeChanged: _changeType,
            onSortChanged: _changeSort,
          ),
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
        _FilterBar(
          type: _type,
          sort: _sort,
          totalElements: _totalElements,
          onTypeChanged: _changeType,
          onSortChanged: _changeSort,
        ),
        Expanded(
          child: GridView.builder(
            controller: _resultScrollController,
            padding: EdgeInsets.fromLTRB(
              12,
              10,
              12,
              _loadMoreLoading ? 84 : 24,
            ),
            itemCount: _results.length + (_loadMoreLoading ? 1 : 0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
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
      ],
    );
  }
}

class _SearchHeader extends StatelessWidget {
  const _SearchHeader({
    required this.controller,
    required this.focusNode,
    required this.onBack,
    required this.onClear,
    required this.onSearch,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onBack;
  final VoidCallback onClear;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 10, 8, 10),
      decoration: const BoxDecoration(color: Colors.white),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(
              LucideIcons.arrowLeft,
              color: Color(0xFFFF6B57),
              size: 28,
            ),
          ),
          Expanded(
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFF6B57), width: 1.4),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 14),
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
                        hintText: 'Đồ Công Nghệ -50%',
                        hintStyle: GoogleFonts.inter(
                          color: const Color(0xFFCBD5E1),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        isCollapsed: true,
                      ),
                      style: GoogleFonts.inter(
                        color: const Color(0xFF1F2937),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: controller,
                    builder: (context, value, child) {
                      if (value.text.trim().isEmpty) {
                        return Container(
                          width: 48,
                          height: 50,
                          decoration: const BoxDecoration(
                            border: Border(
                              left: BorderSide(color: Color(0xFFFECACA)),
                            ),
                          ),
                          child: const Icon(
                            LucideIcons.camera,
                            color: Color(0xFF737373),
                            size: 22,
                          ),
                        );
                      }

                      return GestureDetector(
                        onTap: onClear,
                        child: Container(
                          width: 48,
                          height: 50,
                          decoration: const BoxDecoration(
                            border: Border(
                              left: BorderSide(color: Color(0xFFFECACA)),
                            ),
                          ),
                          child: const Icon(
                            LucideIcons.x,
                            color: Color(0xFF737373),
                            size: 20,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 56,
            height: 50,
            child: FilledButton(
              onPressed: onSearch,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFF5A32),
                foregroundColor: Colors.white,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Icon(
                LucideIcons.search,
                color: Colors.white,
                size: 22,
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
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              const Icon(
                LucideIcons.search,
                size: 17,
                color: Color(0xFF94A3B8),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      keyword,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: const Color(0xFF1F2937),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: GoogleFonts.inter(
                          color: const Color(0xFF94A3B8),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(
                LucideIcons.chevronRight,
                size: 16,
                color: Color(0xFFCBD5E1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.type,
    required this.sort,
    required this.totalElements,
    required this.onTypeChanged,
    required this.onSortChanged,
  });

  final String type;
  final String sort;
  final int totalElements;
  final ValueChanged<String> onTypeChanged;
  final ValueChanged<String> onSortChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFD5F4FF),
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (totalElements > 0)
            Padding(
              padding: const EdgeInsets.only(left: 2, bottom: 6),
              child: Text(
                '$totalElements kết quả',
                style: GoogleFonts.inter(
                  color: const Color(0xFF64748B),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterPill(
                  label: 'Tất cả',
                  selected: type == 'ALL',
                  onTap: () => onTypeChanged('ALL'),
                ),
                _FilterPill(
                  label: 'Dịch vụ',
                  selected: type == 'SERVICE',
                  onTap: () => onTypeChanged('SERVICE'),
                ),
                _FilterPill(
                  label: 'Sản phẩm',
                  selected: type == 'PRODUCT',
                  onTap: () => onTypeChanged('PRODUCT'),
                ),
                _FilterPill(
                  label: 'Gần nhất',
                  selected: sort == 'NEAREST',
                  onTap: () => onSortChanged('NEAREST'),
                ),
                _FilterPill(
                  label: sort == 'PRICE_DESC' ? 'Giá ↓' : 'Giá ↑',
                  selected: sort == 'PRICE_ASC' || sort == 'PRICE_DESC',
                  onTap: () => onSortChanged('PRICE'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: selected ? const Color(0xFFFF5A4E) : Colors.white,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              label,
              style: GoogleFonts.inter(
                color: selected ? Colors.white : const Color(0xFF334155),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
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
