import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

// =========================================================
// 1. MY APP (Sekarang StatefulWidget untuk mengontrol Tema)
// =========================================================
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Secara default aplikasi dimulai dengan Tema Terang (Light)
  ThemeMode _themeMode = ThemeMode.light;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Weather App Premium',
      theme: ThemeData(
        fontFamily: 'Roboto',
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        fontFamily: 'Roboto',
        brightness: Brightness.dark,
      ),
      themeMode: _themeMode, // Mengikuti state tema yang aktif
      home: MainNavigationScreen(
        themeMode: _themeMode,
        onThemeChanged: (bool isDark) {
          setState(() {
            _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
          });
        },
      ),
    );
  }
}

// =========================================================
// 2. LAYAR NAVIGASI INDUK
// =========================================================
class MainNavigationScreen extends StatefulWidget {
  final ThemeMode themeMode;
  final ValueChanged<bool> onThemeChanged;

  const MainNavigationScreen({
    super.key, 
    required this.themeMode, 
    required this.onThemeChanged
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    // Daftar layar digenerate di dalam build agar selalu mendapatkan update tema terbaru
    final List<Widget> screens = [
      const WeatherHomeView(),  
      const ChartView(),        
      const LocationView(),     
      const SearchView(),       
      SettingsView(
        themeMode: widget.themeMode,
        onThemeChanged: widget.onThemeChanged,
      ),     
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[900] : Colors.white,
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 1),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: isDark ? Colors.grey[900] : Colors.white,
          elevation: 0,
          selectedItemColor: Colors.blue[700],
          unselectedItemColor: isDark ? Colors.grey[600] : Colors.grey[400],
          showSelectedLabels: false,
          showUnselectedLabels: false,
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_filled, size: 26), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.analytics_outlined, size: 26), label: 'Chart'),
            BottomNavigationBarItem(icon: Icon(Icons.location_on_outlined, size: 26), label: 'Location'),
            BottomNavigationBarItem(icon: Icon(Icons.map_outlined, size: 26), label: 'Map'),
            BottomNavigationBarItem(icon: Icon(Icons.settings_outlined, size: 26), label: 'Settings'),
          ],
        ),
      ),
    );
  }
}

// =========================================================
// 3. LAYAR BERANDA (Home) - Dengan Gradasi Warna Dinamis
// =========================================================
class WeatherHomeView extends StatefulWidget {
  const WeatherHomeView({super.key});

  @override
  State<WeatherHomeView> createState() => _WeatherHomeViewState();
}

class _WeatherHomeViewState extends State<WeatherHomeView> {
  bool isLoading = true;
  String cityName = "Jakarta"; 
  double temperature = 0.0;
  String weatherDescription = "";
  String weatherMain = "";
  List<Map<String, dynamic>> hourlyForecast = [];
  List<Map<String, dynamic>> dailyForecast = [];

  final String apiKey = "26ae76b8c63a8e30cc288a2a4a1241a7";

  @override
  void initState() {
    super.initState();
    fetchWeatherData(cityName);
  }

