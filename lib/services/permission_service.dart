import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  Future<PermissionStatus> requestLocation() => Permission.locationWhenInUse.request();
  Future<PermissionStatus> requestNotifications() => Permission.notification.request();
  Future<PermissionStatus> requestContacts() => Permission.contacts.request();
  Future<PermissionStatus> requestMicrophone() => Permission.microphone.request();
  Future<PermissionStatus> requestCamera() => Permission.camera.request();
  Future<bool> openSettings() => openAppSettings();
}
