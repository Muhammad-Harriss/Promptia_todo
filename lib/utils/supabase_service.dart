// ignore_for_file: unnecessary_type_check

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supabase_todo/routes/routes_name.dart';
import 'package:supabase_todo/utils/storage_service.dart';

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
      } else if (event == AuthChangeEvent.tokenRefreshed) {
        // session already refreshed & saved above
      }
    });
  }
}


extension PromptCollaboration on SupabaseService {
  /// Invite a user (by email) to collaborate on a prompt.
  /// Returns null if successful, or an error string otherwise.
  static Future<String?> inviteUserToPrompt({
    required String email,
    required String promptId, // must be a valid prompt UUID
  }) async {
    try {
      final trimmedEmail = email.trim().toLowerCase();

      // Call the RPC (returns a String now)
      final result = await SupabaseService.supabase.rpc(
        'invite_user_to_prompt',
        params: {
          'p_prompt_id': promptId,
          'p_user_email': trimmedEmail,
        },
      );

      if (result == 'success') {
        return null; // ✅ success → return no error
      }

      // Pass back Postgres return string as error
      return result.toString();
    } catch (e, st) {
      print("ERROR inviteUserToPrompt: $e\n$st");
      return e.toString();
    }
  }
}
