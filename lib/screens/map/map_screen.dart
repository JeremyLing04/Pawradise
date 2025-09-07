import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import '../../models/location_model.dart';
import 'package:permission_handler/permission_handler.dart'
    as permission_handler;
import 'package:permission_handler/permission_handler.dart';
import '../../models/places_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController mapController;
  final Location _location = Location();

  LatLng _initialPosition = const LatLng(
    3.1390,
    101.6869,
  ); // Default: Kuala Lumpur
  List<LocationModel> nearbyLocations = [];
  bool _isListExpanded = false; // Flag to track list expansion

  @override
  void initState() {
    super.initState();
    requestLocationPermission(); // Request location permission when app starts
  }

  // Request location permission at runtime
  void requestLocationPermission() async {
    permission_handler.PermissionStatus status = await permission_handler
        .Permission
        .location
        .request();

    if (status.isGranted) {
      _setCurrentLocation(); // Permissions granted, now fetch current location
    } else if (status.isDenied) {
      print('Location permission denied');
    } else if (status.isPermanentlyDenied) {
      openAppSettings(); // Open app settings for the user to manually allow permission
    }
  }

  // Fetch the current location of the user
  void _setCurrentLocation() async {
    try {
      final userLocation = await _location.getLocation();
      setState(() {
        _initialPosition = LatLng(
          userLocation.latitude!,
          userLocation.longitude!,
        ); // Update initial position
      });

      // Move the camera to the user's current location
      mapController.animateCamera(
        CameraUpdate.newLatLngZoom(_initialPosition, 14),
      );

      // Fetch pet-friendly places from Google Places API
      final places = await PlacesService.fetchPetFriendlyPlaces(
        userLocation.latitude!,
        userLocation.longitude!,
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

  // Create markers for each nearby location
  Set<Marker> _getMarkers() {
    return nearbyLocations.map((location) {
      return Marker(
        markerId: MarkerId(location.id),
        position: LatLng(location.latitude, location.longitude),
        infoWindow: InfoWindow(
          title: location.name,
          snippet: "${location.rating} ⭐ - ${location.category}",
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      );
    }).toSet();
  }

  // Widget to display the list of nearby locations
  Widget _buildNearbyLocationList() {
    return ListView.builder(
      itemCount: nearbyLocations.length,
      itemBuilder: (context, index) {
        final location = nearbyLocations[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ), // Rounded corners for cards
          elevation: 5, // Adding shadow for better visibility
          child: ListTile(
            contentPadding: const EdgeInsets.all(
              12.0,
            ), // Padding inside each card
            leading: Icon(
              Icons.pets,
              color: const Color.fromARGB(255, 231, 75, 148),
              size: 40,
            ), // Add pet-friendly icon
            title: Text(
              location.name,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            subtitle: Text(
              '${location.category} - ${location.rating} ⭐',
              style: TextStyle(fontSize: 14),
            ),
            onTap: () {
              // When a list item is tapped, move the map's camera to the location
              _moveCameraToLocation(location);
            },
          ),
        );
      },
    );
  }

  // Move camera to the selected location when a list item is tapped
  void _moveCameraToLocation(LocationModel location) {
    mapController.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(location.latitude, location.longitude),
        15,
      ),
    );
  }

  // Toggle the expansion state of the list
  void _toggleListExpansion() {
    setState(() {
      _isListExpanded = !_isListExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dog-Friendly Map'),
        backgroundColor: Color(0xFFB98C6D), // Light brown color for app bar
      ),
      body: Column(
        children: [
          // Google Map
          Expanded(
            child: GoogleMap(
              onMapCreated: (controller) => mapController = controller,
              initialCameraPosition: CameraPosition(
                target: _initialPosition,
                zoom: 14,
              ),
              myLocationEnabled: true, // Show the user's location as a blue dot
              myLocationButtonEnabled: true, // Show the "My Location" button
              markers: _getMarkers(), // Show only nearby places as markers
            ),
          ),
          // IconButton to expand/collapse the list with an arrow
          IconButton(
            icon: Icon(
              _isListExpanded
                  ? Icons.expand_more
                  : Icons.expand_less, // Reversed behavior
              color: Color.fromARGB(
                255,
                78,
                53,
                36,
              ), // Light brown color for the arrow
            ),
            onPressed: _toggleListExpansion,
          ),
          // Collapsing/Expanding List of nearby pet-friendly places
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _isListExpanded
                ? 500
                : 0, // Increase the height to make the list bigger
            child: _buildNearbyLocationList(),
          ),
        ],
      ),
    );
  }
}
