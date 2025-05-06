import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:impact_app/screens/documentasi_screen.dart';
import 'package:impact_app/api/api_services.dart';
import 'package:impact_app/models/store_model.dart';
import 'package:impact_app/utils/location_utils.dart';
import 'package:impact_app/themes/app_colors.dart';

class CheckinMapScreen extends StatefulWidget {
  const CheckinMapScreen({super.key});

  @override
  State<CheckinMapScreen> createState() => _CheckinMapScreenState();
}

class _CheckinMapScreenState extends State<CheckinMapScreen> {
  GoogleMapController? _mapController;
  Position? _currentPosition;
  double _accuracy = 0;
  final Set<Marker> _markers = {};
  List<Store> _nearbyStores = [];
  bool _isLoading = true;
  
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);
    
    Position? position = await LocationUtils.getCurrentLocation();
    
    if (position != null) {
      setState(() {
        _currentPosition = position;
        _accuracy = position.accuracy;
      });
      
      // Move camera to current position
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(
        LatLng(position.latitude, position.longitude),
        16,
      ));
      
      // Fetch nearby stores
      await _fetchNearbyStores();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak dapat mengakses lokasi Anda')),
      );
    }
    
    setState(() => _isLoading = false);
  }
  
  Future<void> _fetchNearbyStores() async {
    if (_currentPosition == null) return;
    
    try {
      final stores = await _apiService.getStores();
      
      // Calculate distance for each store
      _nearbyStores = stores.map((store) {
        if (store.latitude != null && store.longitude != null) {
          double distance = LocationUtils.calculateDistance(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            store.latitude!,
            store.longitude!,
          );
          
          return Store(
            id: store.id,
            code: store.code,
            name: store.name,
            address: store.address,
            description: store.description,
            distributor: store.distributor,
            segment: store.segment,
            province: store.province,
            area: store.area,
            district: store.district,
            subDistrict: store.subDistrict,
            account: store.account,
            type: store.type,
            image: store.image,
            latitude: store.latitude,
            longitude: store.longitude,
            distance: distance.toInt(),
          );
        }
        return store;
      }).toList();
      
      // Sort stores by distance
      _nearbyStores.sort((a, b) => (a.distance ?? 9999).compareTo(b.distance ?? 9999));
      
      _setMarkers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengambil data toko: $e')),
      );
    }
  }

  void _setMarkers() {
    _markers.clear();
    
    // Add marker for current position
    if (_currentPosition != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('current_position'),
          position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          infoWindow: const InfoWindow(title: 'Posisi Anda'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ),
      );
    }
    
    // Add markers for stores
    for (var store in _nearbyStores) {
      if (store.latitude != null && store.longitude != null) {
        final int distance = store.distance ?? 999;
        final markerColor = distance <= 100 ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed;

        _markers.add(
          Marker(
            markerId: MarkerId(store.id ?? ''),
            position: LatLng(store.latitude!, store.longitude!),
            infoWindow: InfoWindow(title: store.name),
            icon: BitmapDescriptor.defaultMarkerWithHue(markerColor),
            onTap: () => _showStoreDialog(context, store),
          ),
        );
      }
    }

    setState(() {});
  }

  void _showStoreDialog(BuildContext context, Store store) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.store, color: AppColors.primary),
            const SizedBox(height: 8),
            Text(store.name ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(store.type ?? ''),
            Text(store.address ?? ''),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Edit store"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              
              // Navigate to documentation screen with store data
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (BuildContext context) => DocumentasiScreen(store: store),
                ),
              );
            },
            child: const Text("Check in"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Check in"),
        backgroundColor: AppColors.secondary,
      ),
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : GoogleMap(
                  initialCameraPosition: _currentPosition != null
                      ? CameraPosition(
                          target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                          zoom: 16,
                        )
                      : const CameraPosition(
                          target: LatLng(-6.2088, 106.8456), // Default to Jakarta
                          zoom: 10,
                        ),
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                  markers: _markers,
                ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Akurasi: ${_accuracy.toStringAsFixed(2)} m (MINIMUM: 100 m)"),
                  const SizedBox(height: 12),
                  // List of nearby stores
                  ..._nearbyStores.take(3).map((store) {
                    final bool isInRange = (store.distance ?? 999) <= 100;
                    return Card(
                      color: isInRange ? AppColors.success : AppColors.error,
                      child: ListTile(
                        leading: const Icon(Icons.store, color: Colors.white),
                        title: Text(
                          store.name ?? '',
                          style: const TextStyle(color: Colors.white),
                        ),
                        trailing: Text(
                          "${store.distance} m",
                          style: const TextStyle(color: Colors.white),
                        ),
                        onTap: () => _showStoreDialog(context, store),
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(context, '/addstore');
                        },
                        icon: const Icon(Icons.add),
                        label: const Text("Add Store"),
                      ),
                      ElevatedButton.icon(
                        onPressed: _getCurrentLocation,
                        icon: const Icon(Icons.refresh),
                        label: const Text("Refresh"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}