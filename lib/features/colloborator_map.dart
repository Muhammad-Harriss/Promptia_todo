import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CollaboratorMap extends StatefulWidget {
  final String promptId;
  const CollaboratorMap({super.key, required this.promptId});

  @override
  State<CollaboratorMap> createState() => _CollaboratorMapState();
}

class _CollaboratorMapState extends State<CollaboratorMap> {
  final List<Marker> _markers = [];

  @override
  void initState() {
    super.initState();
    _loadCollaborators();

    // ✅ Listen for realtime location updates from Supabase
    Supabase.instance.client
        .channel('public:user_locations')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'user_locations',
          callback: (payload) {
            _loadCollaborators();
          },
        )
        .subscribe();
  }

  Future<void> _loadCollaborators() async {
    final response =
        await Supabase.instance.client.from('user_locations').select();

    if (response.isEmpty) return;

    final markers = <Marker>[];

    for (var user in response) {
      final lat = (user['latitude'] as num?)?.toDouble();
      final lng = (user['longitude'] as num?)?.toDouble();
      final userId = user['user_id']?.toString();

      if (lat != null && lng != null && userId != null) {
        markers.add(
          Marker(
            point: LatLng(lat, lng),
            width: 50,
            height: 50,
            child: Column(
              children: [
                const Icon(Icons.location_on, color: Colors.red, size: 32),
                Text(
                  userId,
                  style: const TextStyle(fontSize: 10),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      }
    }

    setState(() {
      _markers
        ..clear()
        ..addAll(markers);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Collaborator Map")),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: LatLng(30.3753, 69.3451), // Pakistan center
          initialZoom: 5,
        ),
        children: [
          TileLayer(
            urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
            subdomains: const ['a', 'b', 'c'],
            userAgentPackageName: 'com.example.app',
          ),
          MarkerLayer(markers: _markers),
        ],
      ),
    );
  }
}
