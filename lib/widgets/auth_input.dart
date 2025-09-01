import 'package:flutter/material.dart';
import 'package:supabase_todo/utils/type_def.dart';

class AuthInput extends StatelessWidget {
  final String label, hinttext;
  final bool isPasswordfield;
  final  ValidatorCallback validatorCallback;
  final TextEditingController controller;
  const AuthInput({
    super.key,
    required this.label,
    required this.hinttext,
    required this.controller,
    this.isPasswordfield = false,
    required this.validatorCallback
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: isPasswordfield,
      validator: validatorCallback,

      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(width: 2.5),
          borderRadius: BorderRadius.circular(20),
        ),
        label: Text(label),
        hintText: hinttext,
      ),
    );
  }
}
