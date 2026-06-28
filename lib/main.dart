import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Aplikasi Cuaca',
      theme: ThemeData(
        fontFamily: 'Roboto',
      ),
      home: const WeatherHomeScreen(),
    );
  }
}

class WeatherHomeScreen extends StatefulWidget {
  const WeatherHomeScreen({super.key});

  @override
  State<WeatherHomeScreen> createState() => _WeatherHomeScreenState();
}

class _WeatherHomeScreenState extends State<WeatherHomeScreen> {
  bool isLoading = true;
  String cityName = "Memuat...";
  double temperature = 0.0;
  String weatherDescription = "";
  String weatherMain = "";

  // List baru untuk menyimpan data ramalan cuaca dinamis
  List<Map<String, dynamic>> hourlyForecast = [];
  List<Map<String, dynamic>> dailyForecast = [];
  
  // Kunci API Anda yang sudah aktif
  final String apiKey = "26ae76b8c63a8e30cc288a2a4a1241a7"; 
  final String targetCity = "Jakarta"; 

  @override
  void initState() {
    super.initState();
    fetchAllWeatherData();
  }

  // Fungsi untuk mengambil data Cuaca Sekarang & Data Prakiraan sekaligus
  Future<void> fetchAllWeatherData() async {
    // URL 1: Cuaca Saat Ini
    final currentWeatherUrl = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?q=$targetCity&appid=$apiKey&units=metric&lang=id');
    
    // URL 2: Prakiraan 5 Hari / 3 Jam ke depan
    final forecastUrl = Uri.parse(
        'https://api.openweathermap.org/data/2.5/forecast?q=$targetCity&appid=$apiKey&units=metric&lang=id');

    try {
      // Menjalankan kedua request API secara bersamaan agar efisien
      final responses = await Future.wait([
        http.get(currentWeatherUrl),
        http.get(forecastUrl),
      ]);

      final currentWeatherResponse = responses[0];
      final forecastResponse = responses[1];

      if (currentWeatherResponse.statusCode == 200 && forecastResponse.statusCode == 200) {
        final currentData = json.decode(currentWeatherResponse.body);
        final forecastData = json.decode(forecastResponse.body);

        // 1. Parsing Data Cuaca Sekarang
        cityName = currentData['name'];
        temperature = currentData['main']['temp'];
        weatherDescription = (currentData['weather'][0]['description']).toString().toTitleCase();
        weatherMain = currentData['weather'][0]['main'];

        // 2. Parsing Data Per Jam (Ambil 5 slot waktu pertama dari API)
        List forecastList = forecastData['list'];
        List<Map<String, dynamic>> tempHourly = [];
        
        for (int i = 0; i < 5; i++) {
          var item = forecastList[i];
          // Mengubah timestamp unix menjadi jam format lokal (HH:mm)
          DateTime date = DateTime.fromMillisecondsSinceEpoch(item['dt'] * 1000);
          String timeStr = "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
          
          tempHourly.add({
            'time': i == 0 ? 'Sekarang' : timeStr,
            'temp': '${item['main']['temp'].round()}°',
            'main': item['weather'][0]['main'],
          });
        }

        // 3. Parsing Data Harian
        // Karena API gratis menyediakan data per 3 jam, kita lompat setiap 8 data (8 x 3 jam = 24 jam) 
        // untuk mendapatkan cuaca di hari-hari berikutnya.
        List<Map<String, dynamic>> tempDaily = [];
        List<String> namaHari = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];

        for (int i = 8; i < forecastList.length; i += 8) {
          var item = forecastList[i];
          DateTime date = DateTime.fromMillisecondsSinceEpoch(item['dt'] * 1000);
          String hari = namaHari[date.weekday - 1];

          tempDaily.add({
            'day': hari,
            'temp': '${item['main']['temp_min'].round()}°C - ${item['main']['temp_max'].round()}°C',
            'main': item['weather'][0]['main'],
          });
        }

        setState(() {
          hourlyForecast = tempHourly;
          dailyForecast = tempDaily;
          isLoading = false;
        });

      } else {
        setState(() {
          cityName = "Gagal memuat data API";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        cityName = "Kesalahan Jaringan";
        isLoading = false;
      });
      print("Error: $e");
    }
  }

