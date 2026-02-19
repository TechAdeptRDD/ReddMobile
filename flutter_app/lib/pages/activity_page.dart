import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/activity/activity_bloc.dart';

class ActivityPage extends StatefulWidget {
  const ActivityPage({super.key});

  @override
  State<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> {
  @override
  void initState() {
    super.initState();
    context.read<ActivityBloc>().add(LoadActivity());
  }

  String _decodeHex(String hex) {
    String result = "";
    for (int i = 0; i < hex.length; i += 2) {
      try {
        result += String.fromCharCode(int.parse(hex.substring(i, i + 2), radix: 16));
      } catch (e) { continue; }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: const Text("Global Activity", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: BlocBuilder<ActivityBloc, ActivityState>(
        builder: (context, state) {
          if (state is ActivityLoading || state is ActivityInitial) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFE31B23)));
          } else if (state is ActivityError) {
            return Center(child: Text(state.message, style: const TextStyle(color: Colors.redAccent)));
          } else if (state is ActivityLoaded) {
            final txs = state.transactions;
            if (txs.isEmpty) return const Center(child: Text("No network activity.", style: TextStyle(color: Colors.grey)));

            return RefreshIndicator(
              color: const Color(0xFFE31B23),
              backgroundColor: const Color(0xFF151515),
              onRefresh: () async => context.read<ActivityBloc>().add(LoadActivity()),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: txs.length,
                itemBuilder: (context, index) {
                  final tx = txs[index];
                  String? username;
                  String? cid;

                  // Hunt for the OP_RETURN in the transaction outputs
                  for (var vout in tx['vout']) {
                    final String asm = vout['scriptPubKey']['asm'] ?? "";
                    if (asm.contains("OP_RETURN") && asm.contains("5244443a49443a")) { // Hex for "RDD:ID:"
                       final hexPayload = asm.split("OP_RETURN ")[1];
                       final decoded = _decodeHex(hexPayload);
                       final parts = decoded.split(":");
                       if (parts.length >= 4) {
                         username = parts[2];
                         cid = parts[3];
                       }
                    }
                  }

                  if (username == null) return const SizedBox.shrink(); // Hide non-social txs

                  return Card(
                    color: const Color(0xFF151515),
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: CircleAvatar(
                        radius: 25,
                        backgroundColor: Colors.black,
                        backgroundImage: cid != null && cid.isNotEmpty ? NetworkImage("https://gateway.pinata.cloud/ipfs/$cid") : null,
                        child: cid == null || cid.isEmpty ? const Icon(Icons.person, color: Colors.grey) : null,
                      ),
                      title: Text("@$username", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text("Registered Identity on Blockchain", style: TextStyle(color: Colors.greenAccent.shade400, fontSize: 13)),
                      ),
                      trailing: const Icon(Icons.verified, color: Colors.blueAccent, size: 20),
                    ),
                  );
                },
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
