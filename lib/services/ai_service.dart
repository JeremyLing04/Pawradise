// services/ai_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/chat_message_model.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class AIService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _hasInitializedWelcomeMessage = false;

  // Identify dog breed from image
  static Future<String?> identifyDogBreed(File imageFile) async {
    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) throw Exception('Gemini API key not found');

      final model = GenerativeModel(model: 'models/gemini-2.0-flash', apiKey: apiKey);

      final prompt = '''
Analyze this dog image and identify the breed. 
Return ONLY the most likely breed name in English.
If it's not a dog or unclear, return "Unknown".
Format: Just the breed name
Example: "Golden Retriever"
''';

      final imageBytes = await imageFile.readAsBytes();
      final content = [Content.multi([TextPart(prompt), DataPart('image/jpeg', imageBytes)])];

      final response = await model.generateContent(content);
      final breed = response.text?.trim();

      if (breed != null && breed.isNotEmpty) {
        final cleanedBreed = breed.replaceAll('"', '').replaceAll("'", '').replaceAll('.', '').trim();
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

  // Alternative dog breed identification
  static Future<String?> identifyDogBreedAlternative(File imageFile) async {
    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) throw Exception('Gemini API key not found');

      final imageBytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(imageBytes);

      const String modelName = 'models/gemini-2.0-flash';
      const String apiUrl = 'https://generativelanguage.googleapis.com/v1/$modelName:generateContent';

      final headers = {'Content-Type': 'application/json'};

      final Map<String, dynamic> requestBody = {
        "contents": [
          {
            "parts": [
              {"text": '''Analyze this dog image and identify the breed. Return ONLY the most likely breed name in English.'''},
              {"inline_data": {"mime_type": "image/jpeg", "data": base64Image}}
            ]
          }
        ],
        "generationConfig": {"temperature": 0.1, "maxOutputTokens": 20, "topP": 0.8, "topK": 40}
      };

      final response = await http.post(Uri.parse('$apiUrl?key=$apiKey'), headers: headers, body: json.encode(requestBody)).timeout(Duration(seconds: 30));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['candidates'] != null &&
            responseData['candidates'].isNotEmpty &&
            responseData['candidates'][0]['content']?['parts']?.isNotEmpty == true) {
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

  // Get detailed breed information
  static Future<String> getBreedInformation(String breedName) async {
    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) return 'Breed information not available.';

      final model = GenerativeModel(model: 'gemini-2.0-flash', apiKey: apiKey);

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

  // Validate breed name
  static bool isValidBreedName(String breedName) {
    if (breedName.isEmpty || breedName == 'Unknown') return false;

    final invalidResponses = ['sorry', 'error', 'cannot', 'unable', 'not sure', 'not a dog', 'unsure', 'maybe'];
    final lowerBreed = breedName.toLowerCase();

    for (final invalid in invalidResponses) if (lowerBreed.contains(invalid)) return false;

    return breedName.length >= 3 &&
           breedName.length <= 50 &&
           !breedName.contains('\n') &&
           !breedName.contains('  ') &&
           RegExp(r'^[a-zA-Z\s\-]+$').hasMatch(breedName);
  }

  // Initialize welcome message
  Future<void> initializeWelcomeMessage() async {
    final user = _auth.currentUser;
    if (user == null || _hasInitializedWelcomeMessage) return;

    final userName = user.displayName ?? (user.email != null ? user.email!.split('@')[0] : "Pet Lover");

    final existingMessages = await _firestore.collection('chat_messages').where('userId', isEqualTo: user.uid).limit(1).get();

    if (existingMessages.docs.isEmpty) {
      final welcomeMessageId = 'welcome_message_${DateTime.now().millisecondsSinceEpoch}';
      final welcomeMessage = ChatMessage(
        id: welcomeMessageId,
        userId: user.uid,
        message: 'Hello!',
        isUser: false,
        timestamp: DateTime.now(),
        response: '''🐾 Welcome to PawPal AI Assistant, $userName!
I can assist with training, health, diet, behavior, grooming, breed advice, puppy & senior dog care. Ask me anything! 😊''',
      );
      await _firestore.collection('chat_messages').doc(welcomeMessageId).set(welcomeMessage.toMap());
      _hasInitializedWelcomeMessage = true;
    }
  }

  // Get AI response from Gemini API
  Future<String> getAIResponse(String userMessage) async {
    print('🔍 Starting Gemini API call: "$userMessage"');

    try {
      final String apiKey = dotenv.get('GEMINI_API_KEY');
      const String modelName = 'models/gemini-2.0-flash';
      const String apiUrl = 'https://generativelanguage.googleapis.com/v1/$modelName:generateContent';

      final headers = {'Content-Type': 'application/json'};
      final Map<String, dynamic> requestBody = {
        "contents": [
          {
            "parts": [
              {
                "text": '''You are PawPal AI. Respond in ENGLISH only.
User question: "$userMessage"
Provide concise practical advice (<150 words). Use 1-2 emojis.'''
              }
            ]
          }
        ],
        "generationConfig": {"temperature": 0.7, "maxOutputTokens": 300, "topP": 0.8, "topK": 40},
        "safetySettings": [
          {"category": "HARM_CATEGORY_HARASSMENT", "threshold": "BLOCK_MEDIUM_AND_ABOVE"},
          {"category": "HARM_CATEGORY_HATE_SPEECH", "threshold": "BLOCK_MEDIUM_AND_ABOVE"}
        ]
      };

      final response = await http.post(Uri.parse('$apiUrl?key=$apiKey'), headers: headers, body: json.encode(requestBody)).timeout(Duration(seconds: 30));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['candidates'] != null &&
            responseData['candidates'].isNotEmpty &&
            responseData['candidates'][0]['content']?['parts']?.isNotEmpty == true) {
          return responseData['candidates'][0]['content']['parts'][0]['text'];
        } else {
          return _getFallbackResponse(userMessage);
        }
      } else {
        return _getFallbackResponse(userMessage);
      }
    } catch (e) {
      print('❌ API call exception: $e');
      return _getFallbackResponse(userMessage);
    }
  }

  // Send message and store both user and AI messages
  Future<void> sendMessage(String message) async {
    final user = _auth.currentUser;
    if (user == null) return;

    if (!_hasInitializedWelcomeMessage) await initializeWelcomeMessage();

    final messageId = DateTime.now().millisecondsSinceEpoch.toString();
    final userMessage = ChatMessage(id: messageId, userId: user.uid, message: message, isUser: true, timestamp: DateTime.now());

    await _firestore.collection('chat_messages').doc(messageId).set(userMessage.toMap());

    final aiResponse = await getAIResponse(message);

    final aiMessageId = '${messageId}_ai';
    final aiMessage = ChatMessage(id: aiMessageId, userId: user.uid, message: message, isUser: false, timestamp: DateTime.now(), response: aiResponse);

    await _firestore.collection('chat_messages').doc(aiMessageId).set(aiMessage.toMap());
  }

  // Stream chat history
  Stream<List<ChatMessage>> getChatHistory() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    if (!_hasInitializedWelcomeMessage) initializeWelcomeMessage();

    return _firestore.collection('chat_messages').where('userId', isEqualTo: user.uid).snapshots().map((snapshot) {
      final messages = snapshot.docs.map((doc) => ChatMessage.fromFirestore(doc)).toList();
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return messages;
    });
  }

  // Clear chat and reset welcome flag
  Future<void> clearChatHistory() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final querySnapshot = await _firestore.collection('chat_messages').where('userId', isEqualTo: user.uid).get();
    final batch = _firestore.batch();
    for (final doc in querySnapshot.docs) batch.delete(doc.reference);
    await batch.commit();

    _hasInitializedWelcomeMessage = false;
  }

  // Fallback AI response
  String _getFallbackResponse(String userMessage) {
    final lowerMessage = userMessage.toLowerCase();

    if (lowerMessage.contains('unhappy') || lowerMessage.contains('sad')) {
      return 'I\'m sorry your dog is unhappy. 🐶 Possible reasons: health, environment, exercise, social needs, diet. Consult vet if persists.';
    }
    if (lowerMessage.contains('happy') || lowerMessage.contains('joy')) {
      return 'Great! 😊 Keep your dog happy: exercise, quality time, healthy diet, social activities.';
    }
    if (lowerMessage.contains('eat') || lowerMessage.contains('food')) {
      return '🍖 Diet advice: quality food, fixed schedule, fresh water, avoid toxic foods, monitor appetite.';
    }
    if (lowerMessage.contains('train') || lowerMessage.contains('obedience')) {
      return '🎯 Training tips: positive reinforcement, short sessions, consistency, basics first, patience.';
    }

    return '''🐾 I\'m PawPal AI Assistant!
I can help with:
• Health 🏥
• Training 🎯
• Diet 🍖
• Behavior 🐕
• Grooming ✂️
Ask me about your dog!''';
  }

  // Quick question suggestions
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
