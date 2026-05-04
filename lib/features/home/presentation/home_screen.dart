import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../recipes/presentation/feed_screen.dart';
import '../../recipes/presentation/user_recipes_screen.dart';
import '../../dictionary/presentation/dictionary_screen.dart';
import '../../social/presentation/ranking_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../recipes/presentation/recipe_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;
  final List<Widget> _screens = [
    const FeedScreen(), // Vista principal de recetas
    const DictionaryScreen(), // Categorías y A-Z
    const UserRecipesScreen(), // Mis recetas subidas
    const RankingScreen(), // Rankings de usuarios y recetas
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
              if (_currentIndex == index && index == 0) {
                // Si presionan "Inicio" estando ya en "Inicio", reiniciamos los filtros
                ref.read(feedCategoryProvider.notifier).state = 'Todas';
                ref.read(feedSearchQueryProvider.notifier).state = '';
              }
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
                icon: Icon(Icons.receipt_long_outlined, size: 32),
                selectedIcon: Icon(Icons.receipt_long, size: 32),
                label: 'Mis Recetas',
              ),
              NavigationDestination(
                icon: Icon(Icons.emoji_events_outlined, size: 32),
                selectedIcon: Icon(Icons.emoji_events, size: 32),
                label: 'Ranking',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
