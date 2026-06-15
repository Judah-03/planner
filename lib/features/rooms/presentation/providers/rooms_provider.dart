import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:planner/core/network/api_service.dart';

class RoomStatus {
  final String id;
  final String name;
  final String building;
  final bool isOccupied;
  final String? nextExam;
  final String? nextTime;
  final int capacity;

  const RoomStatus({
    required this.id,
    required this.name,
    required this.building,
    required this.isOccupied,
    this.nextExam,
    this.nextTime,
    required this.capacity,
  });

  RoomStatus copyWith({bool? isOccupied}) {
    return RoomStatus(
      id: id,
      name: name,
      building: building,
      isOccupied: isOccupied ?? this.isOccupied,
      nextExam: nextExam,
      nextTime: nextTime,
      capacity: capacity,
    );
  }

  factory RoomStatus.fromJson(Map<String, dynamic> map) {
    return RoomStatus(
      id: map['id'] as String,
      name: map['name'] as String,
      building: map['building'] as String,
      isOccupied: map['is_occupied'] as bool,
      nextExam: map['next_exam'],
      nextTime: map['next_time'],
      capacity: map['capacity'] as int,
    );
  }
}

final roomsProvider = StateNotifierProvider<RoomsNotifier, List<RoomStatus>>((ref) {
  return RoomsNotifier();
});

class RoomsNotifier extends StateNotifier<List<RoomStatus>> {
  RoomsNotifier() : super([]) {
    _loadRooms();
  }

  Future<void> _loadRooms() async {
    try {
      final List<dynamic> data = await ApiService.getRooms();
      state = data.map((item) => RoomStatus.fromJson(item)).toList();
    } catch (e) {
      state = [];
    }
  }

  Future<void> refresh() async {
    await _loadRooms();
  }

  Future<void> toggleOccupancy(String roomId) async {
    final roomIndex = state.indexWhere((r) => r.id == roomId);
    if (roomIndex == -1) return;

    final room = state[roomIndex];
    final newStatus = !room.isOccupied;

    try {
      await ApiService.updateRoomOccupancy(roomId, newStatus);
      state = [
        for (final r in state)
          if (r.id == roomId) r.copyWith(isOccupied: newStatus) else r
      ];
    } catch (e) {
      // Gérer l'erreur
    }
  }
}
