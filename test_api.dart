import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final response = await http.post(
    Uri.parse('https://dreamerscast.com/'),
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
      'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
    },
    body: {
      'search': '',
      'pageNumber': '1',
      'pageSize': '16',
      'status': '',
    },
  );

  if (response.statusCode == 200) {
    try {
      final data = jsonDecode(response.body);
      final releases = data['releases'] as List;
      print('Total ongoing releases returned: ${releases.length}');
      for (var r in releases.take(3)) {
        print('Release: id=${r['id']}, poster=${r['poster']}, image=${r['image']}, title=${r['russian']}');
      }
    } catch (e) {
      print('JSON Parse Error: $e');
    }
  } else {
    print('Failed: ${response.statusCode}');
  }
}
