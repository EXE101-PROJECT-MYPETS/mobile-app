import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:petpee_mobile/apps/product/model/product_model.dart';
import 'package:petpee_mobile/apps/product/api/product_service.dart';
import 'package:petpee_mobile/apps/cart/model/cart_item_model.dart';
import 'package:petpee_mobile/apps/profile/model/pet_model.dart';
import 'package:petpee_mobile/apps/checkout/model/address_model.dart';

class AppState extends ChangeNotifier {
  final ProductService _productService = ProductService();

  // --- REAL PRODUCT DATA ---
  List<ProductModel> _allProducts = [];
  bool _isLoadingProducts = false;
  String? _productsError;
  int? _productCursor;
  bool _hasMoreProducts = true;

  bool get hasMoreProducts => _hasMoreProducts;

  // --- MOCK DATA FOR OTHER FEATURES ---
  final Set<String> _likedProductIds = {};
  List<String> _viewedCategories = [];
  List<String> _viewedProductIds = [];

  // --- MOCK CART DATA ---
  final List<CartItemModel> _cartItems = [
    CartItemModel(
      id: 'c1',
      product: ProductModel(id: 'c1_p', name: 'Gói spa cơ bản cho mèo', price: '199.000đ', rating: 4.8, reviews: 10, image: 'https://picsum.photos/seed/cart1/200', type: 'spa', category: 'Spa'),
      shopName: 'PETPEEs Mall',
      quantity: 1,
    ),
    CartItemModel(
      id: 'c2',
      product: ProductModel(id: 'c2_p', name: 'Gói spa cao cấp cho chó', price: '349.000đ', rating: 4.9, reviews: 20, image: 'https://picsum.photos/seed/cart2/200', type: 'spa', category: 'Spa'),
      shopName: 'Spa House Official',
      quantity: 2,
    ),
    CartItemModel(
      id: 'c3',
      product: ProductModel(id: 'c3_p', name: 'Khám tổng quát cho chó', price: '259.000đ', rating: 4.7, reviews: 5, image: 'https://picsum.photos/seed/cart3/200', type: 'thu_y', category: 'Thú y'),
      shopName: 'Doggo Planet',
      quantity: 3,
    ),
  ];

  // --- MOCK PET DATA ---
  final List<PetModel> _myPets = [
    PetModel(
      id: 'p1',
      name: 'Bông',
      type: 'Chó',
      breed: 'Golden Retriever',
      shopName: 'Doggo Planet',
      gender: 'Đực',
      age: '4 tuổi 10 tháng',
      note: 'Đã tiêm phòng đầy đủ',
      image: 'https://picsum.photos/seed/pet1/200'
    ),
    PetModel(
      id: 'p2',
      name: 'Nấm',
      type: 'Mèo',
      breed: 'Anh lông ngắn',
      shopName: 'PETPEEs Mall',
      gender: 'Cái',
      age: '2 tuổi 1 tháng',
      note: 'Ưa thích thức ăn hạt mềm',
      image: 'https://picsum.photos/seed/pet2/200'
    ),
  ];

  // --- MOCK ADDRESS DATA ---
  List<AddressModel> _addresses = [
    AddressModel(
      id: 'a1',
      name: 'Lê Hồng Sơn',
      phone: '(+84) 355 075 204',
      location: 'Số 344, thôn 4',
      region: 'Xã Thạch Hòa, Huyện Thạch Thất, Hà Nội',
      isDefault: true,
      type: 'Nhà Riêng',
    ),
    AddressModel(
      id: 'a2',
      name: 'Lê Trường',
      phone: '(+84) 989 162 659',
      location: 'Khu 4 Số Nhà 75',
      region: 'Thị Trấn Cao Phong, Huyện Cao Phong, Hòa Bình',
      isDefault: false,
      type: 'Nhà Riêng',
    ),
  ];

