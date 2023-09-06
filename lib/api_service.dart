import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl;

  ApiService(this.baseUrl);

  Future<MeteoData> fetchMeteo(String localita) async {
    final response = await http.get(Uri.parse('$baseUrl/meteo?localita=$localita'));

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      return MeteoData.fromJson(jsonData);
    } else {
      throw Exception('Errore durante la chiamata API');
    }
  }
}

class MeteoData {
  final String titolo;
  final String gradi;
  final String vento;
  final String umidita;

  MeteoData({
    required this.titolo,
    required this.gradi,
    required this.vento,
    required this.umidita,
  });

  factory MeteoData.fromJson(Map<String, dynamic> json) {
    return MeteoData(
      titolo: json['titolo'],
      gradi: json['gradi'],
      vento: json['vento'],
      umidita: json['umidita'],
    );
  }
}