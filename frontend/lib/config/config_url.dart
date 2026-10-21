import 'package:flutter_dotenv/flutter_dotenv.dart';

class ConfigUrl {
  static String get baseUrl {
    if (dotenv.isInitialized) {
      final url = dotenv.env['BASE_URL'];
      if (url != null && url.isNotEmpty) {
        return url;
      }
    }
    return "http://localhost:5000/api/";
  }
}
