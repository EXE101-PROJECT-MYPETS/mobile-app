import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:petpee_mobile/apps/checkout/api/address_service.dart';
import 'package:petpee_mobile/apps/product/model/product_model.dart';
import 'package:petpee_mobile/apps/product/api/product_service.dart';
import 'package:petpee_mobile/apps/service/api/service_service.dart';
import 'package:petpee_mobile/common/user/dto/service_public_dto.dart';
import 'package:petpee_mobile/apps/cart/model/cart_item_model.dart';
import 'package:petpee_mobile/apps/profile/api/pet_service.dart';
import 'package:petpee_mobile/apps/profile/model/pet_model.dart';
import 'package:petpee_mobile/apps/checkout/model/address_model.dart';

class AppState extends ChangeNotifier {
  final ProductService _productService = ProductService();
  final ServicePublicService _servicePublicService = ServicePublicService();
  final AddressService _addressService = AddressService();
  final PetService _petService = PetService();

  // --- REAL PRODUCT DATA ---
  List<ProductModel> _allProducts = [];
  bool _isLoadingProducts = false;
  String? _productsError;
  int? _productCursor;
  bool _hasMoreProducts = true;

  // --- REAL SERVICE DATA ---
  List<ServicePublicDTO> _allServices = [];
  bool _isLoadingServices = false;
  String? _servicesError;
  int? _serviceCursor;
  bool _hasMoreServices = true;
  double? _serviceUserLat;
  double? _serviceUserLng;
  double _serviceRadiusKm = 5;

  // --- VETERINARY SERVICE DATA ---
  List<ServicePublicDTO> _veterinaryServices = [];
  bool _isLoadingVeterinary = false;
  String? _veterinaryError;
  int? _veterinaryCursor;
  bool _hasMoreVeterinary = true;

  bool get hasMoreProducts => _hasMoreProducts;

  // --- MOCK DATA FOR OTHER FEATURES ---
  final Set<String> _likedProductIds = {};
  List<String> _viewedCategories = [];
  List<String> _viewedProductIds = [];
  final Map<String, ProductModel> _viewedProductCache = {};

  // --- CART DATA ---
  List<CartItemModel> _cartItems = [];
  int? _currentUserId;

  // --- MOCK PET DATA ---
  final List<PetModel> _myPets = [];
  bool _isLoadingPets = false;
  String? _petsError;

  // --- ADDRESS DATA ---
  List<AddressModel> _addresses = [];
  bool _isLoadingAddresses = false;
  String? _addressesError;

  // Getters
  List<ProductModel> get allProducts => _allProducts;
  bool get isLoadingProducts => _isLoadingProducts;
  String? get productsError => _productsError;
  List<String> get viewedCategories => _viewedCategories;
  Set<String> get likedProductIds => _likedProductIds;
  List<CartItemModel> get cartItems => _cartItems;
  List<PetModel> get myPets => _myPets;
  bool get isLoadingPets => _isLoadingPets;
  String? get petsError => _petsError;
  List<AddressModel> get addresses => _addresses;
  bool get isLoadingAddresses => _isLoadingAddresses;
  String? get addressesError => _addressesError;

  // Service getters
  List<ServicePublicDTO> get allServices => _allServices;
  bool get isLoadingServices => _isLoadingServices;
  String? get servicesError => _servicesError;
  bool get hasMoreServices => _hasMoreServices;

