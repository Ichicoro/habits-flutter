import 'package:drops/drops.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_segmented_list/material_segmented_list.dart';

String datetimeToLocalHRFormat(DateTime dt) {
  // Returns a human-readable local date string like "Aug 20, 2025"
  return DateFormat.yMMMEd().format(dt);
}

void showDropAlert(BuildContext context, {required String title}) {
  Drops.show(context, title: title);
}

Color tileColorForAlert(BuildContext context) {
  return Theme.of(context).colorScheme.primary.withValues(alpha: 0.08);
  // return Theme.of(context).hintColor.withValues(alpha: 0.1);
}

void showSnackBar(
  BuildContext context,
  Widget content, {
  bool clearExisting = true,
}) {
  if (clearExisting) {
    ScaffoldMessenger.of(context).clearSnackBars();
  }
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: content));
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
                    title: Center(child: Text("Cancel")),
                    onTap: () => Navigator.of(context).pop(),
                    tileColor: tileColorForAlert(context),
                    minVerticalPadding: 0,
                  ),
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
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
