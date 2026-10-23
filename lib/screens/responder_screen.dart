import 'package:flutter/material.dart';

import '../models/incident.dart';
import '../services/incident_service.dart';
import 'incident_map_screen.dart';

class ResponderScreen extends StatelessWidget {
  const ResponderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Responder dashboard')),
      body: StreamBuilder<List<Incident>>(
        stream: IncidentService.instance.watchOpenIncidents(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Could not load incidents: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final incidents = snapshot.data!;
          if (incidents.isEmpty) {
            return const Center(child: Text('No open SOS incidents right now.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: incidents.length,
            itemBuilder: (context, index) {
              final incident = incidents[index];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            incident.risk == 'high' ? Icons.warning : Icons.sos,
                            color: incident.risk == 'high' ? Colors.red : null,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${incident.category} • ${incident.risk.toUpperCase()}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('Incident: ${incident.id}'),
                      Text('Status: ${incident.status}'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          FilledButton(
                            onPressed: () async {
                              try {
                                await IncidentService.instance.acceptIncident(incident.id);
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Incident accepted.')),
                                );
                              } catch (error) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Could not accept: $error')),
                                );
                              }
                            },
                            child: const Text('Accept SOS'),
                          ),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.map),
                            label: const Text('View map'),
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => IncidentMapScreen(incident: incident),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
