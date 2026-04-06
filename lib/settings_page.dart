import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habits/constants.dart' as Constants;
import 'package:habits/providers/auth_provider.dart';
import 'package:habits/providers/settings_provider.dart';
import 'package:habits/service_locator.dart';
import 'package:habits/user_settings_page.dart';
import 'package:habits/utils.dart';
import 'package:habits/widgets/app_dropdown.dart';
import 'package:habits/widgets/title_with_board_picker.dart';
import 'package:material_segmented_list/material_segmented_list.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(authProvider);
    final currentUser = ref.watch(currentUserProvider);
    final boardRepository = getIt.get<CurrentBoardRepository>();
    final appSettings = ref.watch(settingsProvider);

    return Scaffold(
      extendBody: true,
      appBar: AppBar(title: TitleWithBoardPicker(title: "Settings")),
      body: SingleChildScrollView(
        clipBehavior: Clip.none,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          spacing: 12,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SegmentedSectionTitle("Account", hasSpacing: false),
            SegmentedListTile(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => UserSettingsPage()),
                );
              },
              leading: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                spacing: 12,
                children: [
                  UserAvatar(currentUser.value, size: 16),
                  Text(currentUser.value?.name ?? 'Guest'),
                ],
              ),
              trailing: SegmentedListChevron(),
            ),

            /* SegmentedListSection(
              children: [
                SegmentedListTile(
                  leading: const Text("Username"),
                  trailing: Text(
                    currentUser.when(
                      data: (user) => user.username,
                      loading: () => '…',
                      error: (_, _) => '—',
                    ),
                  ),
                ),
                SegmentedListTile(
                  leading: const Text("Email"),
                  trailing: Text(
                    currentUser.when(
                      data: (user) => user.email,
                      loading: () => '…',
                      error: (_, _) => '—',
                    ),
                  ),
                ),
                SegmentedListTile(
                  leading: const Text("Name"),
                  trailing: Text(
                    currentUser.when(
                      data: (user) => user.name,
                      loading: () => '…',
                      error: (_, _) => '—',
                    ),
                  ),
                ),
                SegmentedListTile(
                  leading: const Text(
                    "Logout",
                    style: TextStyle(color: Colors.redAccent),
                  ),
                  trailing: SegmentedListChevron(),
                  onTap: () async {
                    // Show confirmation
                    showConfirmationDialog(
                      context,
                      title: "Are you sure you want to logout?",
                      // content: "Test",
                      isDestructive: true,
                      onConfirm: () async {
                        await ref.read(authProvider.notifier).logout();
                      },
                    );
                  },
                ),
              ],
            ), */
            SegmentedSectionTitle("App settings"),
            SegmentedListSection(
              children: [
                SegmentedListTile(
                  leading: const Text("Theme"),
                  trailing: AppDropdown<ThemeMode>(
                    value: appSettings.themeMode,
                    items: const [
                      DropdownMenuItem(
                        value: ThemeMode.system,
                        child: Text("System"),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.light,
                        child: Text("Light"),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.dark,
                        child: Text("Dark"),
                      ),
                    ],
                    onChanged: (mode) {
                      ref.read(settingsProvider.notifier).setThemeMode(mode);
                    },
                  ),
                ),
                SegmentedListTile(
                  leading: const Text("OLED dark mode"),
                  onTap: () {
                    ref
                        .read(settingsProvider.notifier)
                        .setOledDarkMode(!appSettings.oledDarkMode);
                  },
                  trailing: Switch(
                    value: appSettings.oledDarkMode,
                    onChanged: (value) {
                      ref
                          .read(settingsProvider.notifier)
                          .setOledDarkMode(value);
                    },
                  ),
                ),
                if (Platform.isIOS && Constants.enableLiquidGlassBar)
                  SegmentedListTile(
                    leading: const Text("Disable Liquid Glass"),
                    onTap: () {
                      ref
                          .read(settingsProvider.notifier)
                          .setDisableLiquidGlassBar(
                            !appSettings.disableLiquidGlassBar,
                          );
                    },
                    trailing: Switch(
                      value: appSettings.disableLiquidGlassBar,
                      onChanged: (value) {
                        ref
                            .read(settingsProvider.notifier)
                            .setDisableLiquidGlassBar(value);
                      },
                    ),
                  ),
              ],
            ),

            SegmentedSectionTitle("Active board"),
            ValueListenableBuilder(
              valueListenable: boardRepository.currentBoard,
              builder: (context, activeBoard, _) {
                return SegmentedListSection(
                  children: [
                    SegmentedListTile(
                      leading: const Text("Name"),
                      trailing: Text(activeBoard?.name ?? 'n/a'),
                    ),
                    SegmentedListTile(
                      leading: const Text("Description"),
                      trailing: Text(activeBoard?.description ?? 'n/a'),
                    ),
                    SegmentedListTile(
                      leading: const Text("Members"),
                      trailing: Text(
                        activeBoard != null
                            ? '${activeBoard.users.length}'
                            : 'n/a',
                      ),
                    ),
                    SegmentedListTile(
                      leading: const Text("Invite users"),
                      trailing: SegmentedListChevron(),
                      onTap: () {
                        showSnackBar(
                          context,
                          "Work in progress",
                          type: AlertType.warning,
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
