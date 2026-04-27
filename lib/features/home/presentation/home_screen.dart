import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../recipes/presentation/feed_screen.dart';
import '../../dictionary/presentation/dictionary_screen.dart';
import '../../settings/presentation/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;

  final List<Widget> _screens = [
    const FeedScreen(), // Vista principal de recetas
    const DictionaryScreen(), // Categorías y A-Z
    const SettingsScreen(), // Ajustes (Accesibilidad/Temas)
  ];

  @override
  void initState() {
    super.initState();
    _initAdMob();
  }

  void _initAdMob() {
    MobileAds.instance.initialize();
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-3940256099942544/6300978111', // Test Banner ID
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {
            _isBannerAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          print('Error cargando banner: $error');
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isBannerAdLoaded && _bannerAd != null)
            SizedBox(
              height: _bannerAd!.size.height.toDouble(),
              width: _bannerAd!.size.width.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            ),
          NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined, size: 32),
                selectedIcon: Icon(Icons.home, size: 32),
                label: 'Inicio',
              ),
              NavigationDestination(
                icon: Icon(Icons.sort_by_alpha, size: 32),
                selectedIcon: Icon(Icons.sort_by_alpha, size: 32),
                label: 'Diccionario',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_outlined, size: 32),
                selectedIcon: Icon(Icons.settings, size: 32),
                label: 'Ajustes',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
