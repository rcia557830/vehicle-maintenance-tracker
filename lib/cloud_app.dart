import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'database/supabase_repository.dart';
import 'main.dart';
import 'providers/maintenance_provider.dart';
import 'screens/auth_screen.dart';
import 'screens/cloud_setup_screen.dart';
import 'services/notification_service.dart';

class CloudApp extends StatefulWidget {
  const CloudApp({
    super.key,
    this.client,
    this.setupMessage,
    this.notificationService,
  });
  final SupabaseClient? client;
  final String? setupMessage;
  final NotificationService? notificationService;
  @override
  State<CloudApp> createState() => _CloudAppState();
}

class _CloudAppState extends State<CloudApp> {
  StreamSubscription<AuthState>? subscription;
  Session? session;
  bool recovery = false;
  late final NotificationService notifications;
  @override
  void initState() {
    super.initState();
    notifications = widget.notificationService ?? NotificationService();
    session = widget.client?.auth.currentSession;
    subscription = widget.client?.auth.onAuthStateChange.listen(
      (state) {
        if (!mounted) return;
        if (state.session == null) {
          unawaited(
            notifications.synchronize([], false).catchError((Object _) {}),
          );
        }
        setState(() {
          session = state.session;
          if (state.event == AuthChangeEvent.passwordRecovery) recovery = true;
          if (session == null) recovery = false;
        });
      },
      onError: (Object _) {
        // The SDK retries token refresh. Keep the login screen responsive offline.
      },
    );
  }

  @override
  void dispose() {
    subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.client == null) {
      return VehicleMaintenanceApp(
        home: CloudSetupScreen(message: widget.setupMessage),
      );
    }
    if (session == null || recovery) {
      return VehicleMaintenanceApp(
        key: ValueKey(recovery ? 'recovery' : 'signed-out'),
        home: AuthScreen(
          client: widget.client!,
          recovery: recovery,
          onRecovered: () => setState(() => recovery = false),
        ),
      );
    }
    // Replacing the entire navigator removes open record/form routes on logout.
    return ChangeNotifierProvider(
      key: ValueKey(session!.user.id),
      create: (_) => MaintenanceProvider(
        SupabaseRepository(widget.client!),
        notifications,
      ),
      child: const VehicleMaintenanceApp(),
    );
  }
}
