import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habits/providers/auth_provider.dart';
import 'package:habits/utils.dart';
import 'package:material_segmented_list/material_segmented_list.dart';

class UserSettingsPage extends ConsumerWidget {
  const UserSettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("User Settings")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        clipBehavior: Clip.none,
        child: Column(
          spacing: 16,
          children: [
            UserAvatar(currentUser.value, size: 60),
            SizedBox(height: 0),
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
          ],
        ),
      ),
    );
  }
}
