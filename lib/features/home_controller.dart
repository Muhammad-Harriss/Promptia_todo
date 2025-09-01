import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supabase_todo/features/prompt_api.dart';
import 'package:supabase_todo/model/prompt_model.dart';
import 'package:supabase_todo/utils/supabase_service.dart';
import 'package:supabase_todo/routes/routes_name.dart';

class HomeController {
  final PromptApi _promptApi = PromptApi(SupabaseService.supabase);

  List<Prompt> prompts = [];
  bool isLoading = false;

  RealtimeChannel? _channel;

  Future<void> fetchPrompts(VoidCallback onUpdate) async {
    try {
      isLoading = true;
      onUpdate();

      final response = await _promptApi.fetchPrompts();
      prompts = response.map((item) => Prompt.fromJson(item)).toList();
    } catch (e) {
      debugPrint(" Error fetching prompts: $e");
    } finally {
      isLoading = false;
      onUpdate();
    }
  }

  void subscribeRealtime(VoidCallback onUpdate) {
    _channel = SupabaseService.supabase
        .channel('public:prompts')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'prompts',
          callback: (payload) {
            debugPrint("📡 Realtime event: $payload");
            _handleRealtimeChange(payload, onUpdate);
          },
        )
        .subscribe();
  }

  void _handleRealtimeChange(
      PostgresChangePayload payload, VoidCallback onUpdate) {
    final eventType = payload.eventType;
    final newRecord = payload.newRecord;
    final oldRecord = payload.oldRecord;

    if (eventType == PostgresChangeEvent.insert && newRecord != null) {
      prompts.insert(0, Prompt.fromJson(newRecord));
    } else if (eventType == PostgresChangeEvent.update && newRecord != null) {
      final index = prompts.indexWhere((p) => p.id == newRecord['id']);
      if (index != -1) {
        prompts[index] = Prompt.fromJson(newRecord);
      }
    } else if (eventType == PostgresChangeEvent.delete && oldRecord != null) {
      prompts.removeWhere((p) => p.id == oldRecord['id']);
    }
    onUpdate();
  }

  void dispose() {
    _channel?.unsubscribe();
  }

  /// ✅ Safe Logout
  Future<void> logout(BuildContext context) async {
    try {
      dispose(); // stop realtime
      await SupabaseService.supabase.auth.signOut();

      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          RoutesName.login,
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint("❌ Error during logout: $e");
    }
  }
}
