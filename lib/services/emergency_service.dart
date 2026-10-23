import '../services/database_service.dart';
import '../services/location_service.dart';

class EmergencyService {
  EmergencyService({DatabaseService? database, LocationService? location})
      : _database = database ?? DatabaseService(),
        _location = location ?? LocationService();

  final DatabaseService _database;
  final LocationService _location;

  Future<int> createDemoRequest({
    required String category,
    required String description,
  }) async {
    final position = await _location.getCurrentPosition();
    return _database.saveEmergencyRequest(
      category: category,
      description: description,
      latitude: position?.latitude,
      longitude: position?.longitude,
    );
  }
}
