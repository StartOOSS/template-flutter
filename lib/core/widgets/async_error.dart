import 'package:flutter/material.dart';

class AsyncError extends StatelessWidget {
  const AsyncError({required this.details, super.key});

  final FlutterErrorDetails details;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  size: 48, color: Colors.redAccent),
              const SizedBox(height: 12),
              Text(
                'Something went wrong',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(details.exceptionAsString()),
            ],
          ),
        ),
      ),
    );
  }
}