  // Helper untuk menentukan ikon cuaca bawaan Flutter
  IconData getWeatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear': return Icons.wb_sunny;
      case 'clouds': return Icons.wb_cloudy;
      case 'rain': return Icons.water_drop;
      case 'thunderstorm': return Icons.flash_on;
      case 'drizzle': return Icons.cloudy_snowing;
      default: return Icons.wb_cloudy;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue[500]!,
              Colors.blue[300]!,
              Colors.blue[100]!,
            ],
          ),
        ),
        child: SafeArea(
          child: isLoading 
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : RefreshIndicator(
              onRefresh: fetchAllWeatherData, // Fitur tarik ke bawah untuk refresh data
              color: Colors.blue,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 30),
                    _buildHeroSection(),
                    const SizedBox(height: 20),
                    _buildInsightBox(),
                    const SizedBox(height: 20),
                    _buildHourlyForecast(), 
                    const SizedBox(height: 20),
                    _buildDailyForecast(),  
                  ],
                ),
              ),
            ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Icon(Icons.location_on, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              cityName,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const Icon(Icons.settings_outlined, color: Colors.white),
      ],
    );
  }

  Widget _buildHeroSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${temperature.round()}°',
                style: const TextStyle(color: Colors.white, fontSize: 72, fontWeight: FontWeight.bold, height: 1.0),
              ),
              const SizedBox(height: 8),
              Text(
                weatherDescription,
                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600),
              ),
              const Text(
                'Hari Ini',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ],
          ),
        ),
        Icon(
          getWeatherIcon(weatherMain),
          color: weatherMain.toLowerCase() == 'clear' ? Colors.yellowAccent : Colors.white,
          size: 100,
        ),
      ],
    );
  }

  Widget _buildInsightBox() {
    String tipMessage = "Hari yang menyenangkan! Nikmati aktivitas Anda.";
    if (weatherMain.toLowerCase() == 'rain' || weatherMain.toLowerCase() == 'drizzle') {
      tipMessage = "Sedia payung sebelum keluar rumah, ya!";
    } else if (weatherMain.toLowerCase() == 'clear') {
      tipMessage = "Cuaca cukup terik, jangan lupa gunakan tabir surya.";
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb_outline, color: Colors.yellowAccent, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              tipMessage, // REKOMENDASI PINNTAR BERDASARKAN API CUACA
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  // WIDGET JAM-JAMAN SUDAH 100% DINAMIS
  Widget _buildHourlyForecast() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: SizedBox(
        height: 100,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: hourlyForecast.length,
          itemBuilder: (context, index) {
            final data = hourlyForecast[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(data['time']!, style: const TextStyle(color: Colors.white)),
                  Icon(
                    getWeatherIcon(data['main']),
                    color: data['main'].toString().toLowerCase() == 'clear' ? Colors.yellowAccent : Colors.white,
                  ),
                  Text(
                    data['temp']!,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // WIDGET HARIAN SUDAH 100% DINAMIS
  Widget _buildDailyForecast() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: dailyForecast.map((data) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: 90, 
                  child: Text(data['day']!, style: const TextStyle(color: Colors.white, fontSize: 16))
                ),
                Icon(
                  getWeatherIcon(data['main']), 
                  color: data['main'].toString().toLowerCase() == 'clear' ? Colors.yellowAccent : Colors.white, 
                  size: 20
                ),
                Text(
                  data['temp']!, 
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      color: Colors.white,
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: Colors.blue[800],
        unselectedItemColor: Colors.grey,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.show_chart), label: 'Chart'),
          BottomNavigationBarItem(icon: Icon(Icons.location_on_outlined), label: 'Location'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}

extension StringCasingExtension on String {
  String toTitleCase() => replaceAll(RegExp(' +'), ' ').split(' ').map((str) => str.isNotEmpty ? str[0].toUpperCase() + str.substring(1) : '').join(' ');
}