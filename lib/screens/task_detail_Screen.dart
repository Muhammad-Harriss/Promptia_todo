import 'dart:io' show File;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supabase_todo/model/prompt_model.dart';

class TaskDetailScreen extends StatefulWidget {
  final Prompt prompt;
  const TaskDetailScreen({super.key, required this.prompt});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final supabase = Supabase.instance.client;
  List<FileObject> files = [];
  bool loading = false;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    setState(() => loading = true);
    final folder = widget.prompt.id.toString();
    try {
      final result = await supabase.storage.from('task_files').list(path: folder);
      setState(() {
        files = result;
        loading = false;
      });
    } catch (e, st) {
      print("❌ Error loading files: $e\n$st"); // 👈 log to terminal
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load files: $e")),
      );
    }
  }

  Future<void> _uploadFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null) return;

    final file = result.files.single;
    final folder = widget.prompt.id.toString();
    final filePath = "$folder/${file.name}";

    try {
      if (kIsWeb) {
        await supabase.storage.from('task_files').uploadBinary(
              filePath,
              file.bytes!,
              fileOptions: const FileOptions(upsert: true),
            );
      } else {
        await supabase.storage.from('task_files').upload(
              filePath,
              File(file.path!),
              fileOptions: const FileOptions(upsert: true),
            );
      }
      _loadFiles();
    } catch (e, st) {
      print("❌ Upload error: $e\n$st"); // 👈 log to terminal
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Upload failed: $e")));
    }
  }

  String _getFileUrl(String path) {
    return supabase.storage.from('task_files').getPublicUrl(path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.prompt.title ?? "Task Detail")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(widget.prompt.prompt ?? ""),
          ),
          ElevatedButton.icon(
            onPressed: _uploadFile,
            icon: const Icon(Icons.upload),
            label: const Text("Attach File"),
          ),
          const Divider(),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : files.isEmpty
                    ? const Center(child: Text("No files attached yet."))
                    : ListView.builder(
                        itemCount: files.length,
                        itemBuilder: (_, i) {
                          final f = files[i];
                          final url = _getFileUrl("${widget.prompt.id}/${f.name}");
                          final isImage = f.name.toLowerCase().endsWith(".png") ||
                              f.name.toLowerCase().endsWith(".jpg") ||
                              f.name.toLowerCase().endsWith(".jpeg");

                          return ListTile(
                            leading: isImage
                                ? Image.network(url,
                                    width: 40, height: 40, fit: BoxFit.cover)
                                : const Icon(Icons.insert_drive_file),
                            title: Text(f.name),
                            trailing: IconButton(
                              icon: const Icon(Icons.open_in_new),
                              onPressed: () {
                                print("📂 Opening file: $url"); // 👈 debug print
                              },
                            ),
                          );
                        },
                      ),
          )
        ],
      ),
    );
  }
}
