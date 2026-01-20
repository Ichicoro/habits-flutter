import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

String datetimeToLocalHRFormat(DateTime dt) {
  // Returns a human-readable local date string like "Aug 20, 2025"
  return DateFormat.yMMMEd().format(dt);
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
