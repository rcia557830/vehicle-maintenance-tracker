import 'dart:async';

import 'package:flutter/material.dart';

import 'widgets/feedback.dart';

import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'cloud_app.dart';
import 'database/database_platform.dart';
import 'services/cloud_config.dart';
import 'providers/maintenance_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/maintenance_history_screen.dart';
import 'screens/vehicle_screen.dart';
import 'screens/expenses_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/tires_screen.dart';
import 'widgets/common.dart';
import 'widgets/vehicle_switcher.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  configureDatabase();
  var message = CloudConfig.validate(CloudConfig.url, CloudConfig.key);
  SupabaseClient? client;
  if (message == null) {
    try {
      await Supabase.initialize(
        url: CloudConfig.url,
        publishableKey: CloudConfig.key,
      );
      client = Supabase.instance.client;
    } catch (_) {
      message = 'Supabase could not start. Check your configuration and restart the app.';
    }
  }
  runApp(CloudApp(client: client, setupMessage: message));
}

class VehicleMaintenanceApp extends StatelessWidget {
  const VehicleMaintenanceApp({super.key, this.home = const MainScreen()});
  final Widget home;
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Vehicle Maintenance Tracker',
    debugShowCheckedModeBanner: false,
    theme: buildAppTheme(),
    home: home,
  );
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  int index = 0;
  Timer? timer;
  static const titles = [
    'Dashboard',
    'Maintenance',
    'Garage',
    'Expenses',
    'Settings',
    'Tires',
  ];
  static const icons = [
    Icons.grid_view_outlined,
    Icons.build_outlined,
    Icons.garage_outlined,
    Icons.payments_outlined,
    Icons.settings_outlined,
    Icons.tire_repair,
  ];
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final p = context.read<MaintenanceProvider>();
      if (p.loading) await p.load();
      await p.syncReminders();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final p = context.read<MaintenanceProvider>();
      unawaited(p.load().then((_) => p.syncReminders()));
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<MaintenanceProvider>();
    final wide = MediaQuery.sizeOf(context).width >= 1000;
    final pages = [
      const DashboardScreen(),
      const MaintenanceHistoryScreen(),
      const VehicleScreen(),
      const ExpensesScreen(),
      const SettingsScreen(),
      const TiresScreen(),
    ];
    final page = p.loading
        ? const LoadingState()
        : p.error != null && index != 4
        ? Center(
            child: SingleChildScrollView(
              child: EmptyState(
                icon: Icons.cloud_off_outlined,
                title: 'Unable to open your garage',
                message: p.error!,
                label: 'Try again',
                action: p.refresh,
              ),
            ),
          )
        : KeyedSubtree(
            key: ValueKey('${p.vehicle?.id}:$index'),
            child: pages[index],
          );
    Widget brand({bool dark = false}) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(11),
          ),
          child: const Icon(
            Icons.directions_car_filled_rounded,
            color: Colors.white,
            size: 23,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Motorcare',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -.5,
                color: dark ? Colors.white : AppColors.ink,
              ),
            ),
            Text(
              'VEHICLE MAINTENANCE',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 8,
                letterSpacing: 1.5,
                color: dark ? const Color(0xff9bb7b9) : AppColors.muted,
              ),
            ),
          ],
        ),
      ],
    );
    return Scaffold(
      appBar: wide
          ? null
          : AppBar(
              title: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: brand(),
              ),
              toolbarHeight: 64,
              actions: [
                IconButton(
                  tooltip: 'Tire care',
                  onPressed: () =>
                      openScreen(context, const TiresScreen(standalone: true)),
                  icon: const Icon(Icons.tire_repair),
                ),
                IconButton(
                  tooltip: 'Preferences',
                  onPressed: () => setState(() => index = 4),
                  icon: const Icon(Icons.tune_rounded),
                ),
                const SizedBox(width: 8),
              ],
            ),
      body: SafeArea(
        child: Row(
          children: [
            if (wide)
              Padding(
                padding: const EdgeInsets.all(12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: NavigationRail(
                    extended: true,
                    minExtendedWidth: 208,
                    backgroundColor: AppColors.sidebar,
                    indicatorColor: const Color(0xff223d55),
                    selectedIconTheme: const IconThemeData(
                      color: Color(0xffa5e4d7),
                      size: 21,
                    ),
                    unselectedIconTheme: const IconThemeData(
                      color: Color(0xff9bb7b9),
                      size: 21,
                    ),
                    selectedLabelTextStyle: const TextStyle(
                      fontFamily: 'Roboto',
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    unselectedLabelTextStyle: const TextStyle(
                      fontFamily: 'Roboto',
                      color: Color(0xffafc3c5),
                      fontSize: 13,
                    ),
                    leading: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 26, 14, 44),
                      child: brand(dark: true),
                    ),
                    selectedIndex: index,
                    onDestinationSelected: (value) =>
                        setState(() => index = value),
                    destinations: [
                      for (var i = 0; i < titles.length; i++)
                        NavigationRailDestination(
                          icon: Icon(icons[i]),
                          label: Text(titles[i]),
                        ),
                    ],
                    trailing: Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          width: 184,
                          margin: const EdgeInsets.only(bottom: 24),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xff1b304c),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.cloud_outlined,
                                color: Color(0xff9edbd0),
                                size: 20,
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Your personal garage',
                                style: TextStyle(
                                  fontFamily: 'Roboto',
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                p.db.isCloud
                                    ? 'Private records, connected across your devices.'
                                    : 'Local workspace preview',
                                style: const TextStyle(
                                  fontFamily: 'Roboto',
                                  color: Color(0xffafc3c5),
                                  fontSize: 11,
                                  height: 1.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            Expanded(
              child: Column(
                children: [
                  if (wide)
                    Container(
                      height: 76,
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          bottom: BorderSide(color: AppColors.line),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Text(
                            'My garage',
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Icon(
                              Icons.chevron_right,
                              size: 16,
                              color: AppColors.muted,
                            ),
                          ),
                          Text(
                            titles[index],
                            style: const TextStyle(
                              fontFamily: 'Roboto',
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            tooltip: 'Refresh garage',
                            onPressed: p.loading ? null : p.refresh,
                            icon: const Icon(Icons.refresh_rounded, size: 20),
                          ),
                          const SizedBox(width: 12),
                          if (p.vehicle != null)
                            const SizedBox(
                              width: 352,
                              child: VehicleSwitcher(compact: true),
                            ),
                          const SizedBox(width: 12),
                          IconButton.filledTonal(
                            tooltip: 'Account settings',
                            onPressed: () => setState(() => index = 4),
                            icon: const Icon(Icons.person_outline, size: 20),
                          ),
                        ],
                      ),
                    )
                  else
                    const VehicleSwitcher(),
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1280),
                        child: page,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: index < 5 ? index : 2,
              onDestinationSelected: (value) => setState(() => index = value),
              destinations: [
                for (var i = 0; i < 5; i++)
                  NavigationDestination(icon: Icon(icons[i]), label: titles[i]),
              ],
            ),
    );
  }
}
