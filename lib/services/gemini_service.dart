// // services/gemini_service.dart
// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:flutter_dotenv/flutter_dotenv.dart';
// import '../models/chat_message_model.dart';
// import '../models/pet_model.dart';

// class GeminiService {
//   static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta';
//   final String? _apiKey;

//   GeminiService() : _apiKey = dotenv.env['GEMINI_API_KEY'];

//   // 添加缺失的 getAIResponse 方法
//   Future<String> getAIResponse(String userMessage, List<Pet> userPets) async {
//     if (_apiKey == null) {
//       throw Exception('Gemini API key not found. Please check your .env file');
//     }

//     // 构建宠物信息上下文
//     String petsContext = _buildPetsContext(userPets);
    
//     // 构建完整的提示词
//     String fullPrompt = '''
// $petsContext

// 用户问题: $userMessage

// 请以专业、友好的宠物顾问身份回答，提供有帮助的建议。
// ''';

//     final Uri uri = Uri.parse('$_baseUrl/models/gemini-pro:generateContent?key=$_apiKey');
    
//     final Map<String, dynamic> requestBody = {
//       'contents': [
//         {
//           'role': 'user',
//           'parts': [{'text': fullPrompt}]
//         }
//       ],
//       'generationConfig': {
//         'temperature': 0.7,
//         'topK': 40,
//         'topP': 0.95,
//         'maxOutputTokens': 1024,
//       },
//       'safetySettings': [
//         {
//           'category': 'HARM_CATEGORY_HARASSMENT',
//           'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
//         },
//         {
//           'category': 'HARM_CATEGORY_HATE_SPEECH', 
//           'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
//         }
//       ]
//     };

//     try {
//       final response = await http.post(
//         uri,
//         headers: {
//           'Content-Type': 'application/json',
//         },
//         body: json.encode(requestBody),
//       );

//       if (response.statusCode == 200) {
//         final Map<String, dynamic> responseData = json.decode(response.body);
        
//         // 解析响应
//         final candidates = responseData['candidates'];
//         if (candidates != null && candidates.isNotEmpty) {
//           final content = candidates[0]['content'];
//           if (content != null) {
//             final parts = content['parts'];
//             if (parts != null && parts.isNotEmpty) {
//               return parts[0]['text'] ?? 'I received an empty response.';
//             }
//           }
//         }
        
//         return 'Sorry, I couldn\'t process your request at the moment.';
//       } else {
//         throw Exception('API request failed with status: ${response.statusCode}. Response: ${response.body}');
//       }
//     } catch (e) {
//       throw Exception('Network error: $e');
//     }
//   }

//   // 构建宠物上下文信息
//   String _buildPetsContext(List<Pet> pets) {
//     if (pets.isEmpty) {
//       return '用户目前没有注册任何宠物。';
//     }

//     String context = '用户有以下宠物：\n';
    
//     for (var pet in pets) {
//       context += '''
// - 名字: ${pet.name}
//   品种: ${pet.breed}
//   年龄: ${pet.age} 岁
//   ${pet.notes != null ? '备注: ${pet.notes}\n' : ''}
// ''';
//     }
    
//     return context;
//   }

//   // 简单的发送消息方法（备用）
//   Future<String> sendMessage(String message) async {
//     if (_apiKey == null) {
//       throw Exception('Gemini API key not found');
//     }

//      final Uri uri = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=$_apiKey');
    
//     final Map<String, dynamic> requestBody = {
//       'contents': [
//         {
//           'role': 'user',
//           'parts': [{'text': message}]
//         }
//       ],
//       'generationConfig': {
//         'temperature': 0.7,
//         'maxOutputTokens': 1024,
//       }
//     };

//     try {
//       final response = await http.post(
//         uri,
//         headers: {'Content-Type': 'application/json'},
//         body: json.encode(requestBody),
//       );

//       if (response.statusCode == 200) {
//         final Map<String, dynamic> responseData = json.decode(response.body);
//         return responseData['candidates']?[0]['content']?['parts']?[0]['text'] ?? 
//                'Sorry, I didn\'t get a valid response.';
//       } else {
//         throw Exception('API request failed: ${response.statusCode}');
//       }
//     } catch (e) {
//       throw Exception('Network error: $e');
//     }
//   }
// }