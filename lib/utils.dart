import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:habits/constants.dart' as Constants;
import 'package:habits/providers/settings_provider.dart';
import 'package:habits/service_locator.dart';
import 'package:habits/types.dart';
import 'package:intl/intl.dart';
import 'package:material_segmented_list/material_segmented_list.dart';

String datetimeToLocalHRFormat(DateTime dt) {
  // Returns a human-readable local date string like "Aug 20, 2025"
  return DateFormat.yMMMEd().format(dt);
}

Color tileColorForAlert(BuildContext context) {
  return Theme.of(context).colorScheme.primary.withValues(alpha: 0.08);
  // return Theme.of(context).hintColor.withValues(alpha: 0.1);
}

bool shouldEnableGlass(AppSettings settings) {
  return Constants.enableLiquidGlassBar &&
      !settings.disableLiquidGlassBar &&
      Platform.isIOS;
}

enum AlertType { error, warning, info }

void showSnackBar(
  BuildContext context,
  String content, {
  bool clearExisting = true,
  AlertType type = AlertType.info,
  String? actionLabel,
  VoidCallback? onAction,
}) {
  if (!context.mounted) {
    return;
  }
  final theme = Theme.of(context);
  if (clearExisting) {
    ScaffoldMessenger.of(context).clearSnackBars();
  }
  final textColor = switch (type) {
    AlertType.error => theme.colorScheme.onError,
    AlertType.warning => Colors.black,
    AlertType.info => theme.colorScheme.onPrimary,
  };
  final backgroundColor = switch (type) {
    AlertType.error => theme.colorScheme.error,
    AlertType.warning => Colors.amber,
    AlertType.info => theme.colorScheme.primary,
  };
  final splashColor = switch (type) {
    AlertType.error => theme.colorScheme.onError.withValues(alpha: 0.1),
    AlertType.warning => Colors.black.withValues(alpha: 0.1),
    AlertType.info => theme.colorScheme.onPrimary.withValues(alpha: 0.1),
  };
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      content: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
            child: Text(
              content,
              style: theme.textTheme.bodyMedium?.copyWith(color: textColor),
            ),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(
              style: ButtonStyle(
                shape: const WidgetStatePropertyAll(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadiusGeometry.all(Radius.circular(4)),
                  ),
                ),
                padding: const WidgetStatePropertyAll(EdgeInsets.all(0)),
                visualDensity: VisualDensity.compact,
                overlayColor: WidgetStatePropertyAll(splashColor),
                textStyle: WidgetStatePropertyAll(
                  theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              onPressed: onAction,
              child: Text(
                actionLabel,
                style: theme.textTheme.bodyMedium?.copyWith(color: textColor),
              ),
            ),
        ],
      ),
      backgroundColor: backgroundColor,
    ),
  );
}

class SegmentedSectionTitle extends StatelessWidget {
  const SegmentedSectionTitle(this.title, {super.key, this.hasSpacing = true});

  final String title;
  final bool hasSpacing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 4, top: hasSpacing ? 12 : 0),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class SegmentedSectionSpacer extends StatelessWidget {
  const SegmentedSectionSpacer({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(height: 8);
  }
}

class SegmentedListChevron extends StatelessWidget {
  const SegmentedListChevron({super.key, this.color});

  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 19,
      child: Icon(Icons.chevron_right_rounded, color: color),
    );
  }
}

class UserAvatar extends StatelessWidget {
  const UserAvatar(this.user, {super.key, required this.size, this.onTap});

  final User? user;
  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: size,
      backgroundColor: Theme.of(context).colorScheme.primary,
      child: InkWell(
        onTap: onTap,
        customBorder: CircleBorder(),
        child: user?.profilePicture == null
            ? Text(
                user?.name.isNotEmpty == true ? user!.name[0] : '?',
                style: TextStyle(
                  fontSize: size,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              )
            : ClipOval(
                child: Image.network(
                  user!.profilePicture!,
                  width: size * 2,
                  height: size * 2,
                  fit: BoxFit.cover,
                ),
              ),
      ),
    );
  }
}

void showBoardPicker(BuildContext context) async {
  final boardRepo = getIt.get<CurrentBoardRepository>();

  showModalBottomSheet(
    context: context,
    clipBehavior: Clip.antiAlias,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
    ),
    useSafeArea: true,
    builder: (context) => SingleChildScrollView(
      child: Padding(
        padding: EdgeInsetsGeometry.fromLTRB(
          12,
          14,
          12,
          MediaQuery.of(context).padding.bottom + 14,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 12,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SegmentedSectionTitle("Select board", hasSpacing: false),
            SegmentedListSection(
              children: [
                for (var board in boardRepo.boards.value)
                  SegmentedListTile(
                    leading: Column(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(board.name),
                        if (board.description != null &&
                            board.description!.isNotEmpty)
                          Text(
                            board.description!,
                            style: Theme.of(context).textTheme.bodySmall,
                          )
                        else
                          Text(
                            "No description",
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(fontStyle: FontStyle.italic),
                          ),
                      ],
                    ),
                    trailing: SegmentedListChevron(),
                    minVerticalPadding: 0,
                    onTap: () {
                      boardRepo.switchBoard(board.id);
                      Navigator.of(context).pop();
                    },
                  ),
              ],
            ),
            SegmentedListSection(
              children: [
                SegmentedListTile(
                  title: const Text("Cancel", textAlign: TextAlign.center),
                  tileColor: tileColorForAlert(context),
                  minVerticalPadding: 0,
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

void showConfirmationDialog(
  BuildContext context, {
  String? title,
  String? content,
  required AsyncCallback onConfirm,
  String confirmText = "Confirm",
  bool isDestructive = false,
}) {
  showDialog(
    context: context,
    builder: (context) => SimpleDialog(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Column(
            children: [
              if (title != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              // const SizedBox(height: 16),
              if (content != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(content, textAlign: TextAlign.center),
                ),
              SegmentedListSection(
                children: [
                  SegmentedListTile(
                    visualDensity: VisualDensity.compact,
                    dense: true,
                    title: Center(child: Text(confirmText)),
                    tileColor: isDestructive
                        ? Colors.redAccent
                        : Theme.of(context).colorScheme.primary,
                    textColor: isDestructive
                        ? Colors.black
                        : Theme.of(context).colorScheme.onPrimary,
                    minVerticalPadding: 0,
                    onTap: () async {
                      await onConfirm();
                      if (context.mounted) {
                        Navigator.of(context).pop();
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
