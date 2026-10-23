import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/incident.dart';

class IncidentMapScreen extends StatelessWidget {
  const IncidentMapScreen({super.key, required this.incident});

  final Incident incident;

  @override
  Widget build(BuildContext context) {
    final target = LatLng(incident.latitude, incident.longitude);
    return Scaffold(
      appBar: AppBar(title: const Text('Incident location')),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(target: target, zoom: 16),
        markers: {
          Marker(
            markerId: const MarkerId('incident'),
            position: target,
            infoWindow: InfoWindow(
              title: 'SOS location',
              snippet: '${incident.category} • ${incident.status}',
            ),
          ),
        },
        myLocationEnabled: false,
        compassEnabled: true,
        mapToolbarEnabled: true,
      ),
    );
  }
}
