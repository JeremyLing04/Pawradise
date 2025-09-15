//screens/map/map_screen.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:pawradise/constants.dart';
import '../../models/location_model.dart';
import 'package:permission_handler/permission_handler.dart' as permission_handler;
import '../../models/places_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'share_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController mapController;
  final Location _location = Location();
  LatLng _initialPosition = const LatLng(3.1390, 101.6869); // Kuala Lumpur
  List<LocationModel> nearbyLocations = [];
  bool _isListExpanded = true;
  BitmapDescriptor? customMarker;

  @override
  void initState() {
    super.initState();
    _loadMarker();
    requestLocationPermission();
  }

  Future<void> _loadMarker() async {
    customMarker = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
    setState(() {});
  }

  void requestLocationPermission() async {
    permission_handler.PermissionStatus status = await permission_handler.Permission.location.request();

    if (status.isGranted) {
      _setCurrentLocation();
    } else if (status.isDenied) {
      _showSnackBar('Location permission denied. Please grant it.');
    } else if (status.isPermanentlyDenied) {
      _showAlertDialog();
    }
  }

  void _setCurrentLocation() async {
    try {
      final userLocation = await _location.getLocation();
      setState(() {
        _initialPosition = LatLng(userLocation.latitude!, userLocation.longitude!);
      });
      mapController.animateCamera(CameraUpdate.newLatLngZoom(_initialPosition, 14));
      final places = await PlacesService.fetchPetFriendlyPlaces(
        userLocation.latitude!, userLocation.longitude!,
      );
      setState(() {
        nearbyLocations = places.map<LocationModel>((place) {
          return LocationModel(
            id: place['place_id'],
            name: place['name'],
            description: place['vicinity'],
            latitude: place['geometry']['location']['lat'],
            longitude: place['geometry']['location']['lng'],
            rating: place['rating']?.toDouble() ?? 0.0,
            category: place['types'][0] ?? 'Unknown',
          );
        }).toList();
      });
    } catch (e) {
      print("Error getting location: $e");
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: Duration(seconds: 3)),
    );
  }

  void _showAlertDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Location Permission Denied'),
        content: Text('Please enable location permissions in app settings.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('Cancel')),
          TextButton(onPressed: () => permission_handler.openAppSettings(), child: Text('Go to Settings')),
        ],
      ),
    );
  }

  Set<Marker> _getMarkers() {
    return nearbyLocations.map((location) {
      return Marker(
        markerId: MarkerId(location.id),
        position: LatLng(location.latitude, location.longitude),
        infoWindow: InfoWindow(
          title: location.name,
          snippet: "${location.rating} ⭐ - ${location.category}",
        ),
        icon: customMarker ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      );
    }).toSet();
  }

  Widget _buildNearbyLocationList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      itemCount: nearbyLocations.length,
      itemBuilder: (context, index) {
        final location = nearbyLocations[index];
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          decoration: BoxDecoration(
            color: AppColors.secondary.withOpacity(0.8), 
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.accent, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 6,
                offset: Offset(2, 3),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: Icon(Icons.pets, size: 40, color: AppColors.accent),
            title: Text(location.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            subtitle: Text('${location.category} - ${location.rating} ⭐', style: TextStyle(fontSize: 14)),
            onTap: () => _moveCameraToLocation(location),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.info_outline, color: AppColors.accent),
                  onPressed: () => _showPlaceDetails(location),
                ),
                IconButton(
                  icon: Icon(Icons.directions, color: AppColors.accent),
                  onPressed: () => _showDirections(location),
                ),
                IconButton(
                  icon: Icon(Icons.share, color: AppColors.accent),
                  onPressed: () => _shareLocation(location),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _moveCameraToLocation(LocationModel location) {
    mapController.animateCamera(CameraUpdate.newLatLngZoom(LatLng(location.latitude, location.longitude), 20));
  }

  void _showPlaceDetails(LocationModel location) async {
    final googleMapsUrl = 'https://www.google.com/maps/?q=${location.name}';
    if (await canLaunch(googleMapsUrl)) {
      await launch(googleMapsUrl);
    } else {
      throw 'Could not launch $googleMapsUrl';
    }
  }

  void _showDirections(LocationModel location) async {
    final url = 'https://www.google.com/maps/dir/?api=1&destination=${location.latitude},${location.longitude}';
    if (await canLaunch(url)) await launch(url); else throw 'Could not launch $url';
  }

  void _shareLocation(LocationModel location) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => ShareScreen(location: location)));
  }

  void _toggleListExpansion() {
    setState(() => _isListExpanded = !_isListExpanded);
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: AppColors.accent.withOpacity(0.5), 
    appBar: AppBar(
      title: Text(
        'Dog-Friendly Map',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 22,
          color: AppColors.background, 
        ),
      ),
      centerTitle: true, 
      backgroundColor: AppColors.primary, 
      elevation: 4,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
    ),
    body: Column(
      children: [
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: Offset(0, 4))],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: GoogleMap(
                onMapCreated: (controller) => mapController = controller,
                initialCameraPosition: CameraPosition(target: _initialPosition, zoom: 14),
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                markers: _getMarkers(),
              ),
            ),
          ),
        ),
        IconButton(
          icon: Icon(
            _isListExpanded ? Icons.expand_more : Icons.expand_less,
            color: AppColors.accent,
            size: 30,
          ),
          onPressed: _toggleListExpansion,
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: _isListExpanded ? 400 : 0,
          child: _buildNearbyLocationList(),
        ),
      ],
    ),
  );
}
}
