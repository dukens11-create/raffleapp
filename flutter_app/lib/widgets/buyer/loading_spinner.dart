import 'package:flutter/material.dart';

class LoadingSpinner extends StatelessWidget {
  final String? message;

  const LoadingSpinner({
    super.key,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667eea)),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: const TextStyle(
                color: Color(0xFF64748b),
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
