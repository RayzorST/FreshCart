import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CameraFAB extends StatelessWidget {
  const CameraFAB({super.key});

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, 15),
      child: FloatingActionButton(
        backgroundColor: Theme.of(context).colorScheme.primary,
        onPressed: () {
          context.push('/camera');
        },
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          Icons.camera_alt, 
          size: 28,
          color: Theme.of(context).colorScheme.onSurface,
          ),
      ),
    );
  }
}