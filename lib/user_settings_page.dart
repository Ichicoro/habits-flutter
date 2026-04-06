import 'package:dio/dio.dart';
import 'package:habits/api_client.dart';
import 'package:habits/service_locator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habits/providers/auth_provider.dart';
import 'package:habits/types.dart';
import 'package:habits/utils.dart';
import 'package:material_segmented_list/material_segmented_list.dart';

void showChangePictureDialog(
  BuildContext context, {
  required User user,
  required Function(String) onPictureSelected,
}) {
  showDialog(
    context: context,
    builder: (context) => SimpleDialog(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Column(
            spacing: 16,
            children: [
              Text(
                "Change Profile Picture",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              UserAvatar(user, size: 48),
              SegmentedListSection(
                children: [
                  SegmentedListTile(
                    visualDensity: VisualDensity.compact,
                    dense: true,
                    title: Center(child: Text("Pick image...")),
                    tileColor: Theme.of(context).colorScheme.primary,
                    textColor: Theme.of(context).colorScheme.onPrimary,
                    minVerticalPadding: 0,
                    onTap: () async {
                      final picker = ImagePicker();
                      var picked = await picker.pickImage(
                        source: ImageSource.gallery,
                      );
                      if (picked != null) {
                        final String path = picked.path;
                        onPictureSelected(path);
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                      }
                    },
                  ),
                  SegmentedListTile(
                    visualDensity: VisualDensity.compact,
                    dense: true,
                    title: Center(child: Text("Cancel")),
                    onTap: () => Navigator.of(context).pop(),
                    tileColor: tileColorForAlert(context),
                    minVerticalPadding: 0,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class UserSettingsPage extends ConsumerWidget {
  UserSettingsPage({Key? key})
    : apiClient = getIt.get<ApiClient>(),
      super(key: key);

  final ApiClient apiClient;

  void _changeProfilePicture(
    BuildContext context,
    WidgetRef ref,
    String path,
  ) async {
    showSnackBar(context, "Uploading picture...");
    try {
      await apiClient.uploadProfilePicture(path);
      ref.read(currentUserProvider.notifier).refresh();
      if (context.mounted) {
        showSnackBar(context, "Profile picture updated!");
      }
    } on DioException catch (e) {
      if (context.mounted) {
        showSnackBar(
          context,
          "Failed to upload picture: ${ApiClient.parseDjangoErrorMessage(e)}",
        );
      }
    }
  }

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
            UserAvatar(
              currentUser.value,
              size: 60,
              onTap: () {
                showChangePictureDialog(
                  context,
                  user: currentUser.value!,
                  onPictureSelected: (path) =>
                      _changeProfilePicture(context, ref, path),
                );
              },
            ),
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
