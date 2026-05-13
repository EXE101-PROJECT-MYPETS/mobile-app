import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons/lucide_icons.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late MapController mapController;
  LatLng? currentLocation;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    mapController = MapController();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    mapController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      debugPrint('[MapScreen] Getting current location...');
      
      setState(() {
        isLoading = true;
        error = null;
      });

      // Check location service enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      debugPrint('[MapScreen] GPS service enabled: $serviceEnabled');
      
      if (!serviceEnabled) {
        debugPrint('[MapScreen] ERROR: Location service is disabled');
        setState(() {
          error = 'Vui lòng bật dịch vụ vị trí';
          isLoading = false;
        });
        return;
      }

      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      debugPrint('[MapScreen] Location permission before request: $permission');
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        debugPrint('[MapScreen] Location permission after request: $permission');
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        debugPrint('[MapScreen] ERROR: Location permission denied or denied forever');
        setState(() {
          error = 'Vui lòng cấp quyền truy cập vị trí';
          isLoading = false;
        });
        return;
      }

      debugPrint('[MapScreen] Getting current position...');
      
      // Get current position
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

      if (mounted) {
        setState(() {
          currentLocation = latLng;
          isLoading = false;
        });
        
        debugPrint('[MapScreen] Map location updated: ${latLng.latitude}, ${latLng.longitude}');
      }
    } catch (e) {
      debugPrint('[MapScreen] ERROR: $e');
      debugPrint('[MapScreen] Exception type: ${e.runtimeType}');
      
      if (mounted) {
        setState(() {
          error = 'Lỗi lấy vị trí: $e';
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            alignment: Alignment.center,
            child: const Icon(
              LucideIcons.chevronLeft,
              color: Color(0xFF1F2937),
            ),
          ),
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
          if (currentLocation != null)
            FlutterMap(
              mapController: mapController,
              options: MapOptions(
                initialCenter: currentLocation ?? const LatLng(20.9925, 105.7847),
                initialZoom: 15.0,
                minZoom: 1,
                maxZoom: 19,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.petpee.mobile',
                  maxZoom: 18,
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: currentLocation!,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF5A4E),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(12),
                        child: const Icon(
                          LucideIcons.mapPin,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            )
          else if (isLoading)
            const Center(
              child: CircularProgressIndicator(),
            )
          else if (error != null)
            Center(
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
                    error!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _getCurrentLocation,
                    icon: const Icon(LucideIcons.rotateCw),
                    label: Text(
                      'Thử lại',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                      ),
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
          // Floating button to refresh location
          if (currentLocation != null)
            Positioned(
              bottom: 24,
              right: 16,
              child: FloatingActionButton(
                onPressed: _getCurrentLocation,
                backgroundColor: const Color(0xFFFF5A4E),
                child: const Icon(
                  LucideIcons.mapPin,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
