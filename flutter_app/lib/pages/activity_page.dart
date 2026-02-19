import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/activity/activity_bloc.dart';
import '../widgets/send_dialog.dart';

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
      try { result += String.fromCharCode(int.parse(hex.substring(i, i + 2), radix: 16)); } catch (e) { continue; }
    }
    return result;
  }

  void _openTipDialog(String username) {
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (context) => SendDialog(initialRecipient: "@$username"));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: Row(
          children: [
            const Text("Global Activity", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const Spacer(),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.2, end: 1.0),
              duration: const Duration(seconds: 1),
              builder: (context, opacity, child) {
                return Opacity(
                  opacity: opacity,
                  child: Row(
                    children: [
                      Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      const Text("Live Sync", style: TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              },
              onEnd: () { /* The TweenAnimationBuilder resets naturally via state if we wanted infinite looping, but a single pulse on load is elegant */ },
            ),
          ],
        ),
        backgroundColor: Colors.transparent, elevation: 0,
      ),
      body: BlocBuilder<ActivityBloc, ActivityState>(
        builder: (context, state) {
          if (state is ActivityLoading || state is ActivityInitial) return const Center(child: CircularProgressIndicator(color: Color(0xFFE31B23)));
          if (state is ActivityError) return Center(child: Text(state.message, style: const TextStyle(color: Colors.redAccent)));
          if (state is ActivityLoaded) {
            final txs = state.transactions;
            if (txs.isEmpty) return const Center(child: Text("No network activity.", style: TextStyle(color: Colors.grey)));

            return RefreshIndicator(
              color: const Color(0xFFE31B23), backgroundColor: const Color(0xFF151515),
              onRefresh: () async => context.read<ActivityBloc>().add(LoadActivity()),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: txs.length,
                itemBuilder: (context, index) {
                  final tx = txs[index];
                  String? username, cid, memo;
                  bool isRegistration = false;

                  for (var vout in tx['vout']) {
                    final String asm = vout['scriptPubKey']['asm'] ?? "";
                    if (asm.contains("OP_RETURN")) {
                       final hexPayload = asm.split("OP_RETURN ")[1];
                       final decoded = _decodeHex(hexPayload);
                       if (decoded.startsWith("RDD:ID:")) {
                         isRegistration = true;
                         final parts = decoded.split(":");
                         if (parts.length >= 4) { username = parts[2]; cid = parts[3]; }
                       } else if (decoded.startsWith("RDD:MSG:")) {
                         memo = decoded.substring(8); // Strip the prefix
                       }
                    }
                  }
                  
                  if (!isRegistration && memo == null) return const SizedBox.shrink(); 

                  return Card(
                    color: const Color(0xFF151515),
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: CircleAvatar(
                        radius: 25, backgroundColor: Colors.black,
                        backgroundImage: cid != null && cid.isNotEmpty ? NetworkImage("https://gateway.pinata.cloud/ipfs/$cid") : null,
                        child: (cid == null && isRegistration) ? const Icon(Icons.person, color: Colors.grey) : (!isRegistration ? const Icon(Icons.chat_bubble, color: Color(0xFFE31B23)) : null),
                      ),
                      title: Text(isRegistration ? "@$username" : "Network Tip", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8.0), 
                        child: Text(isRegistration ? "Registered Identity" : "\"$memo\"", style: TextStyle(color: isRegistration ? Colors.greenAccent.shade400 : Colors.grey, fontSize: 13, fontStyle: isRegistration ? FontStyle.normal : FontStyle.italic))
                      ),
                      trailing: isRegistration ? IconButton(
                        icon: const Icon(Icons.volunteer_activism, color: Color(0xFFE31B23)),
                        tooltip: "Tip User",
                        onPressed: () => _openTipDialog(username!),
                      ) : null,
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
