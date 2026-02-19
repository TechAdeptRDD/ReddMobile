import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'bloc/dashboard/dashboard_bloc.dart';
import 'bloc/activity/activity_bloc.dart';
import 'services/blockbook_service.dart';
import 'services/secure_storage_service.dart';
import 'pages/dashboard_page.dart';
import 'pages/social_page.dart';
import 'pages/activity_page.dart';
import 'pages/welcome_page.dart';

void main() {
  runApp(const ReddMobileApp());
}

class ReddMobileApp extends StatelessWidget {
  const ReddMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    final blockbookService = BlockbookService();
    final storage = SecureStorageService();

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
        // Use a FutureBuilder to check for existing credentials on launch
        home: FutureBuilder<String?>(
          future: storage.getMnemonic(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFFE31B23))));
            }
            if (snapshot.hasData && snapshot.data != null) {
              return const MainNavigation(); // User has a wallet
            }
            return const WelcomePage(); // First time user
          },
        ),
      ),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});
  @override State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 1; 
  
  final List<Widget> _pages = [
    const SocialPage(),   
    const DashboardPage(),
    const ActivityPage(), 
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
