import 'package:supabase_flutter/supabase_flutter.dart';

class AuthApi {
  final SupabaseClient supabaseClient;
  AuthApi(this.supabaseClient);

  /// -------------------------
  /// Login user
  /// -------------------------
  Future<AuthResponse> login(String email, String password) async {
    final AuthResponse response = await supabaseClient.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return response;
  }

  /// -------------------------
  /// Signup user (metadata is optional)
  /// -------------------------
  Future<AuthResponse> Signup(String name, String email, String password) async {
    final AuthResponse response = await supabaseClient.auth.signUp(
      email: email,
      password: password,
      data: {'name': name}, // optional metadata
    );
    return response;
  }
}
