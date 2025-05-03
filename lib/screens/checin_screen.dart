import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:impact_app/screens/documentasi_screen.dart';

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

  final List<Map<String, dynamic>> stores = [
    {"name": "TK SRI BUANA", "lat": -6.4005, "lng": 106.9650, "distance": 100},
    {"name": "TK SRI BUANA", "lat": -6.4020, "lng": 106.9670, "distance": 250},
    {"name": "TK SRI BUANA", "lat": -6.4050, "lng": 106.9700, "distance": 175},
  ];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Layanan lokasi tidak aktif.')),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Izin lokasi dibutuhkan untuk fitur ini.')),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Izin lokasi ditolak permanen. Buka pengaturan aplikasi.')),
      );
      return;
    }

    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _currentPosition = position;
      _accuracy = position.accuracy;
    });

    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(
      LatLng(position.latitude, position.longitude),
      16,
    ));

    _setMarkers();
  }

  void _setMarkers() {
    _markers.clear();

    for (var store in stores) {

      final int distance = store['distance'];
      final markerColor = distance <= 100 ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed;

      _markers.add(
        Marker(
          markerId: MarkerId(store['name']),
          position: LatLng(store['lat'], store['lng']),
          infoWindow: InfoWindow(title: store['name']),
          icon: BitmapDescriptor.defaultMarkerWithHue(markerColor),
          onTap: () => _showStoreDialog(context, store['name']),
        ),
      );
    }

    setState(() {});
  }

  void _showStoreDialog(BuildContext context, String storeName) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.store, color: Colors.blue),
            SizedBox(height: 8),
            Text(storeName, style: TextStyle(fontWeight: FontWeight.bold)),
            Text("GT"),
            Text("Jl. Villa Makmur 2, Cileungsi, Jawa Barat - BOGOR"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Edit store"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (BuildContext context) => new DocumentasiScreen()));
            },
            child: Text("Check in"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Check in"),
        backgroundColor: Colors.grey[300],
      ),
      body: Stack(
        children: [
          _currentPosition == null
              ? Center(child: CircularProgressIndicator())
              : GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                    zoom: 16,
                  ),
                  myLocationEnabled: true,
                  onMapCreated: (controller) {
                    _mapController = controller;
                    _setMarkers();
                  },
                  markers: _markers,
                ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Accuration: ${_accuracy.toStringAsFixed(2)} m (MINIMUM: 100 m)"),
                  SizedBox(height: 12),
                  ...stores.map((store) {
                    return Card(
                      color: store["distance"] <= 100 ? Colors.green : Colors.redAccent,
                      child: ListTile(
                        leading: Icon(Icons.store),
                        title: Text(store["name"], style: TextStyle(color: Colors.white)),
                        trailing: Text("${store["distance"]} m", style: TextStyle(color: Colors.white)),
                        onTap: () => _showStoreDialog(context, store["name"]),
                      ),
                    );
                  }).toList(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(onPressed: () { Navigator.pushNamed(context, '/addstore'); }, child: Text("Add Store")),
                      ElevatedButton(onPressed: _getCurrentLocation, style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: Text("Reset")),
                      ElevatedButton(onPressed: _getCurrentLocation, child: Text("Refresh")),
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