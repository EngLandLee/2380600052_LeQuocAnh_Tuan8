import 'package:flutter_dotenv/flutter_dotenv.dart';

class ConfigUrl {
  static String get baseUrl {
    final url = dotenv.env['BASE_URL'];
    if (url == null || url.isEmpty) {
      return "http://localhost:5000/api/";
    }
    return url;
  }
}
