import 'package:supabase_flutter/supabase_flutter.dart';

class PromptApi {
  final SupabaseClient supabaseClient;
  final String tableName = 'prompts';
  PromptApi(this.supabaseClient);

  // Fetch prompt
  Future<List<Map<String, dynamic>>> fetchPrompts() async {
    final response = await supabaseClient
        .from(tableName)
        .select('id, title, prompt, created_at')
        .order('id', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  // Create prompt
  Future<void> createPrompt(Map<String, dynamic> body) async {
    await supabaseClient.from(tableName).insert(body);
  }

  // Update prompt
  Future<void> updatePrompt(int id, Map<String, dynamic> body) async {
    await supabaseClient.from(tableName).update(body).eq('id', id);
  }

  // Delete prompt
  Future<void> deletePrompt(int id) async {
    await supabaseClient.from(tableName).delete().eq('id', id);
  }
}
