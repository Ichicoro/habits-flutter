import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart' as google_fonts;
import 'package:habits/api_client.dart';
import 'package:habits/expenses_page.dart';
import 'package:habits/login_view.dart';
import 'package:habits/service_locator.dart';
import 'package:habits/providers/auth_provider.dart';
import 'package:native_glass_navbar/native_glass_navbar.dart';
import 'constants.dart' as Constants;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupServiceLocator();
  runApp(const ProviderScope(child: MainApp()));
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    var themeData = ThemeData(
      useMaterial3: true,
      colorSchemeSeed: Colors.orange,
      brightness: Brightness.dark,
    );

    return MaterialApp(
      // theme: ThemeData(
      //   useMaterial3: true,
      //   colorSchemeSeed: Colors.orange,
      //   brightness: Brightness.dark,
      //   // or crimson
      //   textTheme: google_fonts.GoogleFonts.youngSerifTextTheme(
      //     Typography.englishLike2021.apply(
      //       fontSizeFactor: kIsWeb ? 1.2 : (Platform.isMacOS ? 1.0 : 1.2),
      //       bodyColor: themeData.colorScheme.onSurface,
      //       displayColor: themeData.colorScheme.onSurface,
      //     ),
      //   ),
      //   navigationBarTheme: const NavigationBarThemeData(height: 69),
      //   appBarTheme: AppBarTheme(
      //     centerTitle: true,
      //     titleTextStyle: TextStyle(
      //       fontFamily: 'BasteleurBold',
      //       fontSize: 20,
      //       fontWeight: FontWeight.w700,
      //       color: themeData.colorScheme.onSurface,
      //     ),
      //     toolbarTextStyle: TextStyle(
      //       fontFamily: 'BasteleurBold',
      //       fontSize: 20,
      //       fontWeight: FontWeight.w700,
      //       color: themeData.colorScheme.onSurface,
      //     ),
      //   ),
      // ),
      theme: themeData.copyWith(
        textTheme: google_fonts.GoogleFonts.youngSerifTextTheme(
          Typography.englishLike2021.apply(
            fontSizeFactor: kIsWeb ? 1.0 : (Platform.isMacOS ? 1.0 : 1.2),
            bodyColor: themeData.colorScheme.onSurface,
            displayColor: themeData.colorScheme.onSurface,
          ),
        ),
        navigationBarTheme: const NavigationBarThemeData(height: 69),
        appBarTheme: AppBarTheme(
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontFamily: 'BasteleurBold',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: themeData.colorScheme.onSurface,
          ),
          toolbarTextStyle: TextStyle(
            fontFamily: 'BasteleurBold',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: themeData.colorScheme.onSurface,
          ),
        ),
      ),
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

        return Scaffold(
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
                          // actionButton: TabBarActionButton(
                          //   symbol: "plus",
                          //   onTap: () {
                          //     // showAddExpenseSheet(context);
                          //     // showCupertinoSheet(
                          //     //   context: context,
                          //     //   builder: (context) {
                          //     //     return AddExpenseSheet();
                          //     //   },
                          //     // );
                          //   },
                          // ),
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
          body: [const ExpensesPage(), const SettingsScreen()][_selectedIndex],
        );
      },
    );
  }
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(authProvider);
    return Center(
      child: TextButton(
        onPressed: () async {
          final apiClient = getIt<ApiClient>();
          await ref.read(authProvider.notifier).logout();
          apiClient.removeToken();
        },
        child: const Text("Logout"),
      ),
    );
  }
}
