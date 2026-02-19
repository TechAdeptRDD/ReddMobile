import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'bloc/dashboard/dashboard_bloc.dart';
import 'bloc/activity/activity_bloc.dart';
import 'services/blockbook_service.dart';
import 'pages/dashboard_page.dart';
import 'pages/social_page.dart';
import 'pages/activity_page.dart';

void main() {
  runApp(const ReddMobileApp());
}

class ReddMobileApp extends StatelessWidget {
  const ReddMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    final blockbookService = BlockbookService();

    return MultiBlocProvider(
      providers: [
        BlocProvider<DashboardBloc>(create: (context) => DashboardBloc()),
        BlocProvider<ActivityBloc>(create: (context) => ActivityBloc(blockbookService: blockbookService)),
      ],
      child: MaterialApp(
        title: 'ReddMobile',
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF0F0F0F),
          primaryColor: const Color(0xFFE31B23),
        ),
        home: const MainNavigation(),
      ),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});
  @override State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 1; // Start on the Dashboard (middle tab)
  
  final List<Widget> _pages = [
    const SocialPage(),   // 0: The Registration / Search tab
    const DashboardPage(),// 1: The Wallet Dashboard
    const ActivityPage(), // 2: The Global Feed tab
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF151515),
        selectedItemColor: const Color(0xFFE31B23),
        unselectedItemColor: Colors.grey,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.person_search), label: "Identity"),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: "Wallet"),
          BottomNavigationBarItem(icon: Icon(Icons.public), label: "Global"),
        ],
      ),
    );
  }
}
