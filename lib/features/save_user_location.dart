import 'package:location/location.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> saveUserLocation() async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return;

  final location = Location();
  final permission = await location.requestPermission();
  if (permission != PermissionStatus.granted) return;

  final current = await location.getLocation();

  await Supabase.instance.client
      .from('user_locations')
      .upsert({
        'user_id': user.id,
        'latitude': current.latitude,
        'longitude': current.longitude,
      });
}
