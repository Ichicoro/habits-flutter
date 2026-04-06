import 'package:flutter/material.dart';
import 'package:habits/service_locator.dart';
import 'package:habits/utils.dart';

class TitleWithBoardPicker extends StatelessWidget {
  const TitleWithBoardPicker({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final boardRepo = getIt.get<CurrentBoardRepository>();

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: boardRepo.currentBoard.value != null
          ? () {
              showBoardPicker(context);
            }
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Column(
          children: [
            Text(title),
            if (boardRepo.currentBoard.value != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.swap_horiz_rounded, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    boardRepo.currentBoard.value!.name,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
