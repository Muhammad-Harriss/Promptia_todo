// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:form_validator/form_validator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supabase_todo/model/prompt_model.dart';
import 'package:supabase_todo/widgets/buttonstyle.dart';
import 'package:supabase_todo/widgets/prompt_input.dart';

class AddPrompts extends StatefulWidget {
  const AddPrompts({super.key});

  @override
  State<AddPrompts> createState() => _AddPromptsState();
}

class _AddPromptsState extends State<AddPrompts> {
  final GlobalKey<FormState> _foam = GlobalKey<FormState>();
  final TextEditingController titleController = TextEditingController();
  final TextEditingController promptTextController = TextEditingController();

  bool isLoading = false;

  @override
  void dispose() {
    titleController.dispose();
    promptTextController.dispose();
    super.dispose();
  }

  Future<void> createPrompt(String title, String prompt) async {
    setState(() {
      isLoading = true;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;

      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ No user logged in")),
        );
        return;
      }

      final response = await Supabase.instance.client
          .from('prompts')
          .insert({
            'title': title,
            'prompt': prompt,
            'owner_id': user.id, // ✅ attach logged-in user
          })
          .select()
          .single();

      final newPrompt = Prompt.fromJson(response);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("✅ Prompt '${newPrompt.title}' added!"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, newPrompt); // pass created prompt back
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error: $e")),
        
      );
      print('$e');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Add New Prompt',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xff1f1c2c), Color(0xff928dab)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 100),
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Form(
                    key: _foam,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Create a New Prompt",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "Fill in the details below to add your custom prompt.",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 20),
                        PromptInput(
                          controller: titleController,
                          label: 'Title',
                          hinttext: 'Enter your title',
                          validatorcallback: ValidationBuilder()
                              .minLength(3)
                              .maxLength(50)
                              .build(),
                        ),
                        const SizedBox(height: 20),
                        PromptInput(
                          controller: promptTextController,
                          label: 'Prompt',
                          hinttext: 'Enter your Prompt',
                          isPromptfield: true,
                          validatorcallback: ValidationBuilder()
                              .minLength(10)
                              .maxLength(500)
                              .build(),
                        ),
                        const SizedBox(height: 25),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: double.infinity,
                          child: ElevatedButton(
                            style: commonButtonStyle().copyWith(
                              backgroundColor: WidgetStateProperty.all(
                                isLoading ? Colors.grey : Colors.black,
                              ),
                              shape: WidgetStateProperty.all(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              padding: WidgetStateProperty.all(
                                const EdgeInsets.symmetric(
                                    vertical: 14, horizontal: 20),
                              ),
                            ),
                            onPressed: () {
                              if (_foam.currentState!.validate() && !isLoading) {
                                createPrompt(
                                  titleController.text.trim(),
                                  promptTextController.text.trim(),
                                );
                              }
                            },
                            child: Text(
                              isLoading ? "Submitting..." : "Submit Prompt",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  /// Cross Button (Top Right of Card)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: IconButton(
                      icon: const Icon(Icons.close,
                          color: Colors.black54, size: 28),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
