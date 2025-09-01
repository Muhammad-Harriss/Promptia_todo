import 'package:flutter/material.dart';
import 'package:supabase_todo/routes/routes_name.dart';
import 'package:supabase_todo/screens/Home_Screen.dart';
import 'package:supabase_todo/screens/auth/login.dart';
import 'package:supabase_todo/screens/auth/signup.dart';

class Pages {
  static final Map<String, WidgetBuilder> routes = {
    RoutesName.home: (context) => const HomeScreen(),
    RoutesName.login: (context) => const Login(),
    RoutesName.signup: (context) => const Signup(),
  };
}
