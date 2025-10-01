import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_todo/routes/pages.dart';
import 'package:supabase_todo/routes/routes_name.dart';
import 'package:supabase_todo/utils/supabase_service.dart';
import 'package:supabase_todo/controller/auth_controller.dart';

/// -------------------------
/// Background message handler
/// -------------------------
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
}

/// -------------------------
/// Main entry point
/// -------------------------
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  if (identical(0, 0.0)) {
    // Web
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyD8-BI128vEK9a3q2Kemjv-ElrMFtIO2pE",
        appId: "1:660612640173:web:3ed89038bed33c9f104524",
        messagingSenderId: "660612640173",
        projectId: "promptia-332d0",
        authDomain: "promptia-332d0.firebaseapp.com",
        storageBucket: "promptia-332d0.firebasestorage.app",
        measurementId: "G-6SQ02BPCNT",
      ),
    );
  } else {
    await Firebase.initializeApp();
  }

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Request notification permissions
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  // Initialize Supabase
  await Supabase.initialize(
    url: "https://hmnfkhuliwtatoesamzl.supabase.co",
    anonKey:
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhtbmZraHVsaXd0YXRvZXNhbXpsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTU2ODQ3MDQsImV4cCI6MjA3MTI2MDcwNH0.G4FdXdg1Y4_vayJ3qfmVVGc0I20kogkSfW22Z0Z4LWM",
  );

  // Restore session
  final hasSession = await SupabaseService.tryRestoreSession();

  // Listen auth changes
  SupabaseService.listenAuthChanges();

  // If user is already logged in, save/update FCM token
  if (hasSession && SupabaseService.supabase.auth.currentUser != null) {
    final authController = AuthController();
    await authController.login(
        SupabaseService.supabase.auth.currentUser!.email!,
        ''); // Password is ignored if session exists
  }

  // Listen to prompt changes
  listenForPromptChanges();

  runApp(MyApp(initialRoute: hasSession ? RoutesName.home : RoutesName.login));
}

/// -------------------------
/// Listen for prompt changes
/// -------------------------
void listenForPromptChanges() {
  final supabase = Supabase.instance.client;

  supabase.channel('prompts')
      .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'prompts',
        callback: (payload) {
          final newPrompt = payload.newRecord;
          callSendNotification(
            type: 'assignment',
            promptId: newPrompt['id'],
            userId: newPrompt['assigned_user_id'],
          );
        },
      )
      .onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'prompts',
        callback: (payload) {
          final updatedPrompt = payload.newRecord;
          callSendNotification(
            type: 'update',
            promptId: updatedPrompt['id'],
            userId: updatedPrompt['updated_by'],
          );
        },
      )
      .subscribe();
}

/// -------------------------
/// Call Supabase Edge Function
/// -------------------------
Future<void> callSendNotification({
  required String type,
  required String promptId,
  required String userId,
}) async {
  const functionUrl =
      'https://hmnfkhuliwtatoesamzl.functions.supabase.co/send-notification';

  final body = jsonEncode({
    'type': type,
    'prompt_id': promptId,
    'user_id': userId,
  });

  final res = await http.post(
    Uri.parse(functionUrl),
    headers: {'Content-Type': 'application/json'},
    body: body,
  );

  if (res.statusCode == 200) {
    print('Notification sent: ${res.body}');
  } else {
    print('Failed to send notification: ${res.body}');
  }
}

/// -------------------------
/// MyApp Widget
/// -------------------------
class MyApp extends StatelessWidget {
  final String initialRoute;
  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: SupabaseService.navigatorKey,
      debugShowCheckedModeBanner: false,
      routes: Pages.routes,
      title: 'Promptia',
      theme: ThemeData(
        colorScheme: const ColorScheme.light(primary: Colors.black),
        textTheme: GoogleFonts.specialEliteTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
      initialRoute: initialRoute,
    );
  }
}
