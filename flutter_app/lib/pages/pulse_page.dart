import 'package:flutter/material.dart';
import '../services/pulse_service.dart';

class PulsePage extends StatelessWidget {
  const PulsePage({super.key});

  @override
  Widget build(BuildContext context) {
    final PulseService _pulse = PulseService();

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
          title: const Text("Global Pulse",
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.transparent),
      body: FutureBuilder<List<Map<String, String>>>(
        future: _pulse.getGlobalPulse(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(
                child: CircularProgressIndicator(color: Color(0xFFE31B23)));
          if (snapshot.data!.isEmpty)
            return const Center(
                child: Text("Waiting for the next heartbeat...",
                    style: TextStyle(color: Colors.grey)));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final item = snapshot.data![index];
              return Card(
                color: const Color(0xFF151515),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                child: ListTile(
                  leading: const Icon(Icons.bolt, color: Colors.amber),
                  title: Text(item["message"]!,
                      style:
                          const TextStyle(color: Colors.white, fontSize: 14)),
                  subtitle: Text("TX: ${item["txid"]!.substring(0, 12)}...",
                      style: const TextStyle(color: Colors.grey, fontSize: 11)),
                  trailing: Text("${item["value"]} RDD",
                      style: const TextStyle(
                          color: Colors.greenAccent,
                          fontWeight: FontWeight.bold)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
