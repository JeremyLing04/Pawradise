// // services/pet_knowledge_base.dart
// class PetKnowledgeBase {
//   static final Map<String, String> quickAnswers = {
//     'emergency': '🚨 EMERGENCY SIGNS: \n• Difficulty breathing\n• Bleeding that won\'t stop\n• Seizures\n• Unconsciousness\n• Suspected poisoning\n\n→ Go to emergency vet immediately!',
//     'vaccine': '💉 VACCINE SCHEDULE:\nPuppies/Kittens: 6-8, 10-12, 14-16 weeks\nAdults: Annual boosters\nSenior: Discuss with vet\n\nKeep vaccination records updated!',
//     'groom': '✂️ GROOMING BASICS:\n• Brush regularly (frequency depends on coat type)\n• Bath every 4-6 weeks\n• Trim nails every 2-4 weeks\n• Clean ears weekly\n• Dental care daily',
//     'exercise': '🎾 EXERCISE NEEDS:\nPuppies: 5 mins per month of age, twice daily\nAdult dogs: 30-60 mins daily\nSenior dogs: 20-30 mins daily\nCats: 15-30 mins play daily',
//     'poison': '⚠️ POISON EMERGENCY:\nIf you suspect poisoning:\n1. Call emergency vet immediately\n2. Don\'t induce vomiting unless instructed\n3. Bring the substance container if possible\n4. Watch for symptoms: vomiting, diarrhea, seizures',
//   };

//   static String? getQuickAnswer(String message) {
//     final lowerMessage = message.toLowerCase();
    
//     for (final keyword in quickAnswers.keys) {
//       if (lowerMessage.contains(keyword)) {
//         return quickAnswers[keyword];
//       }
//     }
//     return null;
//   }
// }