  // Veterinary getters
  List<ServicePublicDTO> get veterinaryServices => _veterinaryServices;
  bool get isLoadingVeterinary => _isLoadingVeterinary;
  String? get veterinaryError => _veterinaryError;
  bool get hasMoreVeterinary => _hasMoreVeterinary;
  double? get serviceUserLat => _serviceUserLat;
  double? get serviceUserLng => _serviceUserLng;
  double get serviceRadiusKm => _serviceRadiusKm;
  int? get currentUserId => _currentUserId;
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
    return _viewedProductIds
        .map((id) => _viewedProductCache[id] ?? getProductById(id))
        .whereType<ProductModel>()
        .toList();
  }

  /// Load recently viewed products from Hive persistence
  Future<void> loadRecentlyViewedProducts() async {
    try {
      final box = await Hive.openBox('user_preferences');
      final viewedIds = box.get('viewedProductIds') ?? [];
      final viewedData = box.get('viewedProductsData') ?? {};

      _viewedProductIds = List<String>.from(viewedIds);

      _viewedProductCache.clear();
      for (final id in _viewedProductIds) {
        if (viewedData[id] != null) {
          final data = Map<String, dynamic>.from(
            viewedData[id] as Map<dynamic, dynamic>,
          );
          _viewedProductCache[id] = ProductModel.fromMap(data);
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading recently viewed products: $e');
    }
  }

  Future<void> loadMyPets() async {
    _isLoadingPets = true;
    _petsError = null;
    notifyListeners();

    try {
      final petDtos = await _petService.getAll();
      _myPets
        ..clear()
        ..addAll(petDtos.map(PetModel.fromDTO));
      _petsError = null;
    } catch (error) {
      _petsError = error.toString();
    } finally {
      _isLoadingPets = false;
      notifyListeners();
    }
  }

  Future<void> loadCurrentUserAddresses(String? accessToken) async {
    if (_isLoadingAddresses) return;

    if (accessToken == null || accessToken.isEmpty) {
      _addresses = [];
      _addressesError = null;
      notifyListeners();
      return;
    }

    _isLoadingAddresses = true;
    _addressesError = null;
    notifyListeners();

    try {
      _addresses = await _addressService.getCurrentUserAddresses(accessToken);
    } catch (e) {
      _addresses = [];
      _addressesError = e.toString();
    } finally {
      _isLoadingAddresses = false;
      notifyListeners();
    }
  }

  // --- INIT HIVE ---
  AppState() {
    // Initialize with empty lists first
    _allServices = [];
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

    final savedViewedData = box.get('viewedProductsData');
    if (savedViewedData is Map) {
      _viewedProductCache.clear();
      for (final entry in savedViewedData.entries) {
        if (entry.key is String && entry.value is Map) {
          _viewedProductCache[entry.key as String] = ProductModel.fromMap(
            Map<String, dynamic>.from(entry.value as Map),
          );
        }
      }
    }

    // NOTE: In the future, load liked ids from BE here
    // for now, we just use the in-memory set.
    notifyListeners();
  }

  // --- PRODUCT API METHODS ---

  /// Load products from backend API
  Future<void> loadProducts({
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
      _viewedProductIds = _viewedProductIds.sublist(0, 20);
    }

    // 3. Save to local storage (Hive) - save both IDs and full product data
    final box = await Hive.openBox('user_preferences');
    await box.put('viewedCategories', _viewedCategories);
    await box.put('viewedProductIds', _viewedProductIds);
    _viewedProductCache[product.id] = product;

    // Store full product as JSON for persistence
    final viewedProductsJson = Map<String, dynamic>.from(
      box.get('viewedProductsData') ?? <String, dynamic>{},
    );
    viewedProductsJson[product.id] = {
      'id': product.id,
      'name': product.name,
      'price': product.price,
      'rating': product.rating,
      'reviews': product.reviews,
      'image': product.image,
      'type': product.type,
      'category': product.category,
      'description': product.description,
      'shopProvince': product.shopProvince,
      'timestamp': DateTime.now().toIso8601String(),
    };
    await box.put('viewedProductsData', viewedProductsJson);

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

  Future<void> loadUserCart(int? userId) async {
    _currentUserId = userId;
    final box = await Hive.openBox('user_preferences');
    final cartKey = 'cart_${_currentUserId ?? "guest"}';
    final savedCart = box.get(cartKey);

    if (savedCart is List) {
      _cartItems = savedCart.map((item) {
        return CartItemModel.fromMap(Map<String, dynamic>.from(item as Map));
      }).toList();
    } else {
      _cartItems = [];
    }
    notifyListeners();
  }

  Future<void> _saveUserCart() async {
    final box = await Hive.openBox('user_preferences');
    final cartKey = 'cart_${_currentUserId ?? "guest"}';
    final cartData = _cartItems.map((item) => item.toMap()).toList();
    await box.put(cartKey, cartData);
  }

  void toggleCartSelection(String id, bool? value) {
    final item = _cartItems.firstWhere((i) => i.id == id);
    item.isSelected = value ?? false;
    _saveUserCart();
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
    if (item.isService) return;
    if (item.quantity + delta > 0) {
      item.quantity += delta;
      _saveUserCart();
      notifyListeners();
    }
  }

  void removeFromCart(String id) {
    _cartItems.removeWhere((i) => i.id == id);
    _saveUserCart();
    notifyListeners();
  }

  void addToCart(
    ProductModel product,
    String shopName, {
    int? shopId,
    int quantity = 1,
  }) {
    final index = _cartItems.indexWhere(
      (i) => !i.isService && i.productId == _parseId(product.id) && i.shopName == shopName,
    );
    if (index >= 0) {
      _cartItems[index].quantity += quantity;
    } else {
      _cartItems.add(
        CartItemModel.product(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          shopId: shopId ?? 0,
          shopName: shopName,
          productId: _parseId(product.id) ?? DateTime.now().millisecondsSinceEpoch,
          name: product.name,
          imageUrl: product.image,
          unitPrice: _parsePrice(product.price),
          quantity: quantity,
          isSelected: true,
          description: product.description,
        ),
      );
    }
    _saveUserCart();
    notifyListeners();
  }

  void addServiceToCart(
    ServicePublicDTO service,
    {int quantity = 1}
  ) {
    final serviceId = service.id ?? DateTime.now().millisecondsSinceEpoch;
    final index = _cartItems.indexWhere(
      (item) => item.isService && item.serviceId == serviceId,
    );

    if (index >= 0) {
      _cartItems[index].quantity += quantity;
    } else {
      _cartItems.add(
        CartItemModel.service(
          id: 'service-$serviceId-${DateTime.now().millisecondsSinceEpoch}',
          shopId: service.shopId ?? 0,
          shopName: service.shopName ?? 'Cửa hàng',
          serviceId: serviceId,
          name: service.name ?? 'Dịch vụ spa',
          imageUrl: service.imageUrl ?? '',
          unitPrice: service.basePrice ?? 0,
          durationMin: service.durationMin ?? 0,
          quantity: quantity,
          isSelected: true,
          description: service.shopAddress,
        ),
      );
    }

    _saveUserCart();
    notifyListeners();
  }

  void prepareBuyNow(
    ProductModel product,
    String shopName, {
    int? shopId,
    int quantity = 1,
  }) {
    for (final item in _cartItems) {
      item.isSelected = false;
    }

    final index = _cartItems.indexWhere(
      (i) => !i.isService && i.productId == _parseId(product.id) && i.shopName == shopName,
    );
    if (index >= 0) {
      _cartItems[index].quantity = quantity;
      _cartItems[index].isSelected = true;
    } else {
      _cartItems.add(
        CartItemModel.product(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          shopId: shopId ?? 0,
          shopName: shopName,
          productId: _parseId(product.id) ?? DateTime.now().millisecondsSinceEpoch,
          name: product.name,
          imageUrl: product.image,
          unitPrice: _parsePrice(product.price),
          quantity: quantity,
          isSelected: true,
          description: product.description,
        ),
      );
    }

    _saveUserCart();
    notifyListeners();
  }

  void prepareBuyNowService(
    ServicePublicDTO service, {
    int quantity = 1,
  }) {
    for (final item in _cartItems) {
      item.isSelected = false;
    }

    final serviceId = service.id ?? DateTime.now().millisecondsSinceEpoch;
    final index = _cartItems.indexWhere(
      (item) => item.isService && item.serviceId == serviceId,
    );

    if (index >= 0) {
      _cartItems[index].quantity = quantity;
      _cartItems[index].isSelected = true;
    } else {
      _cartItems.add(
        CartItemModel.service(
          id: 'service-$serviceId-${DateTime.now().millisecondsSinceEpoch}',
          shopId: service.shopId ?? 0,
          shopName: service.shopName ?? 'Cửa hàng',
          serviceId: serviceId,
          name: service.name ?? 'Dịch vụ spa',
          imageUrl: service.imageUrl ?? '',
          unitPrice: service.basePrice ?? 0,
          durationMin: service.durationMin ?? 0,
          quantity: quantity,
          isSelected: true,
          description: service.shopAddress,
        ),
      );
    }

    _saveUserCart();
    notifyListeners();
  }

  double get cartTotalPrice {
    return _cartItems
        .where((i) => i.isSelected)
        .fold(0.0, (sum, item) => sum + item.amount.toDouble());
  }

  bool get isAllCartSelected {
    if (_cartItems.isEmpty) return false;
    return _cartItems.every((i) => i.isSelected);
  }

  List<CartItemModel> get selectedCartItems {
    return _cartItems.where((item) => item.isSelected).toList();
  }

  void clearSelectedCartItems() {
    _cartItems.removeWhere((item) => item.isSelected);
    _saveUserCart();
    notifyListeners();
  }

  void removeSelectedCartItems() {
    clearSelectedCartItems();
  }

  void unselectCartItems(Iterable<String> ids) {
    final idSet = ids.toSet();
    for (final item in _cartItems) {
      if (idSet.contains(item.id)) {
        item.isSelected = false;
      }
    }
    _saveUserCart();
    notifyListeners();
  }

  int? _parseId(String id) {
    return int.tryParse(id);
  }

  int _parsePrice(String priceText) {
    final normalized = priceText.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(normalized) ?? 0;
  }

  // --- PET ACTIONS ---

  void addPet(PetModel pet) {
    _myPets.add(pet);
    notifyListeners();
  }

  void removePet(int id) {
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

  // --- SERVICE API METHODS ---

  /// Load services from backend API
  Future<void> loadServices({
    int? shopId,
    String? search,
    int? categoryId,
    bool active = true,
    double? minRating,
    double? lat,
    double? lng,
    double? radiusKm,
    int? cursor,
    int size = 20,
  }) async {
    if (_isLoadingServices) return;

    if (lat != null) {
      _serviceUserLat = lat;
    }
    if (lng != null) {
      _serviceUserLng = lng;
    }
    if (radiusKm != null && radiusKm > 0) {
      _serviceRadiusKm = radiusKm;
    }

    final effectiveLat = lat ?? _serviceUserLat;
    final effectiveLng = lng ?? _serviceUserLng;
    final effectiveRadiusKm = effectiveLat != null && effectiveLng != null
        ? (radiusKm ?? _serviceRadiusKm)
        : null;

    _isLoadingServices = true;
    _servicesError = null;
    notifyListeners();

    try {
      final response = await _servicePublicService.getAllForScroll(
        shopId: shopId,
        search: search,
        categoryId: categoryId,
        active: active,
        minRating: minRating,
        lat: effectiveLat,
        lng: effectiveLng,
        radiusKm: effectiveRadiusKm,
        cursor: cursor,
        size: size,
      );

      _allServices = response.content;
      _serviceCursor = response.nextCursor;
      _hasMoreServices = response.hasNext;
      _servicesError = null;
    } catch (e) {
      _servicesError = 'Không thể tải dịch vụ: $e';
      // Keep existing services if API fails
    } finally {
      _isLoadingServices = false;
      notifyListeners();
    }
  }

  /// Load veterinary services from backend API (endpoint filters to VETERINARY)
  Future<void> loadVeterinaryServices({
    int? shopId,
    String? search,
    int? categoryId,
    bool active = true,
    double? minRating,
    double? lat,
    double? lng,
    double? radiusKm,
    int? perShopLimit = 5,
    int? cursor,
    int size = 20,
  }) async {
    if (_isLoadingVeterinary) return;

    // Store last known user location
    if (lat != null) {
      _serviceUserLat = lat;
    }
    if (lng != null) {
      _serviceUserLng = lng;
    }

    final effectiveLat = lat ?? _serviceUserLat;
    final effectiveLng = lng ?? _serviceUserLng;
    final effectiveRadiusKm = effectiveLat != null && effectiveLng != null
        ? (radiusKm ?? _serviceRadiusKm)
        : null;

    _isLoadingVeterinary = true;
    _veterinaryError = null;
    notifyListeners();

    try {
      final response = await _servicePublicService.getVeterinaryForScroll(
        shopId: shopId,
        search: search,
        categoryId: categoryId,
        active: active,
        minRating: minRating,
        lat: effectiveLat,
        lng: effectiveLng,
        radiusKm: effectiveRadiusKm,
        perShopLimit: perShopLimit,
        cursor: cursor,
        size: size,
      );

      _veterinaryServices = response.content;
      _veterinaryCursor = response.nextCursor;
      _hasMoreVeterinary = response.hasNext;
      _veterinaryError = null;
    } catch (e) {
      _veterinaryError = 'Không thể tải dịch vụ thú y: $e';
    } finally {
      _isLoadingVeterinary = false;
      notifyListeners();
    }
  }

  /// Load more services (pagination)
  Future<void> loadMoreServices({
    int? shopId,
    String? search,
    int? categoryId,
    bool active = true,
    double? minRating,
    double? lat,
    double? lng,
    double? radiusKm,
    int? cursor,
    int size = 20,
  }) async {
    if (_isLoadingServices || !_hasMoreServices) return;

    final effectiveLat = lat ?? _serviceUserLat;
    final effectiveLng = lng ?? _serviceUserLng;
    final effectiveRadiusKm = radiusKm ?? _serviceRadiusKm;

    _isLoadingServices = true;
    notifyListeners();

    try {
      final response = await _servicePublicService.getAllForScroll(
        shopId: shopId,
        search: search,
        categoryId: categoryId,
        active: active,
        minRating: minRating,
        lat: effectiveLat,
        lng: effectiveLng,
        radiusKm: effectiveRadiusKm,
        cursor: cursor ?? _serviceCursor,
        size: size,
      );

      if (response.content.isNotEmpty) {
        _allServices.addAll(response.content);
      }
      _serviceCursor = response.nextCursor;
      _hasMoreServices = response.hasNext;

      if (response.content.isEmpty && !response.hasNext) {
        _hasMoreServices = false;
      }
    } catch (e) {
      _servicesError = 'Không thể tải thêm dịch vụ: $e';
    } finally {
      _isLoadingServices = false;
      notifyListeners();
    }
  }

}
