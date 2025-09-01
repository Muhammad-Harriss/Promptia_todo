// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

ButtonStyle commonButtonStyle() => ButtonStyle(
  backgroundColor: MaterialStateProperty.all<Color>(Colors.black),
  foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
  minimumSize: MaterialStateProperty.all<Size>(
    const Size.fromHeight(40.0),
  ),
);
