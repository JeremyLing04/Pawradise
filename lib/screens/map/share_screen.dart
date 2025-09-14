import 'package:flutter/material.dart';
import '../../models/location_model.dart'; 
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ShareScreen extends StatelessWidget {
  final LocationModel location; // Receive location data via constructor

  const ShareScreen({Key? key, required this.location}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Set the initial camera position to the location's coordinates
    final CameraPosition initialCameraPosition = CameraPosition(
      target: LatLng(location.latitude, location.longitude),
      zoom: 15, // Zoom level
    );

    // Create a marker for the location
    final Marker locationMarker = Marker(
      markerId: MarkerId(location.id),
      position: LatLng(location.latitude, location.longitude),
      infoWindow: InfoWindow(
        title: location.name,
        snippet: "${location.rating} ⭐ - ${location.category}",
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Location Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display the location details
            Text(
              'ID: ${location.id}',
              style: TextStyle(fontSize: 16),
            ),
            Text(
              'Name: ${location.name}',
              style: TextStyle(fontSize: 16),
            ),
            Text(
              'Description: ${location.description}',
              style: TextStyle(fontSize: 16),
            ),
            Text(
              'Latitude: ${location.latitude}',
              style: TextStyle(fontSize: 16),
            ),
            Text(
              'Longitude: ${location.longitude}',
              style: TextStyle(fontSize: 16),
            ),
            Text(
              'Rating: ${location.rating} ⭐',
              style: TextStyle(fontSize: 16),
            ),
            Text(
              'Category: ${location.category}',
              style: TextStyle(fontSize: 16),
            ),

            // Spacer for better layout
            SizedBox(height: 20),

            // Add the Google Map widget
            Container(
              height: 300, // Set the height for the map
              child: GoogleMap(
                initialCameraPosition: initialCameraPosition, // Set initial position
                markers: {locationMarker}, // Add the marker to the map
                mapType: MapType.normal, // Set the map type (normal or satellite)
              ),
            ),
          ],
        ),
      ),
    );
  }
}