  Future<void> fetchWeatherData(String city) async {
    final currentWeatherUrl = Uri.parse('https://api.openweathermap.org/data/2.5/weather?q=$city&appid=$apiKey&units=metric&lang=id');
    final forecastUrl = Uri.parse('https://api.openweathermap.org/data/2.5/forecast?q=$city&appid=$apiKey&units=metric&lang=id');

    try {
      final responses = await Future.wait([http.get(currentWeatherUrl), http.get(forecastUrl)]);
      if (responses[0].statusCode == 200 && responses[1].statusCode == 200) {
        final currentData = json.decode(responses[0].body);
        final forecastData = json.decode(responses[1].body);

        cityName = currentData['name'];
        temperature = currentData['main']['temp'];
        weatherDescription = (currentData['weather'][0]['description']).toString().toTitleCase();
        weatherMain = currentData['weather'][0]['main'];

        List forecastList = forecastData['list'];
        List<Map<String, dynamic>> tempHourly = [];
        for (int i = 0; i < 5; i++) {
          var item = forecastList[i];
          DateTime date = DateTime.fromMillisecondsSinceEpoch(item['dt'] * 1000);
          tempHourly.add({
            'time': i == 0 ? '10:00' : "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}",
            'temp': '${item['main']['temp'].round()}°',
            'main': item['weather'][0]['main'],
          });
        }

        List<Map<String, dynamic>> tempDaily = [];
        List<String> namaHari = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
        for (int i = 0; i < forecastList.length; i += 8) {
          if (tempDaily.length >= 6) break;
          var item = forecastList[i];
          DateTime date = DateTime.fromMillisecondsSinceEpoch(item['dt'] * 1000);
          tempDaily.add({
            'day': namaHari[date.weekday - 1],
            'temp': '${item['main']['temp_min'].round()}°C - ${item['main']['temp_max'].round()}°C',
            'main': item['weather'][0]['main'],
          });
        }

        setState(() {
          hourlyForecast = tempHourly;
          dailyForecast = tempDaily;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  void _showSearchDialog() {
    TextEditingController searchController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        bool innerDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: innerDark ? Colors.grey[900] : Colors.blue[900]?.withOpacity(0.9),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Cari Kota Lain', style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: searchController,
            style: const TextStyle(color: Colors.white),
            autofocus: true,
            decoration: const InputDecoration(hintText: "Misal: Tokyo, London", hintStyle: TextStyle(color: Colors.white54)),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal', style: TextStyle(color: Colors.white70))),
            TextButton(
              onPressed: () {
                if (searchController.text.isNotEmpty) {
                  Navigator.pop(context);
                  setState(() => isLoading = true);
                  fetchWeatherData(searchController.text);
                }
              },
              child: const Text('Cari', style: TextStyle(color: Colors.yellowAccent)),
            ),
          ],
        );
      },
    );
  }

  IconData getWeatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear': return Icons.wb_sunny;
      case 'clouds': return Icons.wb_cloudy;
      case 'rain': return Icons.water_drop;
      case 'thunderstorm': return Icons.flash_on;
      default: return Icons.wb_cloudy;
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity, height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          // PERUBAHAN UI/UX: Warna latar belakang berubah lebih gelap saat malam/dark mode
          colors: isDark 
            ? [Colors.blueGrey[900]!, Colors.blueGrey[800]!, Colors.grey[900]!]
            : [Colors.blue[400]!, Colors.blue[300]!, Colors.blue[200]!, Colors.blue[100]!],
        ),
      ),
      child: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : RefreshIndicator(
                onRefresh: () => fetchWeatherData(cityName),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 35),
                      _buildHeroSection(),
                      const SizedBox(height: 25),
                      _buildInsightBox(),
                      const SizedBox(height: 20),
                      _buildHourlySection(),
                      const SizedBox(height: 20),
                      _buildDailySection(),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: _showSearchDialog,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
            child: Row(
              children: [
                const Icon(Icons.location_on, color: Colors.white, size: 22),
                const SizedBox(width: 6),
                Text(cityName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(width: 4),
                const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 20),
              ],
            ),
          ),
        ),
        const Icon(Icons.blur_circular, color: Colors.white, size: 24),
      ],
    );
  }

  Widget _buildHeroSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${temperature.round()}°c', style: const TextStyle(color: Colors.white, fontSize: 84, fontWeight: FontWeight.bold, height: 0.9)),
            const SizedBox(height: 10),
            Text(weatherDescription, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
            const Text('Hari Ini', style: TextStyle(color: Colors.white70, fontSize: 16)),
          ],
        ),
        Icon(getWeatherIcon(weatherMain), color: weatherMain.toLowerCase() == 'clear' ? Colors.yellowAccent : Colors.white, size: 110),
      ],
    );
  }

  Widget _buildInsightBox() {
    return _buildGlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: const [
          Icon(Icons.wb_sunny_rounded, color: Colors.yellowAccent, size: 24), SizedBox(width: 15),
          Expanded(child: Text('Ketuk nama kota di atas untuk pindah lokasi.', style: TextStyle(color: Colors.white, fontSize: 14))),
        ],
      ),
    );
  }

  Widget _buildHourlySection() {
    return _buildGlassContainer(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SizedBox(
        height: 110,
        child: ListView.builder(
          scrollDirection: Axis.horizontal, itemCount: hourlyForecast.length,
          itemBuilder: (context, index) {
            final data = hourlyForecast[index];
            bool isFirst = index == 0;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 6), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isFirst ? Colors.blue[700]!.withOpacity(0.4) : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: isFirst ? Border.all(color: Colors.white.withOpacity(0.4), width: 1.5) : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(data['time'], style: TextStyle(color: Colors.white, fontWeight: isFirst ? FontWeight.bold : FontWeight.normal)),
                  Icon(getWeatherIcon(data['main']), color: data['main'].toString().toLowerCase() == 'clear' ? Colors.yellowAccent : Colors.white, size: 22),
                  Text(data['temp'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDailySection() {
    return _buildGlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: dailyForecast.map((data) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(width: 100, child: Text(data['day'], style: const TextStyle(color: Colors.white, fontSize: 16))),
                Icon(getWeatherIcon(data['main']), color: Colors.white, size: 20),
                Text(data['temp'], style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGlassContainer({required Widget child, EdgeInsetsGeometry? padding}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.18),
            borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withOpacity(0.25), width: 1),
          ),
          child: child,
        ),
      ),
    );
  }
}

// =========================================================
// 4. LAYAR KEDUA: GRAFIK (Chart)
// =========================================================
class ChartView extends StatelessWidget {
  const ChartView({super.key});

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity, height: double.infinity,
      color: isDark ? Colors.grey[950] : Colors.grey[50],
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.analytics_outlined, size: 100, color: isDark ? Colors.blue[400] : Colors.blue),
              const SizedBox(height: 20),
              Text('Statistik Cuaca', style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text('Fitur grafik tren suhu segera hadir.', style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
            ],
          ),
        ),
      ),
    );
  }
}

