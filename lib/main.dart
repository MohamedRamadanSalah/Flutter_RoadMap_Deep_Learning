import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/event/presentation/screens/event_list_screen.dart';

void main() {
  runApp(
    // ProviderScope is the root of the Riverpod provider graph.
    // Every Provider, AsyncNotifier, and derived provider lives inside this scope.
    // In tests, you wrap with ProviderContainer instead.
    const ProviderScope(child: EventHubApp()),
  );
}

class EventHubApp extends StatelessWidget {
  const EventHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EventHub',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF2196F3),
        useMaterial3: true,
      ),
      home: const EventListScreen(),
    );
  }
}
