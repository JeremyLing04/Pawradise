// services/ai_service.dart (Complete English version)
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/chat_message_model.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class AIService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _hasInitializedWelcomeMessage = false;

  // 狗品种识别功能
  static Future<String?> identifyDogBreed(File imageFile) async {
    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('Gemini API key not found');
      }

      final model = GenerativeModel(
        model: 'models/gemini-2.0-flash',
        apiKey: apiKey,
      );

      final prompt = '''
Analyze this dog image and identify the breed. 
Return ONLY the most likely breed name in English, nothing else.
If it's not a dog or unclear, return "Unknown".
Format: Just the breed name
Example: "Golden Retriever"
''';

      final imageBytes = await imageFile.readAsBytes();
      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', imageBytes),
        ])
      ];

      final response = await model.generateContent(content);
      final breed = response.text?.trim();
      
      // 清理响应，只返回品种名称
      if (breed != null && breed.isNotEmpty) {
        // 移除可能的引号或其他符号
        final cleanedBreed = breed
            .replaceAll('"', '')
            .replaceAll("'", '')
            .replaceAll('.', '')
            .trim();
        
        // 检查是否是有效的品种名称（不是错误消息）
        if (cleanedBreed.length > 2 && 
            !cleanedBreed.toLowerCase().contains('sorry') &&
            !cleanedBreed.toLowerCase().contains('error') &&
            !cleanedBreed.toLowerCase().contains('cannot')) {
          return cleanedBreed;
        }
      }
      
      return 'Unknown';
    } catch (e) {
      print('AI breed identification error: $e');
      return null;
    }
  }

  // 备选狗品种识别方法（使用文本API）
  static Future<String?> identifyDogBreedAlternative(File imageFile) async {
    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('Gemini API key not found');
      }

      // 将图像转换为base64
      final imageBytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(imageBytes);

      const String modelName = 'models/gemini-2.0-flash';
      const String apiUrl = 'https://generativelanguage.googleapis.com/v1/$modelName:generateContent';

      final headers = {
        'Content-Type': 'application/json',
      };

      final Map<String, dynamic> requestBody = {
        "contents": [
          {
            "parts": [
              {
                "text": '''Analyze this dog image and identify the breed. 
Return ONLY the most likely breed name in English, nothing else.
If it's not a dog or unclear, return "Unknown".
Format: Just the breed name
Example: "Golden Retriever"'''
              },
              {
                "inline_data": {
                  "mime_type": "image/jpeg",
                  "data": base64Image
                }
              }
            ]
          }
        ],
        "generationConfig": {
          "temperature": 0.1,
          "maxOutputTokens": 20,
          "topP": 0.8,
          "topK": 40
        }
      };

      final response = await http.post(
        Uri.parse('$apiUrl?key=$apiKey'),
        headers: headers,
        body: json.encode(requestBody),
      ).timeout(Duration(seconds: 30));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        if (responseData['candidates'] != null &&
            responseData['candidates'].isNotEmpty &&
            responseData['candidates'][0]['content'] != null &&
            responseData['candidates'][0]['content']['parts'] != null &&
            responseData['candidates'][0]['content']['parts'].isNotEmpty) {
          
          final String breed = responseData['candidates'][0]['content']['parts'][0]['text'].trim();
          return breed;
        }
      }
      
      return 'Unknown';
    } catch (e) {
      print('Alternative breed identification error: $e');
      return null;
    }
  }

  // 获取狗品种详细信息
  static Future<String> getBreedInformation(String breedName) async {
    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        return 'Breed information not available.';
      }

      final model = GenerativeModel(
        model: 'gemini-2.0-flash',
        apiKey: apiKey,
      );

      final prompt = '''
Provide brief information about $breedName dog breed in English.
Include:
- Key characteristics
- Typical temperament
- Exercise needs
- Grooming requirements
- Common health considerations

Keep it concise (under 100 words).
Format as bullet points.
''';

      final response = await model.generateContent([Content.text(prompt)]);
      return response.text ?? 'Information not available for $breedName.';
    } catch (e) {
      print('Breed information error: $e');
      return 'Could not retrieve breed information.';
    }
  }

  // 验证品种名称是否合理
  static bool isValidBreedName(String breedName) {
    if (breedName.isEmpty || breedName == 'Unknown') {
      return false;
    }

    // 常见无效响应
    final invalidResponses = [
      'sorry', 'error', 'cannot', 'unable', 'not sure', 
      'not a dog', 'not clear', 'unsure', 'maybe'
    ];

    final lowerBreed = breedName.toLowerCase();
    for (final invalid in invalidResponses) {
      if (lowerBreed.contains(invalid)) {
        return false;
      }
    }

    // 检查长度和格式
    return breedName.length >= 3 && 
           breedName.length <= 50 &&
           !breedName.contains('\n') &&
           !breedName.contains('  ') &&
           RegExp(r'^[a-zA-Z\s\-]+$').hasMatch(breedName);
  }

  // ... 以下保持原有的聊天功能不变 ...

  // 添加初始化欢迎消息的方法
  Future<void> initializeWelcomeMessage() async {
    final user = _auth.currentUser;
    if (user == null || _hasInitializedWelcomeMessage) return;

    // 获取用户名（使用displayName或email用户名）
    final userName = user.displayName ?? 
                  (user.email != null ? user.email!.split('@')[0] : "Pet Lover");
    // 检查是否已经有聊天记录
    final existingMessages = await _firestore
        .collection('chat_messages')
        .where('userId', isEqualTo: user.uid)
        .limit(1)
        .get();

    // 如果没有消息记录，添加欢迎消息
    if (existingMessages.docs.isEmpty) {
      final welcomeMessageId = 'welcome_message_${DateTime.now().millisecondsSinceEpoch}';
      
      final welcomeMessage = ChatMessage(
        id: welcomeMessageId,
        userId: user.uid,
        message: 'Hello!',
        isUser: false,
        timestamp: DateTime.now(),
        response: '''🐾 Welcome to PawPal AI Assistant, $userName! 

  I'm your dedicated dog expert here to help with all things canine! 🐕

  I can assist you with:
  • Training techniques and obedience 🎯
  • Health concerns and preventive care 🏥
  • Diet and nutrition guidance 🍖
  • Behavior issues and solutions 🐶
  • Grooming and maintenance tips ✂️
  • Breed-specific advice 📋
  • Puppy care and socialization 🐾
  • Senior dog wellness 👴

  What would you like to know about your furry friend today? Feel free to ask me anything! 😊''',
      );

      await _firestore.collection('chat_messages').doc(welcomeMessageId).set(welcomeMessage.toMap());
      _hasInitializedWelcomeMessage = true;
    }
  }

  Future<String> getAIResponse(String userMessage) async {
    print('🔍 Starting Gemini API call, user message: "$userMessage"');
    
    try {
      final String apiKey = dotenv.get('GEMINI_API_KEY');
      
      const String modelName = 'models/gemini-2.0-flash';
      const String apiUrl = 'https://generativelanguage.googleapis.com/v1/$modelName:generateContent';

      final headers = {
        'Content-Type': 'application/json',
      };

      final Map<String, dynamic> requestBody = {
        "contents": [
          {
            "parts": [
              {
                "text": '''You are PawPal, a professional dog expert AI assistant. You MUST respond in ENGLISH only.

                User question: "$userMessage"

                Provide concise and practical dog advice. Keep responses under 150 words.

                Focus on:
                - Key insights and main solutions
                - Most important actionable tips
                - Critical warning signs if any

                Be professional yet friendly. Use 1-2 relevant emojis.

                CRITICAL: 
                - RESPOND IN ENGLISH ONLY
                - KEEP RESPONSES CONCISE (under 150 words)
                - NO UNNECESSARY DETAILS
                - GET STRAIGHT TO THE POINT'''
              }
            ]
          }
        ],
        "generationConfig": {
          "temperature": 0.7,
          "maxOutputTokens": 300,  // 减少最大token数量
          "topP": 0.8,
          "topK": 40
        },
        "safetySettings": [
          {
            "category": "HARM_CATEGORY_HARASSMENT",
            "threshold": "BLOCK_MEDIUM_AND_ABOVE"
          },
          {
            "category": "HARM_CATEGORY_HATE_SPEECH", 
            "threshold": "BLOCK_MEDIUM_AND_ABOVE"
          }
        ]
      };

      print('🔄 Calling Gemini API with model: $modelName');
      
      final response = await http.post(
        Uri.parse('$apiUrl?key=$apiKey'),
        headers: headers,
        body: json.encode(requestBody),
      ).timeout(Duration(seconds: 30));

      print('📊 Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        if (responseData['candidates'] != null &&
            responseData['candidates'].isNotEmpty &&
            responseData['candidates'][0]['content'] != null &&
            responseData['candidates'][0]['content']['parts'] != null &&
            responseData['candidates'][0]['content']['parts'].isNotEmpty) {
          
          final String aiResponse = responseData['candidates'][0]['content']['parts'][0]['text'];
          print('✅ AI response obtained');
          return aiResponse;
        } else {
          print('❌ Response format issue');
          return _getFallbackResponse(userMessage);
        }
      } else {
        print('❌ API failed: ${response.statusCode}');
        return _getFallbackResponse(userMessage);
      }
    } catch (e) {
      print('❌ API call exception: $e');
      return _getFallbackResponse(userMessage);
    }
  }

  // 在 sendMessage 方法中确保欢迎消息初始化
  Future<void> sendMessage(String message) async {
    final user = _auth.currentUser;
    if (user == null) return;

    // 确保欢迎消息已初始化
    if (!_hasInitializedWelcomeMessage) {
      await initializeWelcomeMessage();
    }

    final messageId = DateTime.now().millisecondsSinceEpoch.toString();
    
    final userMessage = ChatMessage(
      id: messageId,
      userId: user.uid,
      message: message,
      isUser: true,
      timestamp: DateTime.now(),
    );

    await _firestore.collection('chat_messages').doc(messageId).set(userMessage.toMap());

    final aiResponse = await getAIResponse(message);
    
    final aiMessageId = '${messageId}_ai';
    final aiMessage = ChatMessage(
      id: aiMessageId,
      userId: user.uid,
      message: message,
      isUser: false,
      timestamp: DateTime.now(),
      response: aiResponse,
    );

    await _firestore.collection('chat_messages').doc(aiMessageId).set(aiMessage.toMap());
  }

  // 修改 getChatHistory 以确保欢迎消息显示
  Stream<List<ChatMessage>> getChatHistory() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    // 初始化欢迎消息
    if (!_hasInitializedWelcomeMessage) {
      initializeWelcomeMessage();
    }

    return _firestore
        .collection('chat_messages')
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .map((snapshot) {
          final messages = snapshot.docs
              .map((doc) => ChatMessage.fromFirestore(doc))
              .toList();
          messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          return messages;
        });
  }

  // 在清除聊天记录时重置欢迎消息标志
  Future<void> clearChatHistory() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final querySnapshot = await _firestore
        .collection('chat_messages')
        .where('userId', isEqualTo: user.uid)
        .get();

    final batch = _firestore.batch();
    for (final doc in querySnapshot.docs) {
      batch.delete(doc.reference);
    }
    
    await batch.commit();
    
    // 重置标志，以便下次可以再次显示欢迎消息
    _hasInitializedWelcomeMessage = false;
  }

  // Try alternative models if main one fails
  Future<String> _tryAlternativeModels(String apiKey, String userMessage) async {
    final models = [
      'models/gemini-2.5-pro',
      'models/gemini-1.5-pro-002',
      'models/gemini-1.5-flash-002',
    ];

    for (final model in models) {
      try {
        final apiUrl = 'https://generativelanguage.googleapis.com/v1/$model:generateContent';
        
        final response = await http.post(
          Uri.parse('$apiUrl?key=$apiKey'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            "contents": [{
              "parts": [{
                "text": "Answer in English about dogs: $userMessage"
              }]
            }]
          }),
        ).timeout(Duration(seconds: 15));

        if (response.statusCode == 200) {
          final responseData = json.decode(response.body);
          if (responseData['candidates'] != null && responseData['candidates'].isNotEmpty) {
            return responseData['candidates'][0]['content']['parts'][0]['text'];
          }
        }
      } catch (e) {
        continue;
      }
    }
    return _getFallbackResponse(userMessage);
  }

  String _getFallbackResponse(String userMessage) {
    final lowerMessage = userMessage.toLowerCase();
    
    if (lowerMessage.contains('unhappy') || lowerMessage.contains('sad')) {
      return 'I\'m sorry to hear your dog is unhappy. 🐶 Possible reasons:\n\n• Health issues or pain\n• Environmental changes\n• Lack of exercise\n• Social needs\n• Diet problems\n\nSpend quality time and maintain routine. Consult vet if continues.';
    }
    
    if (lowerMessage.contains('happy') || lowerMessage.contains('joy')) {
      return 'Great! 😊 Keep your dog happy with:\n• Regular exercise\n• Quality time\n• Healthy diet\n• Social activities\n• Safe environment';
    }
    
    if (lowerMessage.contains('eat') || lowerMessage.contains('food')) {
      return '🍖 Diet advice:\n• Quality age-appropriate food\n• Regular feeding schedule\n• Fresh water always\n• Avoid toxic human foods\n• Monitor appetite changes';
    }

    if (lowerMessage.contains('train') || lowerMessage.contains('obedience')) {
      return '🎯 Training tips:\n• Positive reinforcement\n• Short 5-15min sessions\n• Consistency with commands\n• Start with basics: sit/stay/come\n• Patience and repetition';
    }

    return '''🐾 I\'m PawPal AI Assistant for dog-related questions!

I can help with:
• Health care 🏥
• Training guidance 🎯
• Diet plans 🍖
• Behavior issues 🐕
• Grooming tips ✂️

Tell me more about your dog for specific advice!''';
  }

  List<String> getQuickQuestions() {
    return [
      'How to potty train a dog?',
      'What dog food is best?',
      'How to bathe a dog properly?',
      'Daily exercise requirements?',
      'Solving separation anxiety?',
      'Essential puppy vaccines?',
      'How to trim dog nails?',
      'Why does my dog bark excessively?',
    ];
  }
}