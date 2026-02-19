import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/dashboard/dashboard_bloc.dart';
import '../widgets/send_dialog.dart';
import 'receive_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    context.read<DashboardBloc>().add(LoadDashboardData());
  }

  void _showSendDialog() {
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (context) => const SendDialog());
  }

  String _decodeHex(String hex) {
    String result = "";
    for (int i = 0; i < hex.length; i += 2) {
      try { result += String.fromCharCode(int.parse(hex.substring(i, i + 2), radix: 16)); } catch (e) { continue; }
    }
    return result;
  }

  // Determine Redd Level based on sent tips
  Map<String, dynamic> _getReddLevel(List<dynamic> history, String myAddress) {
    int sentCount = 0;
    for (var tx in history) {
      for (var vin in tx['vin']) {
        if (vin['addresses'] != null && vin['addresses'].contains(myAddress)) {
          sentCount++; break;
        }
      }
    }

    if (sentCount >= 50) return {"title": "Gold ReddHead", "color": Colors.amber};
    if (sentCount >= 10) return {"title": "Silver ReddHead", "color": Colors.blueGrey.shade300};
    return {"title": "Bronze ReddHead", "color": Colors.orange.shade800};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: const Text("ReddMobile Vault", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent, elevation: 0,
        actions: [ IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: () => context.read<DashboardBloc>().add(LoadDashboardData())) ],
      ),
      body: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          if (state is DashboardLoading || state is DashboardInitial) return const Center(child: CircularProgressIndicator(color: Color(0xFFE31B23)));
          if (state is DashboardError) return Center(child: Text(state.message, style: const TextStyle(color: Colors.redAccent)));
          if (state is DashboardLoaded) {
            
            final level = _getReddLevel(state.history, state.address);

            return RefreshIndicator(
              color: const Color(0xFFE31B23), backgroundColor: const Color(0xFF151515),
              onRefresh: () async => context.read<DashboardBloc>().add(LoadDashboardData()),
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  // Gamified Balance Card
                  Container(
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFFE31B23), Color(0xFF9E1016)], begin: Alignment.topLeft, end: Alignment.bottomRight), 
                      borderRadius: BorderRadius.circular(25), 
                      border: Border.all(color: level["color"], width: 3), // The Dynamic Border!
                      boxShadow: [BoxShadow(color: level["color"].withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))]
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.stars, color: level["color"], size: 18),
                            const SizedBox(width: 5),
                            Text(level["title"], style: TextStyle(color: level["color"], fontSize: 14, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 15),
                        const Text("Total Balance", style: TextStyle(color: Colors.white70, fontSize: 16)),
                        const SizedBox(height: 10),
                        Text("${state.formattedBalance} RDD", style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 15),
                        Text(state.address.substring(0, 12) + "..." + state.address.substring(state.address.length - 4), style: const TextStyle(color: Colors.white54, fontSize: 12, fontFamily: 'monospace')),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      Expanded(child: ElevatedButton.icon(style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15), backgroundColor: const Color(0xFF151515), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), onPressed: _showSendDialog, icon: const Icon(Icons.arrow_upward, color: Colors.white), label: const Text("SEND", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
                      const SizedBox(width: 15),
                      Expanded(child: ElevatedButton.icon(style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15), backgroundColor: const Color(0xFF151515), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReceivePage())), icon: const Icon(Icons.arrow_downward, color: Colors.white), label: const Text("RECEIVE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
                    ],
                  ),
                  const SizedBox(height: 40),
                  const Text("Recent Transactions", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  
                  if (state.history.isEmpty) const Padding(padding: EdgeInsets.only(top: 20), child: Center(child: Text("No transactions yet.", style: TextStyle(color: Colors.grey)))),
                  
                  ...state.history.map((tx) {
                    bool isOutgoing = false;
                    String? memo;
                    
                    for (var vin in tx['vin']) {
                      if (vin['addresses'] != null && vin['addresses'].contains(state.address)) {
                        isOutgoing = true; break;
                      }
                    }

                    for (var vout in tx['vout']) {
                      final String asm = vout['scriptPubKey']['asm'] ?? "";
                      if (asm.contains("OP_RETURN")) {
                         final hexPayload = asm.split("OP_RETURN ")[1];
                         final decoded = _decodeHex(hexPayload);
                         if (decoded.startsWith("RDD:MSG:")) memo = decoded.substring(8);
                      }
                    }
                    
                    final double val = (int.parse(tx['value'] ?? '0') / 100000000);
                    final String formattedVal = val.toStringAsFixed(2);
                    
                    return Card(
                      color: const Color(0xFF151515), margin: const EdgeInsets.only(bottom: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: ListTile(
                        leading: CircleAvatar(backgroundColor: isOutgoing ? Colors.redAccent.withOpacity(0.2) : Colors.greenAccent.withOpacity(0.2), child: Icon(isOutgoing ? Icons.call_made : Icons.call_received, color: isOutgoing ? Colors.redAccent : Colors.greenAccent)),
                        title: Text(isOutgoing ? "Sent RDD" : "Received RDD", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (memo != null) Text("\"$memo\"", style: const TextStyle(color: Colors.white70, fontStyle: FontStyle.italic)),
                            Text(tx['txid'].toString().substring(0, 12) + "...", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                        trailing: Text("${isOutgoing ? '-' : '+'}$formattedVal", style: TextStyle(color: isOutgoing ? Colors.redAccent : Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    );
                  }).toList(),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
