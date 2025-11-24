import 'package:flutter/material.dart';

class ScreenToModal {
  static void show({
    required BuildContext context,
    required Widget child,
    double height = 0.9,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * height,
        margin: const EdgeInsets.all(20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Scaffold(
            body: child,
          ),
        ),
      ),
    );
  }
}