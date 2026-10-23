import 'package:geolocator/geolocator.dart';

class LocationService {
  Future<Position> currentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) throw StateError('Enable device location to share emergency location.');
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      throw StateError('Location permission was not granted. You can still call emergency services.');
    }
    return Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 15)));
  }

  Stream<Position> watchPosition() => Geolocator.getPositionStream(locationSettings: const LocationSettings(
    accuracy: LocationAccuracy.high, distanceFilter: 15));
}
