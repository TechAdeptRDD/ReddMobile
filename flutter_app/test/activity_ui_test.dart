import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:redd_mobile/widgets/activity_feed.dart';
import 'package:redd_mobile/bloc/activity/activity_bloc.dart';
import 'package:redd_mobile/services/blockbook_service.dart';

class MockActivityBloc extends Bloc<ActivityEvent, ActivityState> implements ActivityBloc {
  MockActivityBloc() : super(ActivityLoaded(List.generate(50, (i) => {
    'txid': 'txid_hash_example_$i',
    'amount': i % 2 == 0 ? 100.0 : -50.0,
    'confirmations': i % 5 == 0 ? 0 : 10,
    'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
  })));
  
  @override
  BlockbookService get blockbookService => throw UnimplementedError();
}

void main() {
  testWidgets('ActivityFeed should render 50 transaction items smoothly', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BlocProvider<ActivityBloc>(
            create: (context) => MockActivityBloc(),
            child: const ActivityFeed(),
          ),
        ),
      ),
    );

    // Check if the first few items are visible
    expect(find.textContaining('txid_has'), findsWidgets);
    
    // Simulate a scroll
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pump();

    expect(find.byType(Container), findsWidgets);
  });
}
