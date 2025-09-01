// ignore_for_file: unnecessary_cast, unnecessary_type_check

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supabase_todo/features/add_prompts.dart';
import 'package:supabase_todo/model/prompt_model.dart';
import 'package:supabase_todo/screens/auth/login.dart';
import 'package:supabase_todo/widgets/prompt_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isLoading = false;
  List<Prompt> prompts = [];

  @override
  void initState() {
    super.initState();
    fetchPrompts();
  }


  /// Fetch prompts from Supabase (owner or collaborator)
Future<void> fetchPrompts() async {
  setState(() => isLoading = true);

  try {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) throw Exception("No user logged in");

    // Call the RPC function
    final response = await Supabase.instance.client
        .rpc('get_user_prompts', params: {'uid': user.id});

    final allPrompts = <Prompt>[];

    if (response is List) {
      // Each item is a PostgrestMap (Map<String, dynamic>)
      for (final item in response) {
        if (item is Map<String, dynamic>) {
          allPrompts.add(Prompt(
            id: item['id'] as String,
            title: item['title'] as String,
            prompt: item['prompt'] as String,
            ownerId: item['owner_id'] as String,
            createdAt: DateTime.parse(item['created_at'] as String),
          ));
        }
      }
    }

    if (!mounted) return;
    setState(() => prompts = allPrompts);
  } catch (e, st) {
    debugPrint("Error fetching prompts via RPC: $e\n$st");
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error fetching prompts: $e")),
        );
      });
    }
  } finally {
    if (mounted) setState(() => isLoading = false);
  }
}


  /// Confirm logout dialog
  Future<void> _confirmLogout() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Logout"),
          content: const Text("Are you sure you want to log out?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
              ),
              child: const Text("Yes, Logout"),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      _logout();
    }
  }

  /// Logout
  Future<void> _logout() async {
    try {
      await Supabase.instance.client.auth.signOut();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const Login()),
        (route) => false,
      );
    } catch (e) {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Failed to log out: $e")),
            );
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Promptia',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _confirmLogout,
          ),
        ],
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.deepPurple,
                Color.fromARGB(255, 219, 207, 207),
                Colors.deepPurple,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : prompts.isEmpty
              ? const Center(
                  child: Text(
                    "No prompts found 📝",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: prompts.length,
                  itemBuilder: (context, index) {
                    final prompt = prompts[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: PromptCard(
                        prompt: prompt,
                        onRefresh: fetchPrompts,
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.deepPurple,
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddPrompts(),
            ),
          );

          if (result == true) {
            fetchPrompts();
          }
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          "Add Prompt",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
