import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habits/api_client.dart';
import 'package:habits/expenses_page.dart';
import 'package:habits/login_view.dart';
import 'package:habits/service_locator.dart';
import 'package:habits/providers/auth_provider.dart';
import 'package:habits/providers/settings_provider.dart';
import 'package:habits/settings_page.dart';
import 'package:habits/theme/mono_theme.dart';
import 'package:native_glass_navbar/native_glass_navbar.dart';
import 'constants.dart' as Constants;
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupServiceLocator();
  // make flutter draw behind navigation bar
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  runApp(const ProviderScope(child: MainApp()));
}

class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return MaterialApp(
      theme: monoTheme(dark: false),
      darkTheme: monoTheme(dark: true, oled: settings.oledDarkMode),
      themeMode: settings.themeMode == ThemeMode.dark
          ? ThemeMode.dark
          : ThemeMode.system,
      // debugShowCheckedModeBanner: false,
      home: const MainScreen(),
    );
  }
}

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return authState.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: const Text(Constants.appName)),
        body: Center(child: Text('Error: $error')),
      ),
      data: (isLoggedIn) {
        if (!isLoggedIn) {
          return LoginScreen(
            onLoginSuccess: () {
              ref.invalidate(authProvider);
            },
          );
        }

        var fallbackNavbar = NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (value) => setState(() {
            _selectedIndex = value;
          }),
          maintainBottomViewPadding: true,
          destinations: [
            NavigationDestination(
              icon: Icon(Icons.attach_money_rounded),
              label: 'Expenses',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_rounded),
              label: 'Settings',
            ),
          ],
        );

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            systemNavigationBarColor: Colors.transparent,
            systemNavigationBarContrastEnforced: false,
            systemStatusBarContrastEnforced: false,
            statusBarColor: Colors.transparent,
          ),
          child: Scaffold(
            bottomNavigationBar:
                (Constants.enableLiquidGlassBar
                        ? (
                            tabs: [
                              NativeGlassNavBarItem(
                                label: "Expenses",
                                symbol: "banknote",
                              ),
                              NativeGlassNavBarItem(
                                label: "Settings",
                                symbol: "gear",
                              ),
                            ],
                            actionButton: TabBarActionButton(
                              symbol: "plus",
                              onTap: () {
                                // showAddExpenseSheet(context);
                                // showCupertinoSheet(
                                //   context: context,
                                //   builder: (context) {
                                //     return AddExpenseSheet();
                                //   },
                                // );
                              },
                            ),
                            currentIndex: _selectedIndex,
                            onTap: (index) {
                              setState(() {
                                _selectedIndex = index;
                              });
                            },
                            fallback: fallbackNavbar,
                          )
                        : fallbackNavbar)
                    as Widget,
            body: [
              const ExpensesPage(),
              const SettingsScreen(),
            ][_selectedIndex],
          ),
        );
      },
    );
  }
}
