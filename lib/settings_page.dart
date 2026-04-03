import 'package:drops/drops.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habits/providers/auth_provider.dart';
import 'package:habits/providers/settings_provider.dart';
import 'package:habits/service_locator.dart';
import 'package:habits/utils.dart';
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
      appBar: AppBar(title: const Text("Settings")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          spacing: 12,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SegmentedSectionTitle("Account", hasSpacing: false),
            SegmentedListSection(
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
            ),

            SegmentedSectionTitle("App settings"),
            SegmentedListSection(
              children: [
                SegmentedListTile(
                  leading: const Text("Force dark mode"),
                  onTap: () => ref
                      .read(settingsProvider.notifier)
                      .setThemeMode(
                        appSettings.themeMode == ThemeMode.dark
                            ? ThemeMode.light
                            : ThemeMode.dark,
                      ),
                  trailing: Switch(
                    value: appSettings.themeMode == ThemeMode.dark,
                    onChanged: (value) {
                      ref
                          .read(settingsProvider.notifier)
                          .setThemeMode(
                            value ? ThemeMode.dark : ThemeMode.light,
                          );
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
                        Drops.show(
                          context,
                          title: "Work in progress!",
                          icon: Icons.warning_amber_rounded,
                          iconColor: Colors.amber,
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
