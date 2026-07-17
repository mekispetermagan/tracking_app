import 'package:flutter/material.dart';

class MonthSelector extends StatelessWidget {
  final DateTime month;
  final ValueChanged<DateTime> onChanged;
  final bool enabled;
  final bool allowFutureMonths;

  const MonthSelector({
    required this.month,
    required this.onChanged,
    this.enabled = true,
    this.allowFutureMonths = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final selectedMonth = DateTime(month.year, month.month);

    final currentMonth = DateTime(DateTime.now().year, DateTime.now().month);

    final canMoveNext =
        enabled && (allowFutureMonths || selectedMonth.isBefore(currentMonth));

    return Row(
      children: [
        IconButton(
          onPressed: enabled
              ? () {
                  onChanged(
                    DateTime(selectedMonth.year, selectedMonth.month - 1),
                  );
                }
              : null,
          icon: const Icon(Icons.chevron_left),
          tooltip: 'Previous month',
        ),
        Expanded(
          child: Text(
            _formatMonth(selectedMonth),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        IconButton(
          onPressed: canMoveNext
              ? () {
                  onChanged(
                    DateTime(selectedMonth.year, selectedMonth.month + 1),
                  );
                }
              : null,
          icon: const Icon(Icons.chevron_right),
          tooltip: 'Next month',
        ),
      ],
    );
  }

  String _formatMonth(DateTime date) {
    const monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${monthNames[date.month - 1]} ${date.year}';
  }
}
