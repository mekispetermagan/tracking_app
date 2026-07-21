import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/widgets/assignment_management_view.dart';
import 'package:frontend/widgets/buttons.dart';
import 'package:frontend/widgets/month_selector.dart';

enum _Status { active, all, inactive }

Widget _app(Widget child) => MaterialApp(home: child);

void main() {
  testWidgets(
    'large buttons expose enabled, disabled, icon, and custom content',
    (tester) async {
      var presses = 0;
      await tester.pumpWidget(
        _app(
          Column(
            children: [
              LargeFilledButton(text: 'Enabled', onPressed: () => presses++),
              const LargeFilledButton(text: 'Disabled'),
              LargeFilledButton(
                icon: const Icon(Icons.add),
                onPressed: () {},
                child: const Text('Custom'),
              ),
            ],
          ),
        ),
      );

      await tester.tap(find.text('Enabled'));
      await tester.tap(find.text('Disabled'));

      expect(presses, 1);
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.text('Custom'), findsOneWidget);
    },
  );

  testWidgets('month selector navigates months and blocks future navigation', (
    tester,
  ) async {
    final changes = <DateTime>[];
    final current = DateTime(DateTime.now().year, DateTime.now().month);

    await tester.pumpWidget(
      _app(MonthSelector(month: current, onChanged: changes.add)),
    );

    expect(
      find.text('${_monthName(current.month)} ${current.year}'),
      findsOneWidget,
    );
    await tester.tap(find.byTooltip('Previous month'));
    await tester.tap(find.byTooltip('Next month'));

    expect(changes, [DateTime(current.year, current.month - 1)]);

    await tester.pumpWidget(
      _app(
        MonthSelector(
          month: current,
          allowFutureMonths: true,
          onChanged: changes.add,
        ),
      ),
    );
    await tester.tap(find.byTooltip('Next month'));
    expect(changes.last, DateTime(current.year, current.month + 1));
  });

  testWidgets('assignment view edits local selection and forwards actions', (
    tester,
  ) async {
    final changes = <(int, bool)>[];
    _Status? selectedFilter;
    var saves = 0;
    var cancels = 0;
    var clears = 0;

    Widget build({int subject = 1, Set<int> assigned = const {1}}) {
      return _app(
        AssignmentManagementView<int, int, _Status>(
          title: 'Assignments',
          subject: subject,
          subjectIdFor: (value) => value,
          subjectNameFor: (value) => 'Subject $value',
          items: const [1, 2],
          assignedItemIds: assigned,
          statusFilter: _Status.active,
          activeFilter: _Status.active,
          allFilter: _Status.all,
          inactiveFilter: _Status.inactive,
          emptyMessage: 'No items',
          idFor: (value) => value,
          titleFor: (value) => 'Item $value',
          subtitleFor: (value) => 'Details $value',
          isActiveFor: (value) => value == 1,
          isLoading: false,
          isSaving: false,
          message: 'Ready',
          clearMessage: () => clears++,
          onStatusFilterChanged: (value) => selectedFilter = value,
          onAssignmentChanged: (id, assigned) => changes.add((id, assigned)),
          onSave: () async {
            saves++;
            return true;
          },
          onCancel: () => cancels++,
        ),
      );
    }

    await tester.pumpWidget(build());
    await tester.pump();
    expect(find.text('Ready'), findsOneWidget);
    expect(clears, 1);
    expect(find.bySemanticsLabel('Inactive'), findsOneWidget);

    await tester.tap(find.text('Item 2'));
    expect(changes, [(2, true)]);
    await tester.tap(find.text('All'));
    expect(selectedFilter, _Status.all);
    await tester.tap(find.text('Save assignments'));
    await tester.tap(find.byType(BackButton));
    expect(saves, 1);
    expect(cancels, 1);

    await tester.pumpWidget(build(subject: 2, assigned: const {2}));
    final boxes = tester.widgetList<Checkbox>(find.byType(Checkbox)).toList();
    expect(boxes.map((box) => box.value), [false, true]);
  });
}

String _monthName(int month) => const [
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
][month - 1];
