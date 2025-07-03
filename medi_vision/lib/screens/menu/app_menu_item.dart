import 'package:flutter/material.dart';

class AppMenuItem {
  final String title;
  final IconData icon;
  final Function() onTap;

  AppMenuItem({
    required this.title,
    required this.icon,
    required this.onTap,
  });
}