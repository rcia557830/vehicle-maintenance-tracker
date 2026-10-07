import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/workspace.dart';

class CloudSetupScreen extends StatelessWidget {
  const CloudSetupScreen({super.key, this.message});
  final String? message;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 580),
          child: Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const IconBadge(Icons.cloud_outlined, size: 56),
                const SizedBox(height: 24),
                Text(
                  'Your garage. Connected.',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Motorcare is ready for Supabase. Finish the one-time project setup to sign in and manage your vehicles across devices.',
                ),
                const SizedBox(height: 24),
                const Text(
                  '1. Run the SQL migration in your Supabase project.\n\n2. Copy config/supabase.example.json to config/supabase.json and add your project URL and publishable key.\n\n3. Restart the app using the command below.',
                ),
                const SizedBox(height: 20),
                const SelectableText(
                  'flutter run -d chrome --web-port=8080 --dart-define-from-file=config/supabase.json',
                  style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
                const SizedBox(height: 20),
                if (message != null)
                  Text(
                    message!,
                    style: const TextStyle(color: AppColors.muted),
                  ),
                const SizedBox(height: 16),
                const Text(
                  'Full instructions: SUPABASE_SETUP.md\nYour previous local records remain available for import after sign-in.',
                  style: TextStyle(color: AppColors.muted),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
