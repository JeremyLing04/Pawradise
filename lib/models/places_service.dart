// //models/places_services.dart
// import 'dart:convert';
// import 'package:http/http.dart' as http;

// class PlacesService {
//   static const String apiKey = "AIzaSyCfOOzVBxw-p_v69VjTeFrg7nVp3OJPaG8";
//   static const String baseUrl = "https://maps.googleapis.com/maps/api/place/nearbysearch/json";

//   // Fetch pet-friendly places near the user's current location
//   static Future<List<dynamic>> fetchPetFriendlyPlaces(double latitude, double longitude) async {
//     final url =
//         "$baseUrl?location=$latitude,$longitude&radius=5000&type=point_of_interest&keyword=pet+friendly&key=$apiKey";

//     final response = await http.get(Uri.parse(url));

//     if (response.statusCode == 200) {
//       final data = json.decode(response.body);
//       return data['results']; // Returning list of results
//     } else {
//       throw Exception('Failed to load pet-friendly places');
//     }
//   }
// }
