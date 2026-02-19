import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../main.dart';

class LockPage extends StatefulWidget {
  const LockPage({super.key});

  @override
  State<LockPage> createState() => _LockPageState();
}

class _LockPageState extends State<LockPage> {
  final LocalAuthentication auth = LocalAuthentication();
  bool _isAuthenticating = false;
  String _message = "Unlock ReddMobile";

  @override
  void initState() {
    super.initState();
    _authenticate();
  }

  Future<void> _authenticate() async {
    setState(() { _isAuthenticating = true; _message = "Verifying Identity..."; });

    try {
      final bool canAuthenticate = await auth.canCheckBiometrics || await auth.isDeviceSupported();
      if (!canAuthenticate) {
        _unlockApp(); // Fallback if emulator/device lacks biometrics
        return;
      }

      final bool didAuthenticate = await auth.authenticate(
        localizedReason: 'Authenticate to access your cryptographic vault.',
        options: const AuthenticationOptions(stickyAuth: true, biometricOnly: false),
      );

      if (didAuthenticate) {
        _unlockApp();
      } else {
        setState(() { _isAuthenticating = false; _message = "Authentication Failed. Try Again."; });
      }
    } catch (e) {
      setState(() { _isAuthenticating = false; _message = "Error: System lock not available."; });
      Future.delayed(const Duration(seconds: 2), _unlockApp); // Safety fallback
    }
  }

  void _unlockApp() {
    if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MainNavigation()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 80, color: Color(0xFFE31B23)),
            const SizedBox(height: 20),
            Text(_message, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 40),
            if (!_isAuthenticating)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF151515), padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                onPressed: _authenticate,
                icon: const Icon(Icons.fingerprint, color: Colors.white),
                label: const Text("UNLOCK", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
      ),
    );
  }
}
