class Pet {
  final String id;
  final String userId;
  final String name;
  final String species; // optional

  Pet({
    required this.id,
    required this.userId,
    required this.name,
    required this.species,
  });

  factory Pet.fromMap(Map<String, dynamic> m) => Pet(
    id: m['id'] as String,
    userId: m['userId'] as String,
    name: m['name'] as String,
    species: m['species'] as String? ?? '',
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'name': name,
    'species': species,
  };
}
