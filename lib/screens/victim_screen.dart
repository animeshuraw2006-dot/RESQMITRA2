import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/incident.dart';
import '../services/incident_service.dart';
import '../services/location_service.dart';
import 'incident_map_screen.dart';

class VictimScreen extends StatefulWidget {
  final String initialCategory;
  const VictimScreen({super.key, this.initialCategory = 'Medical Emergency'});

  @override
  State<VictimScreen> createState() => _VictimScreenState();
}

class _VictimScreenState extends State<VictimScreen> {
  bool _busy = false;
  String? _incidentId;
  late String _category;

  @override
  void initState() {
    super.initState();
    _category = widget.initialCategory;
  }
  bool _highRisk = false;

  Future<void> _createSos() async {
    setState(() => _busy = true);
    try {
      final position = await LocationService.currentPosition();
      final id = await IncidentService.instance.createSos(
        position: position,
        category: _category,
        highRisk: _highRisk,
      );
      if (!mounted) return;
      setState(() => _incidentId = id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'SOS created. This demo does not yet send push notifications '
            'or contact emergency services.',
          ),
          duration: Duration(seconds: 5),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not create SOS: $error')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _call112() async {
    final uri = Uri(scheme: 'tel', path: '112');
    if (!await launchUrl(uri) && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the phone dialler. Call 112 manually.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Request help')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'If you are in immediate danger in India, call 112 now. '
            'Do not wait for a volunteer to respond.',
          ),
          const SizedBox(height: 18),
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: const InputDecoration(
              labelText: 'Emergency type',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'Medical Emergency', child: Text('Medical Emergency')),
              DropdownMenuItem(value: 'Accident', child: Text('Accident')),
              DropdownMenuItem(value: 'Fire', child: Text('Fire')),
              DropdownMenuItem(value: 'Flood / Water', child: Text('Flood / Water')),
              DropdownMenuItem(value: 'Rescue', child: Text('Rescue')),
              DropdownMenuItem(value: 'Evacuation', child: Text('Evacuation')),
              DropdownMenuItem(value: 'Missing Person', child: Text('Missing Person')),
              DropdownMenuItem(value: 'Shelter', child: Text('Shelter')),
              DropdownMenuItem(value: 'Food & Water', child: Text('Food & Water')),
              DropdownMenuItem(value: 'Blood Needed', child: Text('Blood Needed')),
              DropdownMenuItem(value: 'Drug Abuse', child: Text('Drug Abuse')),
              DropdownMenuItem(value: 'Immediate Danger', child: Text('Immediate Danger')),
              DropdownMenuItem(value: 'Harassment / Threat', child: Text('Harassment / Threat')),
              DropdownMenuItem(value: 'Unsafe Situation', child: Text('Unsafe Situation')),
              DropdownMenuItem(value: 'Escort Assistance', child: Text('Escort Assistance')),
              DropdownMenuItem(value: 'Safe Shelter', child: Text('Safe Shelter')),
              DropdownMenuItem(value: 'Lost / Missing Child', child: Text('Lost / Missing Child')),
              DropdownMenuItem(value: 'Abuse / Unsafe Touch', child: Text('Abuse / Unsafe Touch')),
              DropdownMenuItem(value: 'Stranger Danger', child: Text('Stranger Danger')),
              DropdownMenuItem(value: 'Bullying', child: Text('Bullying')),
              DropdownMenuItem(value: 'Safe Pickup / Trusted Adult', child: Text('Safe Pickup / Trusted Adult')),
              DropdownMenuItem(value: 'Child in Danger', child: Text('Child in Danger')),
              DropdownMenuItem(value: 'Other Emergency', child: Text('Other Emergency')),
              DropdownMenuItem(value: 'Other', child: Text('Other')), 
            ],
            onChanged: (value) {
              if (value != null) setState(() => _category = value);
            },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Mark as high risk'),
            subtitle: const Text(
              'Prioritises the incident label only in this MVP; it does not start recording.',
            ),
            value: _highRisk,
            onChanged: (value) => setState(() => _highRisk = value),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 62,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade800,
                foregroundColor: Colors.white,
              ),
              onPressed: _busy || _incidentId != null ? null : _createSos,
              icon: _busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sos, size: 30),
              label: Text(_busy ? 'CREATING SOS…' : 'SEND SOS'),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _call112,
            icon: const Icon(Icons.call),
            label: const Text('Call emergency number 112'),
          ),
          if (_incidentId != null) ...[
            const SizedBox(height: 20),
            const Text('Incident status', style: TextStyle(fontWeight: FontWeight.bold)),
            StreamBuilder<Incident?>(
              stream: IncidentService.instance.watchIncident(_incidentId!),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text('Could not load status: ${snapshot.error}');
                }
                final incident = snapshot.data;
                if (incident == null) return const Text('Loading incident…');
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.shield_outlined),
                    title: Text('Status: ${incident.status.replaceAll('_', ' ')}'),
                    subtitle: Text('Incident ID: ${incident.id}'),
                    trailing: IconButton(
                      tooltip: 'View incident location',
                      icon: const Icon(Icons.map),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => IncidentMapScreen(incident: incident),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            TextButton(
              onPressed: () async {
                await IncidentService.instance.updateStatus(_incidentId!, 'cancelled');
                if (mounted) setState(() => _incidentId = null);
              },
              child: const Text('Cancel SOS'),
            ),
          ],
        ],
      ),
    );
  }
}
