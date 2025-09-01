import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supabase_todo/features/helper.dart';
import 'package:supabase_todo/model/prompt_model.dart';
import 'package:supabase_todo/screens/task_detail_Screen.dart';
import 'package:supabase_todo/utils/supabase_service.dart'; 
import 'package:url_launcher/url_launcher.dart'; 

class PromptCard extends StatelessWidget {
  final Prompt prompt;
  final VoidCallback onRefresh; 

  const PromptCard({super.key, required this.prompt, required this.onRefresh});

  
  Future<List<_AttachmentFile>> _fetchAttachments() async {
    final storage = Supabase.instance.client.storage.from('task_files');
    final folder = prompt.id!.toString();
    try {
      final items = await storage.list(path: folder);
      return items.map((f) {
        final path = '$folder/${f.name}';
        final url = storage.getPublicUrl(path);
        return _AttachmentFile(name: f.name, path: path, url: url);
      }).toList();
    } catch (_) {
      return <_AttachmentFile>[]; // fail silent => no attachments
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  bool _isImage(String name) {
    final n = name.toLowerCase();
    return n.endsWith('.png') || n.endsWith('.jpg') || n.endsWith('.jpeg') || n.endsWith('.gif') || n.endsWith('.webp');
    }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      shadowColor: Colors.black26,
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// ---------- Header ----------
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    prompt.title?.trim().isNotEmpty == true
                        ? prompt.title!
                        : "Untitled",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  tooltip: "Copy Prompt",
                  onPressed: () {
                    if (prompt.prompt != null) {
                      Clipboard.setData(ClipboardData(text: prompt.prompt!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("✅ Prompt copied!")),
                      );
                    }
                  },
                  icon: const Icon(Icons.copy, color: Colors.grey),
                ),
              ],
            ),

            /// ---------- Date ----------
            Text(
              formatDateTime(prompt.createdAt),
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),

            const SizedBox(height: 10),

            /// ---------- Prompt content ----------
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                prompt.prompt ?? "No Prompt",
                style: const TextStyle(fontSize: 16, height: 1.4),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            const SizedBox(height: 12),

            /// ---------- Action buttons ----------
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                /// Invite
                _ActionButton(
                  icon: Icons.person_add,
                  label: "Invite",
                  color: Colors.green,
                  onPressed: () => _showInviteDialog(context),
                ),

                const SizedBox(width: 8),

                /// Attach
                _ActionButton(
                  icon: Icons.attach_file,
                  label: "Attach",
                  color: Colors.orange,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TaskDetailScreen(prompt: prompt),
                      ),
                    );
                  },
                ),

                const SizedBox(width: 8),

                /// Edit
                _ActionButton(
                  icon: Icons.edit,
                  label: "Edit",
                  color: Colors.blue,
                  onPressed: () => _showEditDialog(context),
                ),

                const SizedBox(width: 8),

                /// Delete
                _ActionButton(
                  icon: Icons.delete,
                  label: "Delete",
                  color: Colors.red,
                  onPressed: () => _showDeleteDialog(context),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ---------- NEW: Attachments section (always shows heading) ----------
            const Text(
              "Attachments",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            FutureBuilder<List<_AttachmentFile>>(
              future: _fetchAttachments(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  // Minimal inline loader to avoid changing layout elsewhere
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                }

                final files = snapshot.data ?? const <_AttachmentFile>[];
                if (files.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.only(bottom: 6),
                    child: Text(
                      "No attachments yet.",
                      style: TextStyle(color: Colors.black54),
                    ),
                  );
                }

                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: files.map((f) {
                    return InkWell(
                      onTap: () => _openUrl(f.url),
                      child: Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey.shade200,
                        ),
                        child: _isImage(f.name)
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  f.url,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      const Icon(Icons.broken_image),
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.insert_drive_file, size: 36),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                    child: Text(
                                      f.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// ---------------- Invite Dialog ----------------
  void _showInviteDialog(BuildContext context) {
    final emailController = TextEditingController();
    bool isInviting = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text("Invite User"),
            content: TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: "Enter user email",
                hintText: "example@email.com",
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: isInviting
                    ? null
                    : () async {
                        final email = emailController.text.trim();
                        if (email.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("⚠ Please enter an email")),
                          );
                          return;
                        }
                        setState(() => isInviting = true);

                        final error = await PromptCollaboration.inviteUserToPrompt(
                          email: email,
                          promptId: prompt.id!.toString(),
                        );

                        setState(() => isInviting = false);
                        if (!context.mounted) return;

                        if (error == null) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(" Invitation sent to $email")),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(" Error: $error")),
                          );
                          // ignore: avoid_print
                          print(error);
                        }
                      },
                child: isInviting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text("Send Invite"),
              ),
            ],
          ),
        );
      },
    );
  }

  /// ---------------- Edit Dialog ----------------
  void _showEditDialog(BuildContext context) {
    final titleController = TextEditingController(text: prompt.title);
    final promptController = TextEditingController(text: prompt.prompt);
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: const Text("Edit Prompt"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: "Title"),
                ),
                TextField(
                  controller: promptController,
                  decoration: const InputDecoration(labelText: "Prompt"),
                  maxLines: 3,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        setState(() => isSaving = true);
                        try {
                          await Supabase.instance.client
                              .from("prompts")
                              .update({
                                "title": titleController.text,
                                "prompt": promptController.text,
                              })
                              .eq("id", prompt.id!);

                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("✅ Prompt updated")),
                            );
                          }
                          onRefresh();
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("❌ Error: $e")),
                          );
                          // ignore: avoid_print
                          print('$e');
                        } finally {
                          setState(() => isSaving = false);
                        }
                      },
                child: isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text("Save"),
              ),
            ],
          );
        });
      },
    );
  }

  /// ---------------- Delete Dialog ----------------
  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: const Text("Are you sure you want to delete this prompt? This cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await Supabase.instance.client.from("prompts").delete().eq("id", prompt.id!);

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("🗑 Prompt deleted")),
                  );
                }
                onRefresh();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("❌ Error deleting: $e")),
                );
                // ignore: avoid_print
                print('$e');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      icon: Icon(icon, color: color),
      label: Text(label),
      onPressed: onPressed,
    );
  }
}

// ---------- NEW: tiny data holder ----------
class _AttachmentFile {
  final String name;
  final String path;
  final String url;
  _AttachmentFile({required this.name, required this.path, required this.url});
}
