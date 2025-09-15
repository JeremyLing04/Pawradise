// services/places_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class PlacesService {
  static const String _apiKey = "AIzaSyCfOOzVBxw-p_v69VjTeFrg7nVp3OJPaG8"; // 确保这是正确的API密钥
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/place';

  // 搜索地点 - 使用文本搜索
  static Future<List<Map<String, dynamic>>> searchPlaces(String query) async {
    if (query.isEmpty) return [];

    // 对查询进行URL编码
    final encodedQuery = Uri.encodeComponent(query);
    final url = '$_baseUrl/textsearch/json?query=$encodedQuery&key=$_apiKey';
    
    print('Search URL: $url'); // 调试用

    try {
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Search response: $data'); // 调试用
        
        if (data['status'] == 'OK') {
          return List<Map<String, dynamic>>.from(data['results']);
        } else {
          print('Places API error: ${data['status']} - ${data['error_message']}');
          return [];
        }
      }
      return [];
    } catch (e) {
      print('Search places error: $e');
      return [];
    }
  }

  // 获取地点详情
  static Future<Map<String, dynamic>?> getPlaceDetails(String placeId) async {
    final url = '$_baseUrl/details/json?place_id=$placeId&key=$_apiKey';
    
    print('Details URL: $url'); // 调试用

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Details response: $data'); // 调试用
        
        if (data['status'] == 'OK') {
          return Map<String, dynamic>.from(data['result']);
        } else {
          print('Details API error: ${data['status']}');
          return null;
        }
      }
      return null;
    } catch (e) {
      print('Get place details error: $e');
      return null;
    }
  }

  // 自动完成搜索 - 使用自动完成API
  static Future<List<Map<String, dynamic>>> autocomplete(String query) async {
    if (query.isEmpty) return [];

    final encodedQuery = Uri.encodeComponent(query);
    final url = '$_baseUrl/autocomplete/json?input=$encodedQuery&key=$_apiKey&types=establishment';
    
    print('Autocomplete URL: $url'); // 调试用

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Autocomplete response: $data'); // 调试用
        
        if (data['status'] == 'OK') {
          return List<Map<String, dynamic>>.from(data['predictions']);
        } else {
          print('Autocomplete API error: ${data['status']}');
          return [];
        }
      }
      return [];
    } catch (e) {
      print('Autocomplete error: $e');
      return [];
    }
  }
}