import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:form_validator/form_validator.dart';
import 'package:supabase_todo/controller/auth_controller.dart';
import 'package:supabase_todo/routes/routes_name.dart';
import 'package:supabase_todo/widgets/auth_input.dart';
import 'package:supabase_todo/widgets/buttonstyle.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final AuthController authController = AuthController();

  bool loginLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate() || loginLoading) return;

    if (!mounted) return;
    setState(() => loginLoading = true);

    final success = await authController.login(
      emailController.text.trim(),
      passwordController.text.trim(),
    );

    if (!mounted) return;
    setState(() => loginLoading = false);

    if (success) {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, RoutesName.home);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Login failed. Try again.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      'Promptia',
                      style: TextStyle(
                          fontSize: 30, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Align(
                    alignment: Alignment.topLeft,
                    child: Text('Welcome back'),
                  ),
                  const SizedBox(height: 20),
                  AuthInput(
                    label: 'Email',
                    hinttext: 'Enter your Email',
                    validatorCallback: ValidationBuilder().email().build(),
                    controller: emailController,
                  ),
                  const SizedBox(height: 20),
                  AuthInput(
                    label: 'Password',
                    hinttext: "Enter your Password",
                    isPasswordfield: true,
                    controller: passwordController,
                    validatorCallback: ValidationBuilder()
                        .minLength(6)
                        .maxLength(12)
                        .build(),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _handleLogin,
                    style: commonButtonStyle(),
                    child: Text(loginLoading ? "Loading..." : 'Login'),
                  ),
                  const SizedBox(height: 10),
                  const Text('----OR----'),
                  const SizedBox(height: 10),
                  Text.rich(
                    TextSpan(
                      text: "Don't have an Account? ",
                      children: [
                        TextSpan(
                          text: 'SignUp',
                          style:
                              const TextStyle(fontWeight: FontWeight.bold),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              Navigator.pushNamed(
                                  context, RoutesName.signup);
                            },
                        ),
                      ],
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
