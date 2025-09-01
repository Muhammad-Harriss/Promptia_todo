import 'package:flutter/material.dart';

class PromptInput extends StatelessWidget {
  final String label, hinttext;
  final bool isPromptfield;
  final TextEditingController controller;
  final  validatorcallback;
  const PromptInput({super.key, required this.label , required this.hinttext, this.isPromptfield = false, required this.controller, required this.validatorcallback});

  @override
  Widget build(BuildContext context) {
    return  TextFormField(
      validator: validatorcallback,
      controller: controller,
      minLines: isPromptfield ? 6 :1,
      maxLines: isPromptfield ? 10 :1,
      maxLength: isPromptfield ? 500 : 20,
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20)
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(width: 2.5)
        ),
        label: Text(label),
        hintText: hinttext
      ),
      
    );
  }
}