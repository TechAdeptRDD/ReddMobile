import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/dashboard/dashboard_bloc.dart';
import '../bloc/dashboard/dashboard_event.dart';
import '../bloc/dashboard/dashboard_state.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TextEditingController _handleController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("REDDCOIN ID", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.account_balance_wallet_outlined), onPressed: () {}),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text("Claim your unique handle on the Reddcoin blockchain.", 
              style: TextStyle(color: Colors.grey, fontSize: 16)),
            const SizedBox(height: 32),
            
            // Search Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: TextField(
                controller: _handleController,
                style: const TextStyle(color: Colors.white, fontSize: 18),
                decoration: const InputDecoration(
                  hintText: "Enter handle (e.g. techadept)",
                  border: InputBorder.none,
                  suffixText: ".redd",
                  suffixStyle: TextStyle(color: Color(0xFFE31B23), fontWeight: FontWeight.bold),
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // BLoC State Management for Results
            Expanded(
              child: BlocConsumer<DashboardBloc, DashboardState>(
                listener: (context, state) {
                  if (state is ReddIDPayloadGenerated) {
                    _showSuccessDialog(context, state.payloadHex);
                  }
                },
                builder: (context, state) {
                  if (state is DashboardLoading) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFFE31B23)));
                  }
                  
                  if (state is DashboardError) {
                    return Text(state.message, style: const TextStyle(color: Colors.redAccent));
                  }

                  return Column(
                    children: [
                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE31B23),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            final handle = _handleController.text.trim();
                            if (handle.isNotEmpty) {
                              context.read<DashboardBloc>().add(AcquireReddIDEvent(handle));
                            }
                          },
                          child: const Text("CHECK AVAILABILITY & BID", 
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessDialog(BuildContext context, String txHex) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Transaction Ready"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Rust has successfully signed your ReddID bid transaction!"),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.black,
              child: Text(txHex.substring(0, 40) + "...", 
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: Colors.greenAccent)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CLOSE")),
          ElevatedButton(onPressed: () {}, child: const Text("BROADCAST")),
        ],
      ),
    );
  }
}
