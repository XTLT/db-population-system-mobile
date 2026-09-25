import 'package:flutter/material.dart';


class OnboardingStepWidget extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Widget? demo;

  const OnboardingStepWidget({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    this.demo,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.7),
                ),
            textAlign: TextAlign.center,
          ),
          if (demo != null) ...[
            const SizedBox(height: 24),
            demo!,
          ],
        ],
      ),
    );
  }
}


class OnboardingStep {
  final String title;
  final String description;
  final IconData icon;
  final Widget? demo;

  const OnboardingStep({
    required this.title,
    required this.description,
    required this.icon,
    this.demo,
  });
}
