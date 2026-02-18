import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/activity/activity_bloc.dart';

class ActivityFeed extends StatelessWidget {
  const ActivityFeed({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
          child: Text(
            "RECENT ACTIVITY",
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Expanded(
          child: BlocBuilder<ActivityBloc, ActivityState>(
            builder: (context, state) {
              if (state is ActivityLoading) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFFE31B23)));
              }
              if (state is ActivityLoaded) {
                if (state.transactions.isEmpty) {
                  return const Center(
                    child: Text("No transactions yet.", style: TextStyle(color: Colors.grey)),
                  );
                }
                return ListView.builder(
                  itemCount: state.transactions.length,
                  itemBuilder: (context, index) {
                    final tx = state.transactions[index];
                    final bool isIncoming = (tx['amount'] as num) > 0;
                    
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.05)),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: isIncoming 
                                ? Colors.green.withOpacity(0.1) 
                                : Colors.red.withOpacity(0.1),
                            child: Icon(
                              isIncoming ? Icons.south_west : Icons.north_east,
                              color: isIncoming ? Colors.greenAccent : Colors.redAccent,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tx['txid'].toString().substring(0, 12) + "...",
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  tx['confirmations'] > 0 ? "Confirmed" : "Pending",
                                  style: TextStyle(
                                    color: tx['confirmations'] > 0 ? Colors.grey : Colors.orangeAccent,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            "${isIncoming ? '+' : ''}${tx['amount']} RDD",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isIncoming ? Colors.greenAccent : Colors.white,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              }
              return const Center(child: Text("Start an activity to see history."));
            },
          ),
        ),
      ],
    );
  }
}
