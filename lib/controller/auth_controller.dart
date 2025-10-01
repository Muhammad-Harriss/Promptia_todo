import 'dart:developer';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:location/location.dart';
import 'package:supabase_todo/controller/auth_api.dart';
import 'package:supabase_todo/utils/supabase_service.dart';

class AuthController {
  late final AuthApi authApi;

  AuthController() {
    authApi = AuthApi(SupabaseService.supabase);
  }

  /// -------------------------
  /// Save FCM token safely for multiple devices
  /// -------------------------
  Future<void> _saveFcmToken() async {
    final user = SupabaseService.supabase.auth.currentUser;
    if (user == null) return;

    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) return;

    try {
      await SupabaseService.supabase.from('user_devices').upsert(
        {
          'user_id': user.id,
          'fcm_token': token,
        },
        onConflict: 'user_id,fcm_token',
      );

      log("✅ FCM token saved/upserted: $token");
    } catch (e) {
      log("❌ Error saving FCM token: $e");
    }

    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      try {
        await SupabaseService.supabase.from('user_devices').upsert(
          {
            'user_id': user.id,
            'fcm_token': newToken,
          },
          onConflict: 'user_id,fcm_token',
        );
        log("🔄 FCM token refreshed/upserted: $newToken");
      } catch (e) {
        log("❌ Error updating FCM token: $e");
      }
    });
  }

  /// -------------------------
  /// Save User Location
  /// -------------------------
  Future<void> _saveUserLocation() async {
    final user = SupabaseService.supabase.auth.currentUser;
    if (user == null) return;

    final location = Location();

    // Ask for permission
    final permission = await location.requestPermission();
    if (permission != PermissionStatus.granted) {
      log("⚠️ Location permission not granted");
      return;
    }

    final current = await location.getLocation();

    try {
      await SupabaseService.supabase.from('user_locations').upsert(
        {
          'user_id': user.id,
          'latitude': current.latitude,
          'longitude': current.longitude,
        },
        onConflict: 'user_id',
      );
      log("📍 Location saved: ${current.latitude}, ${current.longitude}");
    } catch (e) {
      log("❌ Error saving location: $e");
    }
  }

  /// -------------------------
  /// Login method
  /// -------------------------
  Future<bool> login(String email, String password) async {
    try {
      final response = await authApi.login(email, password);

      if (response.user != null) {
        log("Login successful: ${response.user!.email}");

        // Save FCM + Location after login
        await _saveFcmToken();
        await _saveUserLocation();

        return true;
      } else {
        log("Invalid credentials");
        return false;
      }
    } catch (e) {
      log("Login error: $e");
      return false;
    }
  }

  /// -------------------------
  /// Signup method
  /// -------------------------
  Future<bool> signup(String name, String email, String password) async {
    try {
      final response = await authApi.Signup(name, email, password);

      if (response.user != null) {
        log("Signup successful: ${response.user!.email}");

        // Save location immediately after signup
        await _saveUserLocation();

        return true;
      } else {
        log("Signup failed");
        return false;
      }
    } catch (e) {
      log("Signup error: $e");
      return false;
    }
  }
}
