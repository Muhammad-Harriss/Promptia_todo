import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:form_validator/form_validator.dart';
import 'package:supabase_todo/controller/auth_controller.dart';
import 'package:supabase_todo/routes/routes_name.dart';
import 'package:supabase_todo/widgets/auth_input.dart';
import 'package:supabase_todo/widgets/buttonstyle.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController(text: '');
  final TextEditingController emailController = TextEditingController(text: '');
  final TextEditingController passwordController =
      TextEditingController(text: '');

  final AuthController authController = AuthController();
  bool signupLoading = false;

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
                    child: Text('Create your account'),
                  ),
                  const SizedBox(height: 20),

                  AuthInput(
                    label: 'Name',
                    hinttext: 'Enter your Name',
                    validatorCallback:
                        ValidationBuilder().minLength(3).maxLength(50).build(),
                    controller: nameController,
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
                    onPressed: () async {
                      if (_formKey.currentState!.validate() && !signupLoading) {
                        setState(() => signupLoading = true);

                        final success = await authController.signup(
                          nameController.text.trim(),
                          emailController.text.trim(),
                          passwordController.text.trim(),
                        );

                        setState(() => signupLoading = false);

                        if (success && mounted) {
                          Navigator.pushReplacementNamed(
                              context, RoutesName.home);
                        } else {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text("Signup failed. Try again.")),
                            );
                          }
                        }
                      }
                    },
                    style: commonButtonStyle(),
                    child: Text(signupLoading ? "Loading..." : 'Sign Up'),
                  ),
                  const SizedBox(height: 10),
                  const Text('----OR----'),
                  const SizedBox(height: 10),
                  Text.rich(
                    TextSpan(
                      text: "Already have an Account ? ",
                      children: [
                        TextSpan(
                          text: 'Login',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              Navigator.pushNamed(context, RoutesName.login);
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
