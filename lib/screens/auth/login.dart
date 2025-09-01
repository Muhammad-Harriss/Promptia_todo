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
  final GlobalKey<FormState> _foam = GlobalKey<FormState>();
  final TextEditingController emailcontroller = TextEditingController(text: '');
  final TextEditingController passwordcontroller =
      TextEditingController(text: '');
  final AuthController authController = AuthController();

  bool loginLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Form(
              key: _foam,
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      'Promptia',
                      style: const TextStyle(
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
                    controller: emailcontroller,
                  ),
                  const SizedBox(height: 20),
                  AuthInput(
                    label: 'Password',
                    hinttext: "Enter your Password",
                    isPasswordfield: true,
                    controller: passwordcontroller,
                    validatorCallback: ValidationBuilder()
                        .minLength(6)
                        .maxLength(12)
                        .build(),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      if (_foam.currentState!.validate() && !loginLoading) {
                        setState(() => loginLoading = true);

                        final success = await authController.login(
                          emailcontroller.text.trim(),
                          passwordcontroller.text.trim(),
                        );

                        setState(() => loginLoading = false);

                        if (success && mounted) {
                          Navigator.pushReplacementNamed(
                              context, RoutesName.home);
                        } else {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text("Login failed. Try again.")),
                            );
                          }
                        }
                      }
                    },
                    style: commonButtonStyle(),
                    child: Text(loginLoading ? "Loading..." : 'Login'),
                  ),
                  const SizedBox(height: 10),
                  const Text('----OR----'),
                  const SizedBox(height: 10),
                  Text.rich(
                    TextSpan(
                      text: "Don't have an Account ? ",
                      children: [
                        TextSpan(
                          text: 'SignUp',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              Navigator.pushNamed(context, RoutesName.signup);
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
