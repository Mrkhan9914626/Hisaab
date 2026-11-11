import 'package:flutter/material.dart';

import '../domain/history_range.dart';

/// Labeled Day/Week/Month controls with previous/next period navigation.
class HistoryRangeControls extends StatelessWidget {
  const HistoryRangeControls({
    super.key,
    required this.rangeType,
    required this.onRangeChanged,
    required this.onPrevious,
    required this.onNext,
    required this.canGoPrevious,
    required this.canGoNext,
    required this.periodLabel,
  });

  final HistoryRangeType rangeType;
  final ValueChanged<HistoryRangeType> onRangeChanged;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final bool canGoPrevious;
  final bool canGoNext;
  final Widget periodLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<HistoryRangeType>(
            segments: const <ButtonSegment<HistoryRangeType>>[
              ButtonSegment<HistoryRangeType>(
                value: HistoryRangeType.day,
                label: Text('Day'),
              ),
              ButtonSegment<HistoryRangeType>(
                value: HistoryRangeType.week,
                label: Text('Week'),
              ),
              ButtonSegment<HistoryRangeType>(
                value: HistoryRangeType.month,
                label: Text('Month'),
              ),
            ],
            selected: <HistoryRangeType>{rangeType},
            showSelectedIcon: false,
            onSelectionChanged: (selection) {
              if (selection.isNotEmpty) {
                onRangeChanged(selection.first);
              }
            },
            style: const ButtonStyle(
              minimumSize: WidgetStatePropertyAll<Size>(Size(48, 48)),
              tapTargetSize: MaterialTapTargetSize.padded,
            ),
          ),
        ),
        Row(
          children: [
            IconButton(
              onPressed: canGoPrevious ? onPrevious : null,
              icon: const Icon(Icons.chevron_left),
              tooltip: 'Previous period',
            ),
            Expanded(child: Center(child: periodLabel)),
            IconButton(
              onPressed: canGoNext ? onNext : null,
              icon: const Icon(Icons.chevron_right),
              tooltip: 'Next period',
            ),
          ],
        ),
      ],
    );
  }
}
