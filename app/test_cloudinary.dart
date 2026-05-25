import 'dart:io';

void main() async {
  final url = 'https://res.cloudinary.com/demo/image/upload/sample.jpg';
  try {
    final client = HttpClient();
    final request = await client.getUrl(Uri.parse(url));
    final response = await request.close();
    print('HttpClient status: ${response.statusCode}');
  } catch (e) {
    print('HttpClient error: $e');
  }
}
