import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../database/supabase_repository.dart';
import '../providers/maintenance_provider.dart';
import 'workspace.dart';

class CloudAccountPanel extends StatefulWidget {
  const CloudAccountPanel({super.key});
  @override
  State<CloudAccountPanel> createState() => _CloudAccountPanelState();
}

class _CloudAccountPanelState extends State<CloudAccountPanel> {
  bool busy = false;
  String? message;
  Future<void> importGarage() async {
    final p = context.read<MaintenanceProvider>();
    final db = p.db as SupabaseRepository;
    setState(() {
      busy = true;
      message = null;
    });
    try {
      final count = await db.importLocalData();
      await p.load();
      await p.syncReminders();
      message = count == 0
          ? 'These local records were already imported.'
          : '$count ${count == 1 ? 'vehicle' : 'vehicles'} imported. Your local originals are unchanged.';
    } on StateError catch (e) {
      message = e.message;
    } on PostgrestException catch (e) {
      message = e.code == 'P0001' ? e.message : 'Import failed. Check your connection and database setup. Local data is unchanged.';
    } catch (_) {
      message = 'Import failed. Check your connection and try again. Local data is unchanged.';
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<MaintenanceProvider>();
    if (p.db is! SupabaseRepository) return const SizedBox.shrink();
    final db = p.db as SupabaseRepository;
    return FormSection(
      title: 'Cloud account',
      subtitle: db.accountEmail ?? 'Signed in',
      icon: Icons.cloud_done_outlined,
      children: [
        const Text(
          'Your garage is saved in Supabase and available wherever you sign in. An internet connection is required to load and save changes.',
        ),
        const SizedBox(height: 18),
        const Text(
          'Bring your previous garage',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        const Text(
          'Import records from this device into an empty cloud garage. For Chrome, use the same browser, address and port as your old app. Local originals are kept.',
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: busy || p.vehicles.isNotEmpty ? null : importGarage,
          icon: const Icon(Icons.cloud_upload_outlined, size: 18),
          label: Text(busy ? 'Please wait…' : 'Import local garage'),
        ),
        if (message != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(message!),
          ),
        const SizedBox(height: 18),
        const Divider(),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: busy
              ? null
              : () async {
                  setState(() => busy = true);
                  try {
                    // Clear Android reminders before another account can use this device.
                    try {
                      await p.notifications.synchronize([], false);
                    } catch (_) {}
                    await db.client.auth.signOut();
                  } catch (_) {
                    if (mounted) {
                      setState(() {
                        busy = false;
                        message = 'Unable to sign out. Please try again.';
                      });
                    }
                  }
                },
          icon: const Icon(Icons.logout, size: 18),
          label: const Text('Sign out'),
        ),
      ],
    );
  }
}