// =========================================================
// 5. LAYAR KETIGA: LOKASI
// =========================================================
class LocationView extends StatelessWidget {
  const LocationView({super.key});

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity, height: double.infinity,
      color: isDark ? Colors.grey[950] : Colors.grey[50], 
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Daftar Kota', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
              const SizedBox(height: 20),
              _buildCityCard(context, 'Jakarta', '31°C', 'Cerah Berawan', Icons.wb_cloudy, Colors.blue),
              const SizedBox(height: 15),
              _buildCityCard(context, 'Denpasar', '30°C', 'Cerah', Icons.wb_sunny, Colors.orange),
              const SizedBox(height: 15),
              _buildCityCard(context, 'Surabaya', '32°C', 'Mendung', Icons.cloud, Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCityCard(BuildContext context, String city, String temp, String desc, IconData icon, Color iconColor) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white, 
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 40, color: iconColor),
              const SizedBox(width: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(city, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                  Text(desc, style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.grey[600])),
                ],
              ),
            ],
          ),
          Text(temp, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
        ],
      ),
    );
  }
}

// =========================================================
// 6. LAYAR KEEMPAT: MAP
// =========================================================
class SearchView extends StatelessWidget {
  const SearchView({super.key});

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity, height: double.infinity,
      color: isDark ? Colors.black : Colors.black87,
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // Baris yang benar
            children: const [
              Icon(Icons.map_outlined, size: 100, color: Colors.blueAccent),
              SizedBox(height: 20),
              Text('Peta Radar', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              Text('Integrasi Google Maps / Radar Hujan di sini.', style: TextStyle(color: Colors.white70)),
            ],
          ),
        ),
      ),
    );
  }
}

// =========================================================
// 7. LAYAR KELIMA: PENGATURAN (Ditambahkan Fitur Dark Mode)
// =========================================================
class SettingsView extends StatelessWidget {
  final ThemeMode themeMode;
  final ValueChanged<bool> onThemeChanged;

  const SettingsView({
    super.key, 
    required this.themeMode, 
    required this.onThemeChanged
  });

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity, height: double.infinity,
      color: isDark ? Colors.grey[950] : Colors.grey[50], // Beradaptasi sesuai tema aktif
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Pengaturan', 
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)
            ),
            const SizedBox(height: 20),
            
            // 1. Satuan Suhu
            ListTile(
              leading: Icon(Icons.thermostat, color: isDark ? Colors.blue[300] : Colors.blue), 
              title: Text('Satuan Suhu', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
              trailing: const Text('Celsius (°C)', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
              tileColor: isDark ? Colors.grey[900] : Colors.white, 
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
            const SizedBox(height: 10),
            
            // 2. Notifikasi Hujan
            ListTile(
              leading: Icon(Icons.notifications_active_outlined, color: isDark ? Colors.blue[300] : Colors.blue), 
              title: Text('Notifikasi Hujan', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
              trailing: Switch(value: true, onChanged: (val) {}, activeColor: Colors.blue),
              tileColor: isDark ? Colors.grey[900] : Colors.white, 
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
            const SizedBox(height: 10),
            
            // FITUR BARU: TOMBOL TAMPILAN GELAP (Di bawah Notifikasi Hujan)
            ListTile(
              leading: Icon(
                isDark ? Icons.dark_mode : Icons.light_mode, 
                color: isDark ? Colors.amber : Colors.orange
              ), 
              title: Text(
                'Tampilan Gelap (Dark Mode)', 
                style: TextStyle(color: isDark ? Colors.white : Colors.black87)
              ),
              trailing: Switch(
                value: themeMode == ThemeMode.dark, // Bernilai true jika themeMode adalah dark
                onChanged: onThemeChanged, // Memanggil fungsi callback untuk merubah tema utama
                activeColor: Colors.blue,
              ),
              tileColor: isDark ? Colors.grey[900] : Colors.white, 
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
          ],
        ),
      ),
    );
  }
}

extension StringCasingExtension on String {
  String toTitleCase() => replaceAll(RegExp(' +'), ' ').split(' ').map((str) => str.isNotEmpty ? str[0].toUpperCase() + str.substring(1) : '').join(' ');
}