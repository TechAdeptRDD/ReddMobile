import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class IPFSService {
  // For production, these should be securely injected via environment variables.
  // We are using Pinata as the standard IPFS pinning provider.
  final String _pinataApiKey = "YOUR_PINATA_API_KEY";
  final String _pinataSecretKey = "YOUR_PINATA_SECRET_KEY";
  final String _pinataUrl = "https://api.pinata.cloud/pinning/pinFileToIPFS";

  /// Uploads an image file to IPFS and returns the CID.
  Future<String> uploadAvatar(File imageFile) async {
    try {
      // 1. Prepare the multipart HTTP request
      var request = http.MultipartRequest("POST", Uri.parse(_pinataUrl));
      
      // 2. Attach the Pinata authentication headers
      request.headers.addAll({
        'pinata_api_key': _pinataApiKey,
        'pinata_secret_api_key': _pinataSecretKey,
      });

      // 3. Attach the image file
      var multipartFile = await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
      );
      request.files.add(multipartFile);

      // 4. Send the payload to the IPFS network
      var response = await request.send();
      var responseData = await response.stream.toBytes();
      var responseString = String.fromCharCodes(responseData);

      if (response.statusCode == 200) {
        final jsonData = json.decode(responseString);
        return jsonData['IpfsHash']; // This is the CID we write to the blockchain
      } else {
        throw Exception("IPFS Upload Failed: $responseString");
      }
    } catch (e) {
      print("IPFS Service Error: $e");
      rethrow;
    }
  }
}
