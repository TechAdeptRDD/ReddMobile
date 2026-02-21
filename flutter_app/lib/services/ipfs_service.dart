import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class IpfsService {
  // Inject token via --dart-define=PINATA_JWT=... at build/runtime.
  final String _pinataJwt;

  IpfsService({String? pinataJwt})
      : _pinataJwt = pinataJwt ?? const String.fromEnvironment('PINATA_JWT');

  Future<String?> uploadAvatar(File imageFile) async {
    if (_pinataJwt.isEmpty || _pinataJwt == 'YOUR_COMMUNITY_PINATA_JWT_PLACEHOLDER') {
      return null;
    }

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.pinata.cloud/pinning/pinFileToIPFS'),
      );

      request.headers.addAll({
        'Authorization': 'Bearer $_pinataJwt',
        'Accept': 'application/json',
      });

      request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      final response = await request.send().timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final json = jsonDecode(responseData);
        return json['IpfsHash']?.toString();
      }
    } on Exception {
      // Prevent leaking internal details.
    }
    return null;
  }
}
