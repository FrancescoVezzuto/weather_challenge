
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Meteo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.blue,
          accentColor: Colors.orangeAccent,
        ),
      ),
      home: const LaMiaHomePage(),
    );
  }
}

class Coordinates {
  final double latitude;
  final double longitude;

  Coordinates(this.latitude, this.longitude);
}

class MeteoData {
  final double temperature;
  final double windspeed;
  final String time;
  final int weathercode;
  final bool isDay;

  MeteoData(this.temperature, this.windspeed, this.time, this.weathercode, this.isDay);
}

class LaMiaHomePage extends StatefulWidget {
  const LaMiaHomePage({Key? key});

  @override
  _LaMiaHomePageState createState() => _LaMiaHomePageState();
}

class _LaMiaHomePageState extends State<LaMiaHomePage> {
  String _localita = '';
  String _titolo = '';
  String _gradi = '';
  String _vento = '';
  String _umidita = '';
  bool _mostraRicerca = true;
  String _sfondoImage = 'images/Parzialmente nuvoloso.jpeg';
  String _localitaTrovata = '';
  MeteoData? _meteoData;

  final Map<String, Coordinates> cityCoordinates = {
    'roma': Coordinates(41.9027835, 12.4963655),
    'napoli': Coordinates(40.8518, 14.2681),
    'milano': Coordinates(45.4654219, 9.1859243),
    'bologna': Coordinates(44.494887, 11.342616),
    'monte bianco': Coordinates(45.832622, 6.865175),
    'bari': Coordinates(41.117143, 16.871871),
    'potenza': Coordinates(40.640407, 15.805604),
    'larisa': Coordinates(39.6369, 22.4375),
  };

  Future<void> _eseguiRicerca() async {
    final localitaTrim = _localita.trim().toLowerCase();

    if (localitaTrim.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Non è stata inserita alcuna località',
            style: TextStyle(fontSize: 16),
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    if (!cityCoordinates.containsKey(localitaTrim)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Località non valida',
            style: TextStyle(fontSize: 16),
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    _caricaDatiMeteo(localitaTrim);
  }

  Future<void> _caricaDatiMeteo(String localitaTrim) async {
    Coordinates coordinates = cityCoordinates[localitaTrim]!;
    String apiUrl =
        'https://api.open-meteo.com/v1/forecast?latitude=${coordinates
        .latitude}&longitude=${coordinates
        .longitude}&hourly=temperature_2m,relativehumidity_2m,rain,snowfall,cloudcover_low,cloudcover_high,windspeed_10m,weathercode&current_weather=true&timezone=auto';

    try {
      final response = await http.get(Uri.parse(apiUrl));
      final jsonData = json.decode(response.body);
      print(jsonData);

      final meteoData = jsonData['current_weather'];

      final temperature = (meteoData['temperature'] ?? 0.0).toDouble();
      final windspeed = (meteoData['windspeed'] ?? 0.0).toDouble();
      final time = meteoData['time'] ?? '';
      final weathercode = (meteoData['weathercode'] ?? 0).toInt();

      // Effettua una seconda richiesta per ottenere l'umidità
      final humidityData = jsonData['hourly']['relativehumidity_2m'][0] ?? 0.0;
      final humidity = humidityData.toDouble();

      setState(() {
        _localitaTrovata = localitaTrim.toUpperCase();
        _titolo = localitaTrim;
        _gradi = temperature.toStringAsFixed(1) + '°C';
        _vento = windspeed.toStringAsFixed(1) + ' km/h';
        _umidita = humidity.toStringAsFixed(1) + '%'; // Mostra l'umidità
        _sfondoImage = _selezionaSfondo(weathercode);
        _mostraRicerca = false;
        _meteoData = MeteoData(temperature, windspeed, time, weathercode, true);
      });
    } catch (error) {
      setState(() {
        _titolo = 'Località non trovata';
        _gradi = '';
        _vento = '';
        _umidita = '';
        _sfondoImage = 'images/';
        _meteoData = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Località non trovata',
            style: TextStyle(fontSize: 16),
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  String _selezionaSfondo(int weathercode) {
    if (weathercode == 0) {
      return 'images/Soleggiato.webp';
    } else if (weathercode == 61) {
      return 'images/Temporale.jpeg';
    } else if (weathercode >= 30 && weathercode <= 36) {
      return 'images/Nuvoloso.jpeg';
    } else if (weathercode == 68) {
      return 'images/Neve.jpeg';
    } else if (weathercode == 85 || weathercode == 89) {
      return 'images/Piovoso.jpeg';
    } else {
      return 'images/Parzialmente nuvoloso.jpeg';
    }
  }

  void _tornaIndietro() {
    setState(() {
      _mostraRicerca = true;
      _localita = '';
      _meteoData = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null,
      body: _mostraRicerca
          ? Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal, Colors.tealAccent],
            // Qui puoi specificare i tuoi colori
            begin: Alignment.topLeft,
            // Puoi regolare la direzione del gradiente
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        _localita = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Inserisci la località',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.all(15),
                      fillColor: Colors.white,
                      filled: true,
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                    onPressed: _eseguiRicerca,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(
                          vertical: 15, horizontal: 30),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                    child: const Text('Cerca Meteo')
                ),
              ],
            ),
          ),
        ),
      )
          : Stack(
        children: [
          Image.asset(
            _sfondoImage,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
          ),
          Center(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                    ),
                    onPressed: _tornaIndietro,
                  ),
                  const SizedBox(height: 45),
                  Padding(
                    padding: const EdgeInsets.only(
                        left: 16, right: 15),
                    child: Text(
                      _titolo.isNotEmpty
                          ? _titolo.toUpperCase()
                          : 'In attesa di dati...',
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.only(
                        left: 16, right: 15),
                    child: Text(
                      _gradi,
                      style: const TextStyle(
                        fontSize: 110,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 300),
                  Padding(
                    padding: const EdgeInsets.only(
                        left: 15, right: 15),
                    child: Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            _localitaTrovata.isNotEmpty
                                ? _localitaTrovata.toUpperCase()
                                : 'In attesa di dati...',
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 25),
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    'Vento:',
                                    style: TextStyle(
                                      fontSize: 25,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    _vento,
                                    style: const TextStyle(
                                      fontSize: 25,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Text(
                                    'Umidità: $_umidita',
                                    style: const TextStyle(
                                      fontSize: 25,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}