import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:petpee_mobile/apps/home/api/shop_marker_service.dart';
import 'package:petpee_mobile/common/utils/external_url_launcher.dart';
import 'package:petpee_mobile/common/user/dto/shop_marker_dto.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const LatLng _defaultCenter = LatLng(10.7769, 106.7009);
  static const double _expandedMarkerZoom = 14.2;

  late final MapController mapController;
  final ShopMarkerService _shopMarkerService = const ShopMarkerService();

  LatLng? currentLocation;
  List<ShopMarkerDTO> shopMarkers = const [];
  bool isLoading = true;
  String? errorMessage;
  double _currentZoom = 15;

  @override
  void initState() {
    super.initState();
    mapController = MapController();
    _loadMapData();
  }

  @override
  void dispose() {
    mapController.dispose();
    super.dispose();
  }

  Future<void> _loadMapData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final markers = await _shopMarkerService.getAllMarkers();
      final location = await _tryGetCurrentLocation();

      if (!mounted) return;

      setState(() {
        shopMarkers = markers;
        currentLocation = location;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('[MapScreen] Failed to load shop markers: $e');

      if (!mounted) return;

      setState(() {
        errorMessage = 'Không tải được danh sách cửa hàng.';
        isLoading = false;
      });
    }
  }

  Future<LatLng?> _tryGetCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      debugPrint('[MapScreen] GPS service enabled: $serviceEnabled');

      if (!serviceEnabled) return null;

      var permission = await Geolocator.checkPermission();
      debugPrint('[MapScreen] Location permission before request: $permission');

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        debugPrint(
          '[MapScreen] Location permission after request: $permission',
        );
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        debugPrint('[MapScreen] Location permission denied');
        return null;
      }

      debugPrint('[MapScreen] Getting current position...');

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      debugPrint('[MapScreen] CURRENT POSITION:');
      debugPrint('[MapScreen] lat = ${position.latitude}');
      debugPrint('[MapScreen] lng = ${position.longitude}');
      debugPrint('[MapScreen] accuracy = ${position.accuracy}');
      debugPrint('[MapScreen] timestamp = ${position.timestamp}');

      final latLng = LatLng(position.latitude, position.longitude);

      if (latLng.latitude.isNaN || latLng.longitude.isNaN) {
        debugPrint('[MapScreen] Invalid coordinates');
        return null;
      }

      return latLng;
    } catch (e) {
      debugPrint('[MapScreen] Failed to get current location: $e');
      return null;
    }
  }

  LatLng get _initialCenter {
    if (currentLocation != null) return currentLocation!;

    if (shopMarkers.isNotEmpty) {
      return LatLng(shopMarkers.first.lat!, shopMarkers.first.lng!);
    }

    return _defaultCenter;
  }

  List<Marker> _buildMarkers() {
    final showExpandedMarker = _currentZoom >= _expandedMarkerZoom;

    final markers = <Marker>[
      for (final shop in shopMarkers)
        Marker(
          point: LatLng(shop.lat!, shop.lng!),
          width: showExpandedMarker ? 170 : 44,
          height: showExpandedMarker ? 290 : 44,
          child: GestureDetector(
            onTap: () => _showShopDetails(shop),
            child: showExpandedMarker
                ? _ShopMapMarkerCard(
                    shop: shop,
                    distanceLabel: _buildDistanceLabel(shop),
                    onDirectionsTap: () => _openDirections(shop),
                  )
                : const _ShopMapMarkerPin(),
          ),
        ),
    ];

    if (currentLocation != null) {
      markers.add(
        Marker(
          point: currentLocation!,
          width: 56,
          height: 56,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 10,
                ),
              ],
            ),
            child: const Icon(
              LucideIcons.mapPin,
              color: Colors.white,
              size: 18,
            ),
          ),
        ),
      );
    }

    return markers;
  }

  String? _buildDistanceLabel(ShopMarkerDTO shop) {
    if (currentLocation == null) return null;

    final shopPoint = LatLng(shop.lat!, shop.lng!);
    final distanceKm = const Distance().as(
      LengthUnit.Kilometer,
      currentLocation!,
      shopPoint,
    );

    if (distanceKm < 1) {
      final meters = (distanceKm * 1000).round();
      return '$meters m';
    }

    return '${distanceKm.toStringAsFixed(distanceKm >= 10 ? 0 : 1)} km';
  }

  Future<void> _openDirections(ShopMarkerDTO shop) async {
    final lat = shop.lat;
    final lng = shop.lng;
    if (lat == null || lng == null) return;

    final appUri = Uri.parse('google.navigation:q=$lat,$lng');
    final webUri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
    );

    try {
      final launchedApp = await openExternalUrl(appUri);
      if (launchedApp) return;
    } catch (e) {
      debugPrint('[MapScreen] Failed to open Google Maps app: $e');
    }

    final launchedWeb = await openExternalUrl(webUri);

    if (launchedWeb || !mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Không mở được Google Maps.')));
  }

  void _showShopDetails(ShopMarkerDTO shop) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if ((shop.imageUrl ?? '').isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Image.network(
                        shop.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            _buildImageFallback(),
                      ),
                    ),
                  )
                else
                  _buildImageFallback(),
                const SizedBox(height: 16),
                Text(
                  shop.name ?? 'Cửa hàng',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF111827),
                  ),
                ),
                if (shop.rating != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _RatingStars(rating: shop.rating!),
                      const SizedBox(width: 8),
                      Text(
                        shop.rating!.toStringAsFixed(1),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(
                        LucideIcons.mapPin,
                        size: 16,
                        color: Color(0xFFFF5A4E),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        shop.address ?? 'Chưa có địa chỉ',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          height: 1.45,
                          color: const Color(0xFF4B5563),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _openDirections(shop),
                    icon: const Icon(LucideIcons.navigation),
                    label: Text(
                      'Chỉ đường',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildImageFallback() {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1EE),
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.center,
      child: const Icon(
        LucideIcons.imageOff,
        color: Color(0xFFFF5A4E),
        size: 32,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showMap = !isLoading && errorMessage == null;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(LucideIcons.chevronLeft, color: Color(0xFF1F2937)),
        ),
        title: Text(
          'Bản đồ vị trí',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1F2937),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: Stack(
        children: [
          if (showMap)
            FlutterMap(
              mapController: mapController,
              options: MapOptions(
                initialCenter: _initialCenter,
                initialZoom: 15,
                minZoom: 1,
                maxZoom: 19,
                onPositionChanged: (position, hasGesture) {
                  final zoom = position.zoom;
                  if ((zoom - _currentZoom).abs() < 0.05) {
                    return;
                  }

                  setState(() {
                    _currentZoom = zoom;
                  });
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.petpee.mobile',
                  maxZoom: 18,
                ),
                MarkerLayer(markers: _buildMarkers()),
              ],
            )
          else if (isLoading)
            const Center(child: CircularProgressIndicator())
          else
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      LucideIcons.alertCircle,
                      color: Color(0xFFFF5A4E),
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      errorMessage ?? 'Có lỗi xảy ra khi tải bản đồ.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _loadMapData,
                      icon: const Icon(LucideIcons.rotateCw),
                      label: Text(
                        'Thử lại',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF5A4E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (showMap)
            Positioned(
              bottom: 24,
              right: 16,
              child: FloatingActionButton(
                onPressed: _loadMapData,
                backgroundColor: const Color(0xFFFF5A4E),
                child: const Icon(LucideIcons.rotateCw, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}

class _ShopMapMarkerCard extends StatelessWidget {
  const _ShopMapMarkerCard({
    required this.shop,
    required this.distanceLabel,
    required this.onDirectionsTap,
  });

  final ShopMarkerDTO shop;
  final String? distanceLabel;
  final VoidCallback onDirectionsTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 156,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1F2937).withValues(alpha: 0.14),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  _ShopMapMarkerImage(imageUrl: shop.imageUrl),
                  if (distanceLabel != null)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF8A1F),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              LucideIcons.mapPin,
                              size: 12,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              distanceLabel!,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shop.name ?? 'Cửa hàng',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        height: 1.15,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                    if (shop.rating != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _RatingStars(rating: shop.rating!),
                          const SizedBox(width: 6),
                          Text(
                            shop.rating!.toStringAsFixed(1),
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(
                          LucideIcons.mapPin,
                          size: 13,
                          color: Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            shop.address ?? 'Chưa có địa chỉ',
                            softWrap: true,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              height: 1.3,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: onDirectionsTap,
                        icon: const Icon(LucideIcons.navigation, size: 14),
                        label: Text(
                          'Chỉ đường',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF2563EB),
                          side: const BorderSide(color: Color(0xFFBFDBFE)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ShopMapMarkerPin extends StatelessWidget {
  const _ShopMapMarkerPin();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: Color(0xFFFF8A1F),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.store, size: 13, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _ShopMapMarkerImage extends StatelessWidget {
  const _ShopMapMarkerImage({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final hasImage = (imageUrl ?? '').isNotEmpty;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      child: Container(
        width: 156,
        height: 104,
        color: const Color(0xFFFFF1EE),
        child: hasImage
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const _ShopMapMarkerImageFallback(),
              )
            : const _ShopMapMarkerImageFallback(),
      ),
    );
  }
}

class _RatingStars extends StatelessWidget {
  const _RatingStars({required this.rating});

  final double rating;

  @override
  Widget build(BuildContext context) {
    final normalizedRating = rating.clamp(0, 5).toDouble();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final fill = (normalizedRating - index).clamp(0, 1).toDouble();

        return Padding(
          padding: EdgeInsets.only(right: index == 4 ? 0 : 1),
          child: _StarFill(fill: fill),
        );
      }),
    );
  }
}

class _StarFill extends StatelessWidget {
  const _StarFill({required this.fill});

  final double fill;

  @override
  Widget build(BuildContext context) {
    const size = 12.0;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          const Icon(Icons.star_rounded, size: size, color: Color(0xFFE2E8F0)),
          if (fill > 0)
            ClipRect(
              child: Align(
                alignment: Alignment.centerLeft,
                widthFactor: fill,
                child: const Icon(
                  Icons.star_rounded,
                  size: size,
                  color: Color(0xFFFFB020),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ShopMapMarkerImageFallback extends StatelessWidget {
  const _ShopMapMarkerImageFallback();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(LucideIcons.store, size: 28, color: Color(0xFFFF5A4E)),
    );
  }
}
