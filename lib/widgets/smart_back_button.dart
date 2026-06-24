import 'package:flutter/material.dart';

class SmartBackButton extends StatelessWidget {
  const SmartBackButton({super.key, this.fallback});

  final VoidCallback? fallback;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Back',
      icon: const Icon(Icons.arrow_back_rounded),
      onPressed: () {
        final navigator = Navigator.of(context);
        if (navigator.canPop()) {
          navigator.pop();
          return;
        }

        fallback?.call();
      },
    );
  }
}
