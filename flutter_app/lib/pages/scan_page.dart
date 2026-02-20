import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../widgets/send_dialog.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});
  @override State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  bool _isProcessing = false;

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
      setState(() => _isProcessing = true);
      String raw = barcodes.first.rawValue!;
      
      // Parse deep link redd://pay?user=@handle OR raw address
      String parsedAddress = raw;
      if (raw.startsWith('redd://pay?user=')) {
        parsedAddress = raw.replaceAll('redd://pay?user=', '');
      }

      Navigator.pop(context); // Close scanner
      
      // Open Send Dialog pre-filled with the scanned target
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => SendDialog(initialRecipient: parsedAddress),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text("Scan ReddCard", style: TextStyle(color: Colors.white)), backgroundColor: Colors.transparent, elevation: 0, iconTheme: const IconThemeData(color: Colors.white)),
      body: Stack(
        alignment: Alignment.center,
        children: [
          MobileScanner(
            onDetect: _onDetect,
             borderRadius: 10, borderLength: 30, borderWidth: 10, cutOutSize: 250),
          ),
          const Positioned(bottom: 50, child: Text("Align QR code within the frame", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
}

// Helper class for the UI overlay frame
class QRScannerOverlayShape extends OverlayShape {
  final Color borderColor;
  final double borderRadius;
  final double borderLength;
  final double borderWidth;
  final double cutOutSize;

  QRScannerOverlayShape({this.borderColor = Colors.white, this.borderRadius = 0, this.borderLength = 0, this.borderWidth = 0, this.cutOutSize = 250});

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => Path()..addRect(Rect.fromCenter(center: rect.center, width: cutOutSize, height: cutOutSize));

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) => Path()..addRect(rect);

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final paint = Paint()..color = Colors.black54..style = PaintingStyle.fill;
    canvas.drawPath(Path.combine(PathOperation.difference, getOuterPath(rect), getInnerPath(rect)), paint);
    
    final borderPaint = Paint()..color = borderColor..style = PaintingStyle.stroke..strokeWidth = borderWidth;
    final cutOutRect = Rect.fromCenter(center: rect.center, width: cutOutSize, height: cutOutSize);
    canvas.drawRRect(RRect.fromRectAndRadius(cutOutRect, Radius.circular(borderRadius)), borderPaint);
  }
}
