class Room {
  final String id;
  final String name;
  final String building;
  final bool isOccupied;
  final int capacity;

  const Room({
    required this.id,
    required this.name,
    required this.building,
    required this.isOccupied,
    required this.capacity,
  });

  factory Room.fromJson(Map<String, dynamic> map) {
    return Room(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      building: map['building'] as String? ?? '',
      isOccupied: map['is_occupied'] as bool? ?? false,
      capacity: (map['capacity'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'building': building,
      'is_occupied': isOccupied,
      'capacity': capacity,
    };
  }
}
