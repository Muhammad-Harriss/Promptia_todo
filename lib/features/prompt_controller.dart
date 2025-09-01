import 'package:get/get.dart';
import 'package:supabase_todo/features/prompt_api.dart';
import 'package:supabase_todo/screens/Home_Screen.dart';
import 'package:supabase_todo/utils/supabase_service.dart';

class PromptController extends GetxController {
  final PromptApi _promptApi = PromptApi(SupabaseService.supabase);
  RxBool isloading = false.obs;

  Future<void> createPrompt(String title, String prompt) async {
    try {
      isloading.value = true;

      await _promptApi.createPrompt({
        'title': title,
        'prompt': prompt,
      });

      print("Prompt created successfully");

      /// Go back or move to Home
      Get.off(() => HomeScreen());

    } catch (e) {
      print("❌ Error creating prompt: $e");
      Get.snackbar("Error", "Failed to create prompt");
    } finally {
      isloading.value = false;
    }
  }
}
