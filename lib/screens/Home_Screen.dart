import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supabase_todo/features/add_prompts.dart';
import 'package:supabase_todo/model/prompt_model.dart';
import 'package:supabase_todo/screens/Analaytics/analaytics_dashbord_screen.dart';
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
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _waitForUserAndFetch();
  }

  Future<void> _waitForUserAndFetch() async {
    final supabase = Supabase.instance.client;
    const timeout = Duration(seconds: 10);
    const interval = Duration(milliseconds: 200);
    var elapsed = Duration.zero;

    while (supabase.auth.currentUser == null && elapsed < timeout) {
      await Future.delayed(interval);
      elapsed += interval;
    }

    if (supabase.auth.currentUser != null) {
      await fetchPrompts();
      _subscribeToRealtime();
    } else {
      debugPrint("No user session found, skipping fetchPrompts");
    }
  }

  Future<void> fetchPrompts() async {
    setState(() => isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception("No user logged in");

      final response = await Supabase.instance.client
          .rpc('get_user_prompts', params: {'uid': user.id});

      final allPrompts = <Prompt>[];

      if (response is List) {
        for (final item in response) {
          if (item is Map<String, dynamic>) {
            allPrompts.add(Prompt.fromJson(item));
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

  void _subscribeToRealtime() {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) return;

    _channel = supabase.channel('public:prompts')
      ..onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'prompts',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'owner_id',
          value: user.id,
        ),
        callback: (payload) => _handleRealtimeInsert(payload),
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'prompt_collaborators',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'user_id',
          value: user.id,
        ),
        callback: (payload) async {
          final record = Map<String, dynamic>.from(payload.newRecord);
          final promptId = record['prompt_id'] as String;
          final newPrompt = await supabase
              .from('prompts')
              .select()
              .eq('id', promptId)
              .maybeSingle();

          if (newPrompt != null && mounted) {
            setState(() {
              prompts.insert(0, Prompt.fromJson(newPrompt));
            });
          }
        },
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'prompts',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'owner_id',
          value: user.id,
        ),
        callback: (payload) => _handleRealtimeUpdate(payload),
      )
      ..subscribe();
  }

  void _handleRealtimeInsert(PostgresChangePayload payload) {
    final newRecord = Map<String, dynamic>.from(payload.newRecord);
    if (!mounted) return;

    setState(() {
      prompts.insert(0, Prompt.fromJson(newRecord));
    });
  }

  void _handleRealtimeUpdate(PostgresChangePayload payload) {
    final updatedRecord = Map<String, dynamic>.from(payload.newRecord);
    final index = prompts.indexWhere((p) => p.id == updatedRecord['id']);
    if (index != -1 && mounted) {
      setState(() {
        prompts[index] = Prompt.fromJson(updatedRecord);
      });
    }
  }

  @override
  void dispose() {
    if (_channel != null) {
      Supabase.instance.client.removeChannel(_channel!);
    }
    super.dispose();
  }

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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to log out: $e")),
          );
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
        leading: IconButton(
          icon: const Icon(Icons.bar_chart, color: Colors.white),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AnalyticsDashboard(),
              ),
            );
          },
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
                        onStatusChanged: (updatedPrompt) {
                          setState(() {
                            prompts[index] = updatedPrompt;
                          });
                        },
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
