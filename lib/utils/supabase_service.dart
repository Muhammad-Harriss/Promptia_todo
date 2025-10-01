// ignore_for_file: unnecessary_type_check
import 'dart:async'; 
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:supabase_todo/routes/routes_name.dart';
import 'package:supabase_todo/utils/storage_service.dart';
import 'package:supabase_todo/model/prompt_model.dart';


class SupabaseService {
  static final SupabaseClient supabase = Supabase.instance.client;

  /// (Optional) use this to navigate without BuildContext
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// Try to restore a previously saved session.
  /// Returns true if a valid session is restored.
  static Future<bool> tryRestoreSession() async {
    final raw = await StorageService.getRawSession();
    if (raw == null) return false;

    try {
      final res = await supabase.auth.recoverSession(raw); // expects JSON string
      final session = res.session;
      if (session != null) {
        await StorageService.saveSession(session); // keep it fresh
        return true;
      }
    } catch (_) {
      // ignore and fall through
    }

    await StorageService.clearSession();
    return false;
  }

  /// Listen to auth events and keep SharedPreferences + navigation in sync
  static void listenAuthChanges() {
    supabase.auth.onAuthStateChange.listen((data) async {
      final event = data.event;
      final session = data.session;

      if (session != null) {
        await StorageService.saveSession(session);
      }

      if (event == AuthChangeEvent.signedIn) {
        navigatorKey.currentState
            ?.pushNamedAndRemoveUntil(RoutesName.home, (_) => false);
      } else if (event == AuthChangeEvent.signedOut) {
        await StorageService.clearSession();
        navigatorKey.currentState
            ?.pushNamedAndRemoveUntil(RoutesName.login, (_) => false);
      }
    });
  }
}



extension PromptCollaboration on SupabaseService {
  /// ---------------- Invite a user ----------------
  static Future<String?> inviteUserToPrompt({
    required String email,
    required String promptId,
  }) async {
    final trimmedEmail = email.trim().toLowerCase();
    if (trimmedEmail.isEmpty) return "Email cannot be empty";

    try {
      // 1. Send notification
      final notifRes = await SupabaseService.supabase.functions
          .invoke(
            'send-notification',
            body: {
              'type': 'assignment',
              'prompt_id': promptId,
              'user_email': trimmedEmail,
            },
          )
          .timeout(const Duration(seconds: 15));

      // 2. Send email (independent of notification result)
      final emailRes = await SupabaseService.supabase.functions
          .invoke(
            'send-email',
            body: {
              'to': trimmedEmail,
              'subject': "You've been invited!",
              'body': "You’ve been invited to collaborate on prompt $promptId 🚀",
            },
          )
          .timeout(const Duration(seconds: 15));

      debugPrint("✅ Notification response: ${notifRes.data}");
      debugPrint("✅ Email response: ${emailRes.data}");

      return null; // success
    } on TimeoutException {
      return "Request timed out. Please try again.";
    } catch (e, st) {
      debugPrint("🔥 ERROR inviteUserToPrompt: $e\n$st");
      return "Network error or request failed. Please try again.";
    }
  }
  




  /// ---------------- Fetch prompts ----------------
  static Future<List<Prompt>> fetchUserPrompts() async {
    try {
      final rpc = await SupabaseService.supabase.rpc('get_user_prompts');
      if (rpc is List) {
        return rpc
            .map((e) => Prompt.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
      return [];
    } catch (e, st) {
      print("ERROR fetchUserPrompts: $e\n$st");
      return [];
    }
  }

  /// ---------------- Update prompt ----------------
  static Future<String?> updatePrompt({
    required String promptId,
    required String title,
    required String promptText,
  }) async {
    try {
      final rpc = await SupabaseService.supabase.rpc('update_prompt', params: {
        'p_prompt_id': promptId,
        'p_title': title,
        'p_prompt': promptText,
      });

      if (rpc is String) return rpc == 'success' ? null : rpc;
      if (rpc is Map<String, dynamic>) {
        final val = rpc.values.first;
        return val == 'success' ? null : val.toString();
      }
      return null;
    } catch (e, st) {
      print("ERROR updatePrompt: $e\n$st");
      return e.toString();
    }
  }

  /// ---------------- Delete prompt ----------------
  static Future<String?> deletePrompt({required String promptId}) async {
    try {
      final rpc = await SupabaseService.supabase.rpc('delete_prompt', params: {
        'p_prompt_id': promptId,
      });

      if (rpc is String) return rpc == 'success' ? null : rpc;
      if (rpc is Map<String, dynamic>) {
        final val = rpc.values.first;
        return val == 'success' ? null : val.toString();
      }
      return null;
    } catch (e, st) {
      print("ERROR deletePrompt: $e\n$st");
      return e.toString();
    }
  }
}
