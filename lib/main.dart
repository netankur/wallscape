import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'screens/splash_screen.dart';

// Global States
ValueNotifier<List<dynamic>> favoriteWallpapers = ValueNotifier([]);
ValueNotifier<bool> isInfiniteScrollEnabled = ValueNotifier(true);
ValueNotifier<String> imageQualityConfig = ValueNotifier('Original (Raw)');
ValueNotifier<String> appThemeConfig = ValueNotifier('Deep Onyx');

late SharedPreferences prefs;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  prefs = await SharedPreferences.getInstance();
  
  // Load Persistent Favorites on Startup
  String? savedFavs = prefs.getString('wallscape_favorites');
  if (savedFavs != null) {
    favoriteWallpapers.value = jsonDecode(savedFavs);
  }

  runApp(const WallscapeApp());
}

class WallscapeApp extends StatelessWidget {
  const WallscapeApp({Key? key}) : super(key: key);

  ThemeData _getTheme(String themeName, BuildContext context) {
    final baseTextTheme = GoogleFonts.montserratTextTheme(Theme.of(context).textTheme);
    Color bgColor = const Color(0xFF070707); 
    Color primaryColor = const Color(0xFFD4AF37); // Classic Gold

    if (themeName == 'Midnight Blue') {
      bgColor = const Color(0xFF040B16);
      primaryColor = const Color(0xFF4DB8FF);
    } else if (themeName == 'Platinum Classic') {
      bgColor = const Color(0xFF1A1A1D);
      primaryColor = const Color(0xFFE5E4E2);
    }

    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgColor,
      colorScheme: ColorScheme.dark(primary: primaryColor, secondary: const Color(0xFFE5E4E2)),
      textTheme: baseTextTheme.apply(bodyColor: Colors.white70, displayColor: Colors.white),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: GoogleFonts.playfairDisplay(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w600, letterSpacing: 1.2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: appThemeConfig,
      builder: (context, currentTheme, child) {
        return MaterialApp(
          title: 'Wallscape',
          debugShowCheckedModeBanner: false,
          theme: _getTheme(currentTheme, context),
          home: const SplashScreen(), // Ensure you change 'AuraX' to 'Wallscape' in your splash_screen.dart too!
        );
      },
    );
  }
}