  // Getters
  List<ProductModel> get allProducts => _allProducts;
  bool get isLoadingProducts => _isLoadingProducts;
  String? get productsError => _productsError;
  List<String> get viewedCategories => _viewedCategories;
  Set<String> get likedProductIds => _likedProductIds;
  List<CartItemModel> get cartItems => _cartItems;
  List<PetModel> get myPets => _myPets;
  List<AddressModel> get addresses => _addresses;
  AddressModel? get defaultAddress {
    try {
      return _addresses.firstWhere((a) => a.isDefault);
    } catch (_) {
      return _addresses.isNotEmpty ? _addresses.first : null;
    }
  }

  List<ProductModel> get likedProducts {
    return _allProducts.where((p) => _likedProductIds.contains(p.id)).toList();
  }

  List<ProductModel> get recentlyViewedProducts {
    // Return in order of recently viewed
    return _viewedProductIds.map((id) => getProductById(id)).whereType<ProductModel>().toList();
  }

  // --- INIT HIVE ---
  AppState() {
    _loadData();
    loadProducts(); // Load products from API on initialization
  }

  Future<void> _loadData() async {
    final box = await Hive.openBox('user_preferences');

    // Load viewed categories
    final savedCategories = box.get('viewedCategories');
    if (savedCategories != null) {
      _viewedCategories = List<String>.from(savedCategories);
    }

    // Load viewed products history
    final savedProducts = box.get('viewedProductIds');
    if (savedProducts != null) {
      _viewedProductIds = List<String>.from(savedProducts);
    }

    // NOTE: In the future, load liked ids from BE here
    // for now, we just use the in-memory set.
    notifyListeners();
  }

  // --- PRODUCT API METHODS ---

  /// Load products from backend API
  Future<void> loadProducts({
    int shopId = 1, // Default shop ID, should be configurable
    String? keyword,
    bool? active,
    int? cursor,
    int size = 20,
  }) async {
    if (_isLoadingProducts) return;

    _isLoadingProducts = true;
    _productsError = null;
    notifyListeners();

    try {
      final response = await _productService.getAllMobile(
        shopId: shopId,
        keyword: keyword,
        active: active,
        cursor: cursor,
        size: size,
      );

      // Convert DTOs to ProductModels
      _allProducts = response.content
          .map((dto) => ProductModel.fromDTO(dto))
          .toList();
      _productCursor = response.nextCursor;
      _hasMoreProducts = response.hasNext;
      _productsError = null;
    } catch (e) {
      _productsError = 'Không thể tải sản phẩm: $e';
      // Keep existing products if API fails
    } finally {
      _isLoadingProducts = false;
      notifyListeners();
    }
  }

  /// Load more products (pagination)
  Future<void> loadMoreProducts({
    int shopId = 1,
    String? keyword,
    bool? active,
    int? cursor,
    int size = 20,
  }) async {
    if (_isLoadingProducts || !_hasMoreProducts) return;

    _isLoadingProducts = true;
    notifyListeners();

    try {
      final response = await _productService.getAllMobile(
        shopId: shopId,
        keyword: keyword,
        active: active,
        cursor: cursor ?? _productCursor,
        size: size,
      );

      final newProducts = response.content
          .map((dto) => ProductModel.fromDTO(dto))
          .toList();

      if (newProducts.isNotEmpty) {
        _allProducts.addAll(newProducts);
      }
      _productCursor = response.nextCursor;
      _hasMoreProducts = response.hasNext;

      if (newProducts.isEmpty && !response.hasNext) {
        _hasMoreProducts = false;
      }
    } catch (e) {
      _productsError = 'Không thể tải thêm sản phẩm: $e';
    } finally {
      _isLoadingProducts = false;
      notifyListeners();
    }
  }

  // --- ACTIONS ---

  /// Gọi khi người dùng xem 1 sản phẩm
  Future<void> logProductViewed(ProductModel product) async {
    // 1. Cập nhật danh mục
    if (product.category != 'Tất cả' && product.category.isNotEmpty) {
      _viewedCategories.remove(product.category);
      _viewedCategories.insert(0, product.category);
      if (_viewedCategories.length > 5) {
        _viewedCategories = _viewedCategories.sublist(0, 5);
      }
    }

    // 2. Cập nhật sản phẩm
    _viewedProductIds.remove(product.id);
    _viewedProductIds.insert(0, product.id);
    if (_viewedProductIds.length > 20) {
      _viewedProductIds = _viewedProductIds.sublist(0, 20); // Lưu tối đa 20 sp gần nhất
    }

    // 3. Save to local storage
    final box = await Hive.openBox('user_preferences');
    await box.put('viewedCategories', _viewedCategories);
    await box.put('viewedProductIds', _viewedProductIds);

    notifyListeners();
  }

