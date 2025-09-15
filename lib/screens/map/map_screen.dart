//screens/map/map_screen.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:pawradise/screens/community/create_post_screen.dart';
import '../../models/location_model.dart';
import 'package:permission_handler/permission_handler.dart'as permission_handler;
import 'package:permission_handler/permission_handler.dart';
import '../../models/places_service.dart';
import 'package:url_launcher/url_launcher.dart';

// REMEMBER DELETE THIS AFTER MODIFY THE SHARE FUNCTION
import 'share_screen.dart';






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
  bool _isListExpanded = true; // Flag to track list expansion
  BitmapDescriptor? customMarker; // Custom marker

  @override
  void initState() {
    super.initState();
    _loadMarker(); // Load the custom marker color
    requestLocationPermission(); // Request location permission when app starts
  }

  // Load the custom marker color directly without using then
  Future<void> _loadMarker() async {
    customMarker = BitmapDescriptor.defaultMarkerWithHue(
      BitmapDescriptor.hueAzure,
    );
    setState(() {
      // Marker is now ready
    });
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
      // Show SnackBar if permission is denied
      _showSnackBar(
        'Location permission denied. Please grant it to use this feature.',
      );
    } else if (status.isPermanentlyDenied) {
      // Show AlertDialog if permission is permanently denied
      _showAlertDialog();
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
      print(places); // Debug print to check the fetched data
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

  // Show SnackBar with a message
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: Duration(seconds: 3)),
    );
  }

  // Show an AlertDialog when permission is permanently denied
  void _showAlertDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Location Permission Denied'),
          content: Text(
            'Please enable location permissions in the app settings.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                openAppSettings(); // Open app settings to allow permission
              },
              child: Text('Go to Settings'),
            ),
          ],
        );
      },
    );
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
        icon:
            customMarker ??
            BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueAzure,
            ), // Use custom marker or default
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
          ),
          elevation: 5, // Adding shadow for better visibility
          color: Color.fromRGBO(236, 185, 44, 1),
          child: ListTile(
            contentPadding: const EdgeInsets.all(
              12.0,
            ), // Padding inside each card
            leading: Icon(
              Icons.pets,
              color: const Color.fromARGB(255, 97, 72, 3),
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
            trailing: Row(
              mainAxisSize:
                  MainAxisSize.min, // Ensure buttons stay next to each other
              children: [
                // Preview Button (Modified to open Google Maps place details)
                IconButton(
                  icon: Icon(Icons.info_outline),
                  onPressed: () {
                    _showPlaceDetails(
                      location,
                    ); // Open Google Maps place details
                  },
                ),
                // Directions Button
                IconButton(
                  icon: Icon(Icons.directions),
                  onPressed: () {
                    _showDirections(location); // Call the directions function
                  },
                ),
                // Share Button
                IconButton(
                  icon: Icon(Icons.share),
                  onPressed: () {
                    _shareLocation(location); // Call the share function
                  },
                ),
              ],
            ),
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
        20,
      ),
    );
  }

  // Show the Google Maps place details page when Preview button is clicked
  void _showPlaceDetails(LocationModel location) async {
    // Correct URL format for opening Google Maps with place_id
    final googleMapsUrl = 'https://www.google.com/maps/?q=${location.name}';
    ;

    // Check if the URL can be launched
    if (await canLaunch(googleMapsUrl)) {
      // Open the URL to the Google Maps place details page
      await launch(googleMapsUrl);
    } else {
      // Handle the case where the URL cannot be launched
      throw 'Could not launch $googleMapsUrl';
    }
  }

  void _showDirections(LocationModel location) async {
    final url =
        'https://www.google.com/maps/dir/?api=1&destination=${location.latitude},${location.longitude}';

    // Check if the URL can be launched
    if (await canLaunch(url)) {
      // Launch the URL to open Google Maps with directions
      await launch(url);
    } else {
      // Handle the case where the URL cannot be launched
      throw 'Could not launch $url';
    }
  }

  // 修改分享功能，导航到 CreatePostScreen 并传递位置数据
  void _shareLocation(LocationModel location) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreatePostScreen(sharedLocation: location),
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
        backgroundColor: Color.fromARGB(255, 243, 199, 79),
      ),
      body: Column(
        children: [
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
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _isListExpanded
                ? 400 // The height when expanded
                : 0, // The height when collapsed
            child: _buildNearbyLocationList(),
          ),
        ],
      ),
    );
  }
}
