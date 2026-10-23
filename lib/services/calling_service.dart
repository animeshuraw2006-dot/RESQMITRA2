import 'package:url_launcher/url_launcher.dart';

class CallingService {
  Future<bool> openDialler(String phoneNumber) async {
    final uri = Uri(scheme: 'tel', path: phoneNumber);
    return launchUrl(uri);
  }
}