  /// Toggle Like/Unlike (Giả lập gọi Backend)
  Future<void> toggleLike(String productId) async {
    // Tạm thời mô phỏng thời gian chờ BE
    // await Future.delayed(const Duration(milliseconds: 200));

    if (_likedProductIds.contains(productId)) {
      _likedProductIds.remove(productId);
    } else {
      _likedProductIds.add(productId);
    }
    notifyListeners();
  }

  bool isLiked(String productId) {
    return _likedProductIds.contains(productId);
  }

  // Lấy các sản phẩm có danh mục nằm trong lịch sử xem
  List<ProductModel> get similarProducts {
    if (_viewedCategories.isEmpty) return [];
    
    return _allProducts.where((p) {
      return _viewedCategories.contains(p.category);
    }).toList();
  }

  ProductModel? getProductById(String id) {
    try {
      return _allProducts.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  // --- CART ACTIONS ---

  void toggleCartSelection(String id, bool? value) {
    final item = _cartItems.firstWhere((i) => i.id == id);
    item.isSelected = value ?? false;
    notifyListeners();
  }

  void toggleAllCartSelection(bool? value) {
    for (var item in _cartItems) {
      item.isSelected = value ?? false;
    }
    notifyListeners();
  }

  void updateCartQuantity(String id, int delta) {
    final item = _cartItems.firstWhere((i) => i.id == id);
    if (item.quantity + delta > 0) {
      item.quantity += delta;
      notifyListeners();
    }
  }

  void removeFromCart(String id) {
    _cartItems.removeWhere((i) => i.id == id);
    notifyListeners();
  }

  void addToCart(ProductModel product, String shopName, [int quantity = 1]) {
    final index = _cartItems.indexWhere((i) => i.product.id == product.id && i.shopName == shopName);
    if (index >= 0) {
      _cartItems[index].quantity += quantity;
    } else {
      _cartItems.add(CartItemModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        product: product,
        shopName: shopName,
        quantity: quantity,
      ));
    }
    notifyListeners();
  }

  double get cartTotalPrice {
    return _cartItems.where((i) => i.isSelected).fold(0.0, (sum, item) => sum + (item.priceAsDouble * item.quantity));
  }
  
  bool get isAllCartSelected {
    if (_cartItems.isEmpty) return false;
    return _cartItems.every((i) => i.isSelected);
  }

  // --- PET ACTIONS ---

  void addPet(PetModel pet) {
    _myPets.add(pet);
    notifyListeners();
  }

  void removePet(String id) {
    _myPets.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  // --- ADDRESS ACTIONS ---

  void addAddress(AddressModel address) {
    if (address.isDefault) {
      // Set all other addresses to non-default
      _addresses = _addresses.map((existingAddress) {
        return AddressModel(
          id: existingAddress.id,
          name: existingAddress.name,
          phone: existingAddress.phone,
          location: existingAddress.location,
          region: existingAddress.region,
          type: existingAddress.type,
          isDefault: false,
        );
      }).toList();
    }
    _addresses.add(address);
    notifyListeners();
  }

  void setDefaultAddress(String id) {
    // In a real app we'd copy models or update fields
    // Here we'll do a simple rebuild of the list
    final updatedList = _addresses.map((a) {
      return AddressModel(
        id: a.id,
        name: a.name,
        phone: a.phone,
        location: a.location,
        region: a.region,
        type: a.type,
        isDefault: a.id == id,
      );
    }).toList();
    _addresses.clear();
    _addresses.addAll(updatedList);
    notifyListeners();
  }

  // --- CLEANUP ---
  @override
  void dispose() {
    _productService.dispose();
    super.dispose();
  }
}
