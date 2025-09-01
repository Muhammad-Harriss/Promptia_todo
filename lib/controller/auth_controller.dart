import 'dart:developer';
import 'package:supabase_todo/controller/auth_api.dart';
import 'package:supabase_todo/utils/supabase_service.dart';

class AuthController {
  late AuthApi authApi;

  AuthController() {
    authApi = AuthApi(SupabaseService.supabase);
  }

  /// Login method
  Future<bool> login(String email, String password) async {
    try {
      final response = await authApi.login(email, password);

      if (response.user != null) {
        log(" Login successful: ${response.user!.email}");
        return true;
      } else {
        log(" Invalid credentials");
        return false;
      }
    } catch (e) {
      log("Login error: $e");
      return false;
    }
  }

  /// Signup method
  Future<bool> signup(String name, String email, String password) async {
    try {
      final response = await authApi.Signup(name, email, password);

      if (response.user != null) {
        log(" Signup successful: ${response.user!.email}");
        return true;
      } else {
        log(" Signup failed");
        return false;
      }
    } catch (e) {
      log("Signup error: $e");
      return false;
    }
  }
}
