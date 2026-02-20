import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

class IpfsService {
  // In production, this should be fetched from a secure community backend or hidden via proxy
  // to prevent scraping, but this architecture directly interfaces with Pinata IPFS.
  final String _pinataJwt = "YOUR_COMMUNITY_PINATA_JWT_PLACEHOLDER";

  Future<String?> uploadAvatar(File imageFile) async {
    try {
      var request = http.MultipartRequest(
          "POST", Uri.parse("https://api.pinata.cloud/pinning/pinFileToIPFS"));

      request.headers.addAll({
        "Authorization": "Bearer $_pinataJwt",
      });

      request.files
          .add(await http.MultipartFile.fromPath("file", imageFile.path));

      var response = await request.send();

      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        var json = jsonDecode(responseData);
        return json["IpfsHash"]; // Returns the decentralized CID!
      } else {
        print("IPFS Node Rejected Upload: ${response.statusCode}");
      }
    } catch (e) {
      print("IPFS Upload Error: $e");
    }
    return null;
  }
}
