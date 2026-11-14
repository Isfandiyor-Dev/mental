import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mental/core/di/injector.dart';
import 'package:mental/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Advances the clock in slices large enough that exactly one
/// [AnimationController] completes per frame — the countdown and the sequence
/// both progress via status listeners, so a single huge pump would only ever
/// fire the first transition.
/// The slice must exceed the configured speed interval (2000 ms by default),
/// or a step's controller would not reach completion within one frame.
Future<void> pumpSlices(
  WidgetTester tester, {
  int count = 14,
  Duration slice = const Duration(milliseconds: 2100),
}) async {
  for (int i = 0; i < count; i++) {
    await tester.pump(slice);
  }
}

/// Settles an interaction: one frame to apply the state change, one span to run
/// the transition, and a final frame so [AnimatedSwitcher] can retire its
/// outgoing child.
Future<void> pumpInteraction(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump();
}

/// Brings the home screen up on a realistic phone viewport and plays its
/// entrance.
///
/// Note: `pumpAndSettle` is never used in these tests. The ambient background,
/// the START button shimmer and the answer caret all repeat forever by design,
/// so the tree never reaches a settled state.
Future<void> pumpHome(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1170, 2532); // iPhone-class device
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(const MentalApp());
  await tester.pump(); // resolve the settings load future
  await tester.pump(const Duration(milliseconds: 1200)); // entrance stagger
}

/// Scrolls the configuration list to reveal the lower cards.
Future<void> scrollToOperations(WidgetTester tester) async {
  await tester.drag(find.byType(ListView), const Offset(0, -400));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
}

