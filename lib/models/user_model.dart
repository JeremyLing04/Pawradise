import 'package:cloud_firestore/cloud_firestore.dart'; 

class User {
  final String id;
  final String email;
  final String username;
  final String name; 
  final int karmaPoints;
  final DateTime createdAt;
  final String? avatarUrl; 
  final String bio; 
  final List<String> searchKeywords; 

  User({
    required this.id,
    required this.email,
    required this.username,
    required this.name, 
    required this.karmaPoints,
    required this.createdAt,
    this.avatarUrl, 
    this.bio = '', 
    required this.searchKeywords,
  });

  factory User.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return User(
      id: doc.id,
      email: data['email'] ?? '',
      username: data['username'] ?? '',
      name: data['name'] ?? '', 
      karmaPoints: data['karmaPoints'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      avatarUrl: data['avatarUrl'], 
      bio: data['bio'] ?? '', 
      searchKeywords: List<String>.from(data['searchKeywords'] ?? []),
    );
  }

  factory User.fromMap(Map<String, dynamic> data, String id) {
    return User(
      id: id,
      email: data['email'] ?? '',
      username: data['username'] ?? '',
      name: data['name'] ?? '', 
      karmaPoints: data['karmaPoints'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      avatarUrl: data['avatarUrl'],
      bio: data['bio'] ?? '',
      searchKeywords: data['searchKeywords'] ?? [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'username': username,
      'name': name, 
      'karmaPoints': karmaPoints,
      'createdAt': Timestamp.fromDate(createdAt),
      'avatarUrl': avatarUrl, 
      'bio': bio, 
      'updatedAt': FieldValue.serverTimestamp(), 
      'searchKeywords': searchKeywords,
    };
  }

  static List<String> generateSearchKeywords(String username, String name) {
    Set<String> keywords = {};

    String cleanedUsername = username.toLowerCase().trim();
    String cleanedName = name.toLowerCase().trim();

    if (cleanedUsername.isNotEmpty) {
      keywords.add(cleanedUsername);
      for (int i = 1; i <= cleanedUsername.length; i++) {
        String prefix = cleanedUsername.substring(0, i);
        if (prefix.length > 1) keywords.add(prefix);
      }
    }

    if (cleanedName.isNotEmpty) {
      keywords.add(cleanedName);
      for (int i = 1; i <= cleanedName.length; i++) {
        String prefix = cleanedName.substring(0, i);
        if (prefix.length > 1) keywords.add(prefix);
      }
    }

    return keywords.toList();
  }

  factory User.createNew({
    required String id,
    required String email,
    required String username,
    required String name, 
    int karmaPoints = 0,
  }) {
    return User(
      id: id,
      email: email,
      username: username,
      name: name,
      karmaPoints: karmaPoints,
      createdAt: DateTime.now(),
      searchKeywords: generateSearchKeywords(username, name),
    );
  }

  User copyWith({
    String? email,
    String? username,
    String? name,
    int? karmaPoints,
    String? avatarUrl,
    String? bio,
    List<String>? searchKeywords,
  }) {
    return User(
      id: id,
      email: email ?? this.email,
      username: username ?? this.username,
      name: name ?? this.name,
      karmaPoints: karmaPoints ?? this.karmaPoints,
      createdAt: createdAt,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      searchKeywords: searchKeywords ?? this.searchKeywords,
    );
  }

  User withUpdatedSearchKeywords() {
    return copyWith(
      searchKeywords: generateSearchKeywords(username, name),
    );
  }

  String get displayAvatarUrl {
    return avatarUrl ?? 'https://via.placeholder.com/150/cccccc/ffffff?text=${username[0]}';
  }

  @override
  String toString() {
    return 'User{id: $id, username: $username, name: $name, email: $email, karmaPoints: $karmaPoints, bio: $bio}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
