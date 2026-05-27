import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';
import 'screens/home_page.dart';
import 'widgets/app_state_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://knmfoiaemghtsjdheafp.supabase.co',
    anonKey: 'sb_publishable_5pTxe4BMOB_jjl34I4hdXw_jjiQNEiY',
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final AppState _appState = AppState();
  bool _isDarkMode = true;

  @override
  void initState() {
    super.initState();
    // Initialize Supabase sync (fetches profile & starts real-time streams)
    _appState.initializeSupabaseSync();
  }

  void _toggleTheme() => setState(() => _isDarkMode = !_isDarkMode);

  @override
  Widget build(BuildContext context) {
    return AppStateProvider(
      state: _appState,
      child: ListenableBuilder(
        listenable: _appState,
        builder: (context, _) {
          return MaterialApp(
            title: 'Rizwana Freelancing App',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
            home: HomePage(
              onToggleTheme: _toggleTheme,
              isDarkMode: _isDarkMode,
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _appState.dispose();
    super.dispose();
  }
}