void main() {
  setUp(() {
    // Each test starts from an empty store and a fresh object graph, so saved
    // settings never leak between tests.
    SharedPreferences.setMockInitialValues(<String, Object>{});
    Injector.reset();
  });

  testWidgets('first launch uses the novice defaults', (WidgetTester tester) async {
    await pumpHome(tester);

    expect(find.text('2 s'), findsOneWidget); // speed interval
    expect(find.text('5 numbers'), findsOneWidget); // sequence length

    await scrollToOperations(tester);
    expect(find.text('1 of 4'), findsOneWidget); // addition only
  });

  testWidgets('settings survive an app restart', (WidgetTester tester) async {
    await pumpHome(tester);
    await scrollToOperations(tester);

    // A discrete control persists the moment it changes.
    await tester.tap(find.text('×'));
    await pumpInteraction(tester);
    expect(find.text('2 of 4'), findsOneWidget);

    // Relaunch: same storage, brand-new object graph.
    Injector.reset();
    await tester.pumpWidget(const MentalApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1200));

    await scrollToOperations(tester);
    expect(find.text('2 of 4'), findsOneWidget);
  });

  testWidgets('home screen renders every configuration control', (WidgetTester tester) async {
    await pumpHome(tester);

    expect(find.text('Mental'), findsOneWidget);
    expect(find.text('START'), findsOneWidget);

    expect(find.text('SPEED INTERVAL'), findsOneWidget);
    expect(find.text('NUMBER RANGE'), findsOneWidget);
    expect(find.text('SEQUENCE LENGTH'), findsOneWidget);

    // All four ranges, and the negative-number checkbox beside them
    expect(find.text('1–9'), findsOneWidget);
    expect(find.text('1–99'), findsOneWidget);
    expect(find.text('1–999'), findsOneWidget);
    expect(find.text('1–9999'), findsOneWidget);
    // The negative-operand checkbox is gone; sign comes from the operations.
    expect(find.text('Allow negative numbers'), findsNothing);

    await scrollToOperations(tester);
    expect(find.text('Allow negative results'), findsOneWidget);
    expect(find.text('OPERATIONS'), findsOneWidget);
    for (final String symbol in <String>['+', '−', '×', '÷']) {
      expect(find.text(symbol), findsOneWidget);
    }
  });

  testWidgets('range selection and operation chips respond to taps',
      (WidgetTester tester) async {
    await pumpHome(tester);

    await tester.tap(find.text('1–9999'));
    await pumpInteraction(tester);

    await scrollToOperations(tester);

    // Addition alone is selected by default; adding × makes two.
    expect(find.text('1 of 4'), findsOneWidget);
    await tester.tap(find.text('×'));
    await pumpInteraction(tester);
    expect(find.text('2 of 4'), findsOneWidget);

    // Deselecting back down is fine.
    await tester.tap(find.text('×'));
    await pumpInteraction(tester);
    expect(find.text('1 of 4'), findsOneWidget);
  });

  testWidgets('the last operation cannot be deselected', (WidgetTester tester) async {
    await pumpHome(tester);
    await scrollToOperations(tester);

    // Addition is the only selection out of the box.
    expect(find.text('1 of 4'), findsOneWidget);

    // Refused: the count holds at one and the chip shakes instead.
    await tester.tap(find.text('+'));
    await pumpInteraction(tester);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('1 of 4'), findsOneWidget);
  });

  testWidgets('full round: START → countdown → sequence → keypad → result → home',
      (WidgetTester tester) async {
    await pumpHome(tester);

    await tester.tap(find.text('START'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600)); // route transition

    expect(find.text('Get ready'), findsOneWidget);

    // Countdown (4 ticks) then the default 8-number sequence.
    await pumpSlices(tester);

    // The custom keypad is up and the answer starts at zero.
    expect(find.text('Enter the total'), findsOneWidget);
    expect(find.text('0'), findsWidgets);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(find.byIcon(Icons.backspace_outlined), findsOneWidget);

    // Type 7, then 3 — the display should read 73.
    await tester.tap(find.text('7'));
    await pumpInteraction(tester);
    await tester.tap(find.text('3'));
    await pumpInteraction(tester);
    expect(find.text('73'), findsOneWidget);

    // Backspace drops the 3.
    await tester.tap(find.byIcon(Icons.backspace_outlined));
    await pumpInteraction(tester);
    expect(find.text('73'), findsNothing);

    // Confirm opens the animated result modal.
    await tester.tap(find.byIcon(Icons.check_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    final bool wasCorrect = find.text('Perfect!').evaluate().isNotEmpty;
    expect(wasCorrect || find.text('Not quite').evaluate().isNotEmpty, isTrue,
        reason: 'the modal must report one outcome or the other');
    expect(find.text(wasCorrect ? 'THANK' : 'OK'), findsOneWidget);

    // Dismissing resets the game and returns to configuration.
    await tester.tap(find.text(wasCorrect ? 'THANK' : 'OK'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump(const Duration(milliseconds: 700));

    expect(find.text('START'), findsOneWidget);
    expect(find.text('Enter the total'), findsNothing);
  });

  testWidgets('the answer updates in place, with no swap transition',
      (WidgetTester tester) async {
    await pumpHome(tester);

    await tester.tap(find.text('START'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await pumpSlices(tester);

    // Display and keypad both show '0' to begin with.
    expect(find.text('0'), findsNWidgets(2));

    await tester.tap(find.text('7'));
    await tester.pump(); // exactly one frame — no transition time allowed
    expect(find.text('7'), findsNWidgets(2)); // keypad key + display
    expect(find.text('0'), findsOneWidget); // only the keypad key is left

    await tester.tap(find.text('3'));
    await tester.pump(); // exactly one frame
    expect(find.text('73'), findsOneWidget);
    // The previous value is gone the instant it changes. An AnimatedSwitcher
    // would still be holding an outgoing '7' here, making this find two.
    expect(find.text('7'), findsOneWidget);
  });

  testWidgets('the minus key produces a negative answer', (WidgetTester tester) async {
    await pumpHome(tester);

    await tester.tap(find.text('START'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await pumpSlices(tester);

    await tester.tap(find.text('4'));
    await pumpInteraction(tester);
    await tester.tap(find.text('−')); // sign key
    await pumpInteraction(tester);

    expect(find.text('−4'), findsOneWidget);
  });

  testWidgets('gameplay fits a small phone without overflowing', (WidgetTester tester) async {
    // iPhone SE (1st gen) class — the tightest layout the app has to survive.
    // Any RenderFlex overflow would surface as a thrown exception here.
    tester.view.physicalSize = const Size(640, 1136);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MentalApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1200));

    await tester.tap(find.text('START'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await pumpSlices(tester);

    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('leaving mid-round tears down cleanly', (WidgetTester tester) async {
    await pumpHome(tester);

    await tester.tap(find.text('START'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    // Abandon during the countdown, while tickers are still running.
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('START'), findsOneWidget);

    // Pumping well past the abandoned round's duration must not throw — no
    // orphaned timer or ticker is left behind.
    await pumpSlices(tester, count: 8);
    expect(tester.takeException(), isNull);
  });
}
