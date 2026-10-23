import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:kombucha_app/datamanager.dart';

import 'package:kombucha_app/pages/calculator_page.dart';
import 'package:kombucha_app/pages/ingredients_page.dart';

import 'pages/receipe_page.dart';

const _bottomAdUnitId = String.fromEnvironment('PAGE_BOTTOM_AD_ID');
const _drawerAdUnitId = String.fromEnvironment('AD_BANNER_DRAWER_ID');

bool get _supportsMobileAds =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) &&
    (_adUnitId(_bottomAdUnitId).isNotEmpty ||
        _adUnitId(_drawerAdUnitId).isNotEmpty);

String _adUnitId(String configuredId) {
  if (configuredId.isNotEmpty) return configuredId;
  if (kReleaseMode) return '';
  return defaultTargetPlatform == TargetPlatform.iOS
      ? 'ca-app-pub-3940256099942544/2435281174'
      : 'ca-app-pub-3940256099942544/9214589741';
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kombucha Club',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: const MyHomePage(title: 'Kombucha Making Toolkit'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var dataManager = DataManager();
  var selectedIndex = 0;
  BannerAd? _anchoredAdaptiveAd;
  BannerAd? _adBannerDrawer;
  bool _isBottomBannerAdLoaded = false;
  bool _isDrawerAdLoaded = false;
  int? _bottomBannerWidth;
  int _bottomBannerGeneration = 0;
  Timer? _bottomBannerRetry;
  Timer? _drawerRetry;
  int _bottomBannerFailures = 0;
  int _drawerFailures = 0;
  bool _adsStarted = false;
  bool _adsStarting = false;
  bool _mobileAdsInitialized = false;
  bool _privacyOptionsRequired = false;

  @override
  void initState() {
    super.initState();

    if (_supportsMobileAds) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _prepareAds());
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_adsStarted) _loadBottomBannerAd();
  }

  void _prepareAds() {
    if (!mounted) return;
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () {
        _syncAdPermission();
        _refreshPrivacyOptions();
        ConsentForm.loadAndShowConsentFormIfRequired((_) {
          _syncAdPermission();
          _refreshPrivacyOptions();
        });
      },
      (_) => _syncAdPermission(),
    );
  }

  Future<void> _refreshPrivacyOptions() async {
    try {
      final status = await ConsentInformation.instance
          .getPrivacyOptionsRequirementStatus();
      if (mounted) {
        setState(() => _privacyOptionsRequired =
            status == PrivacyOptionsRequirementStatus.required);
      }
    } catch (_) {
      // Keep the current entry point if the status cannot be refreshed.
    }
  }

  Future<void> _syncAdPermission() async {
    bool canRequestAds;
    try {
      canRequestAds = await ConsentInformation.instance.canRequestAds();
    } catch (_) {
      canRequestAds = false;
    }
    if (!mounted || !_supportsMobileAds) return;
    if (!canRequestAds) {
      if (_adsStarted) {
        ++_bottomBannerGeneration;
        _bottomBannerRetry?.cancel();
        _drawerRetry?.cancel();
        _bottomBannerFailures = 0;
        _drawerFailures = 0;
        _anchoredAdaptiveAd?.dispose();
        _adBannerDrawer?.dispose();
        setState(() {
          _adsStarted = false;
          _anchoredAdaptiveAd = null;
          _adBannerDrawer = null;
          _isBottomBannerAdLoaded = false;
          _isDrawerAdLoaded = false;
          _bottomBannerWidth = null;
        });
      }
      return;
    }
    if (_adsStarted || _adsStarting) return;
    _adsStarting = true;
    if (!_mobileAdsInitialized) {
      try {
        await MobileAds.instance.initialize();
        _mobileAdsInitialized = true;
      } catch (_) {
        _adsStarting = false;
        return;
      }
    }
    bool stillAllowed;
    try {
      stillAllowed = await ConsentInformation.instance.canRequestAds();
    } catch (_) {
      stillAllowed = false;
    }
    _adsStarting = false;
    if (!mounted || !stillAllowed) return;
    _adsStarted = true;
    _loadDrawerAd();
    _loadBottomBannerAd();
  }

  Future<void> _loadBottomBannerAd() async {
    if (!_adsStarted) return;
    final width = MediaQuery.sizeOf(context).width.truncate();
    if (width <= 0 || width == _bottomBannerWidth) return;
    _bottomBannerWidth = width;
    final generation = ++_bottomBannerGeneration;
    final oldAd = _anchoredAdaptiveAd;
    _anchoredAdaptiveAd = null;
    _isBottomBannerAdLoaded = false;
    oldAd?.dispose();

    final adUnitId = _adUnitId(_bottomAdUnitId);
    if (adUnitId.isEmpty) return;

    final AnchoredAdaptiveBannerAdSize? size =
        await AdSize.getLargeAnchoredAdaptiveBannerAdSize(width);

    if (!mounted ||
        !_adsStarted ||
        generation != _bottomBannerGeneration ||
        size == null) {
      if (mounted && generation == _bottomBannerGeneration && size == null) {
        _bottomBannerWidth = null;
        _retryBottomBanner();
      }
      return;
    }

    final banner = BannerAd(
      adUnitId: adUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          if (!mounted || !identical(_anchoredAdaptiveAd, ad)) {
            ad.dispose();
            return;
          }
          setState(() {
            _isBottomBannerAdLoaded = true;
          });
          _bottomBannerFailures = 0;
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          ad.dispose();
          if (mounted && identical(_anchoredAdaptiveAd, ad)) {
            setState(() {
              _anchoredAdaptiveAd = null;
              _isBottomBannerAdLoaded = false;
              _bottomBannerWidth = null;
            });
            _retryBottomBanner();
          }
        },
      ),
    );
    _anchoredAdaptiveAd = banner;
    banner.load();
  }

  void _retryBottomBanner() {
    if (!_adsStarted || _bottomBannerFailures >= 3) return;
    _bottomBannerFailures++;
    _bottomBannerRetry?.cancel();
    _bottomBannerRetry = Timer(
      Duration(seconds: 30 * _bottomBannerFailures),
      () {
        if (mounted && _adsStarted) _loadBottomBannerAd();
      },
    );
  }

  void _loadDrawerAd() {
    if (!_adsStarted) return;
    final adUnitId = _adUnitId(_drawerAdUnitId);
    if (adUnitId.isEmpty) return;
    final banner = BannerAd(
      adUnitId: adUnitId,
      size: AdSize.mediumRectangle,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          if (!mounted || !identical(_adBannerDrawer, ad)) {
            ad.dispose();
            return;
          }
          setState(
            () {
              _isDrawerAdLoaded = true;
            },
          );
          _drawerFailures = 0;
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          ad.dispose();
          if (mounted && identical(_adBannerDrawer, ad)) {
            setState(() {
              _adBannerDrawer = null;
              _isDrawerAdLoaded = false;
            });
            _retryDrawerAd();
          }
        },
      ),
    );

    _adBannerDrawer = banner;
    banner.load();
  }

  void _retryDrawerAd() {
    if (!_adsStarted || _drawerFailures >= 3) return;
    _drawerFailures++;
    _drawerRetry?.cancel();
    _drawerRetry = Timer(Duration(seconds: 30 * _drawerFailures), () {
      if (mounted && _adsStarted) _loadDrawerAd();
    });
  }

  @override
  void dispose() {
    ++_bottomBannerGeneration;
    _bottomBannerRetry?.cancel();
    _drawerRetry?.cancel();
    _anchoredAdaptiveAd?.dispose();
    _adBannerDrawer?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    late Widget currentPage;
    late String pageTitle;

    switch (selectedIndex) {
      case 0:
        currentPage = const IngredientsPage();
        pageTitle = "Ingredients";
        break;
      case 1:
        currentPage = ReceipePage(dataManager: dataManager);
        pageTitle = "Receipe";
        break;
      case 2:
        currentPage = const CalculatorPage();
        pageTitle = "Proportions";
        break;
    }

    tapHandler(int index, BuildContext context) {
      setState(
        () {
          selectedIndex = index;
        },
      );
      Navigator.pop(context);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(pageTitle),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Colors.green,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32.0),
                child: Text(
                  widget.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                  ),
                ),
              ),
            ),
            DrawerListItem(
              index: 0,
              icon: Icons.restaurant,
              name: "Ingredients",
              onTap: (index) => {
                tapHandler(index, context),
              },
            ),
            DrawerListItem(
              index: 1,
              icon: Icons.menu_book,
              name: "Receipe",
              onTap: (index) => {
                tapHandler(index, context),
              },
            ),
            DrawerListItem(
              index: 2,
              icon: Icons.calculate,
              name: "Proportions",
              onTap: (index) => {
                tapHandler(index, context),
              },
            ),
            if (_privacyOptionsRequired)
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text('Privacy options'),
                onTap: () {
                  Navigator.pop(context);
                  ConsentForm.showPrivacyOptionsForm((_) {
                    _syncAdPermission();
                    _refreshPrivacyOptions();
                  });
                },
              ),
            if (_adBannerDrawer != null && _isDrawerAdLoaded)
              Container(
                alignment: Alignment.center,
                width: _adBannerDrawer?.size.width.toDouble(),
                height: _adBannerDrawer?.size.height.toDouble(),
                child: AdWidget(
                  ad: _adBannerDrawer!,
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar:
          _anchoredAdaptiveAd != null && _isBottomBannerAdLoaded
              ? Container(
                  alignment: Alignment.center,
                  width: _anchoredAdaptiveAd!.size.width.toDouble(),
                  height: _anchoredAdaptiveAd!.size.height.toDouble(),
                  child: AdWidget(
                    ad: _anchoredAdaptiveAd!,
                  ),
                )
              : null,
      body: currentPage,
    );
  }
}

class DrawerListItem extends StatelessWidget {
  final int index;
  final IconData icon;
  final String name;
  final Function(int index) onTap;

  const DrawerListItem(
      {super.key,
      required this.index,
      required this.icon,
      required this.name,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(
        name,
        style: const TextStyle(
          fontSize: 16,
        ),
      ),
      onTap: () => onTap(index),
    );
  }
}
