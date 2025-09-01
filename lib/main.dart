import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supabase_todo/routes/pages.dart';
import 'package:supabase_todo/routes/routes_name.dart';
import 'package:supabase_todo/utils/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: "https://hmnfkhuliwtatoesamzl.supabase.co",
    anonKey:
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhtbmZraHVsaXd0YXRvZXNhbXpsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTU2ODQ3MDQsImV4cCI6MjA3MTI2MDcwNH0.G4FdXdg1Y4_vayJ3qfmVVGc0I20kogkSfW22Z0Z4LWM",
  );

  //restore a saved session
  final hasSession = await SupabaseService.tryRestoreSession();

  //listen auth event
  SupabaseService.listenAuthChanges();

  runApp(MyApp(
    initialRoute: hasSession ? RoutesName.home : RoutesName.login,
  ));
}

class MyApp extends StatelessWidget {
  final String initialRoute;
  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: SupabaseService.navigatorKey, // for navigation in listener
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
