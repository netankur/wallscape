import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main.dart'; // Accesses global appThemeConfig, imageQualityConfig, etc.

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final List<String> qualityOptions = ['Original (Raw)', 'Large (4K)', 'Medium (HD)'];
  final List<String> themeOptions = ['Deep Onyx', 'Midnight Blue', 'Platinum Classic'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Preferences'),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        children: [
          _buildSectionHeader('Preference'),
          _buildSettingsCard(
            children: [
              // Image Quality Dropdown
              _buildDropdownItem(
                icon: CupertinoIcons.photo_on_rectangle,
                title: 'Download Quality',
                value: imageQualityConfig.value,
                options: qualityOptions,
                onChanged: (val) {
                  setState(() => imageQualityConfig.value = val!);
                },
              ),
              _buildDivider(),
              
              // App Theme Dropdown connected to Global State
              _buildDropdownItem(
                icon: CupertinoIcons.paintbrush,
                title: 'App Theme Color',
                value: appThemeConfig.value,
                options: themeOptions,
                onChanged: (val) {
                  setState(() => appThemeConfig.value = val!);
                  
                  // Clear previous snackbars to prevent stacking delays
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "$val theme applied",
                        style: const TextStyle(
                          color: Colors.white, // Forces white text so it never blends
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      backgroundColor: const Color(0xFF2C2C2C),
                      behavior: SnackBarBehavior.floating,
                      margin: const EdgeInsets.only(bottom: 20, left: 24, right: 24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.white.withOpacity(0.1)),
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
              _buildDivider(),
              
              // Infinite Scroll Toggle connected to Global State
              ValueListenableBuilder<bool>(
                valueListenable: isInfiniteScrollEnabled,
                builder: (context, isEnabled, _) {
                  return _buildToggleItem(
                    icon: CupertinoIcons.arrow_up_down_square,
                    title: 'Infinity Scrolling',
                    subtitle: 'Load wallpapers continuously',
                    value: isEnabled,
                    onChanged: (val) => isInfiniteScrollEnabled.value = val,
                  );
                }
              ),
            ],
          ),
          const SizedBox(height: 30),
          
          // About Section
          _buildSectionHeader('About'),
          _buildSettingsCard(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 30),
                child: Column(
                  children: [
                    Text(
                      'WALLSCAPE', 
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 26, 
                        fontWeight: FontWeight.bold, 
                        letterSpacing: 8, 
                        color: Theme.of(context).colorScheme.primary
                      )
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'First Edition • v1.1.0', 
                      style: TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 1)
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Curated by NetAnkur', 
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14)
                    ),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // --- UI Helper Methods ---

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Colors.white54, 
          fontSize: 11, 
          fontWeight: FontWeight.w600, 
          letterSpacing: 2
        ),
      ),
    );
  }

  Widget _buildSettingsCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDropdownItem({
    required IconData icon, 
    required String title, 
    required String value, 
    required List<String> options, 
    required Function(String?) onChanged
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Icon(icon, color: Colors.white70, size: 22),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: Colors.white)),
      trailing: DropdownButton<String>(
        value: value,
        dropdownColor: const Color(0xFF141414), // Keeps dropdown dark regardless of system theme
        underline: const SizedBox(),
        icon: const Icon(CupertinoIcons.chevron_down, size: 16, color: Colors.white54),
        style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 13, fontWeight: FontWeight.w500),
        items: options.map((String option) {
          return DropdownMenuItem(value: option, child: Text(option));
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildToggleItem({
    required IconData icon, 
    required String title, 
    required String subtitle, 
    required bool value, 
    required Function(bool) onChanged
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Icon(icon, color: Colors.white70, size: 22),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: Colors.white)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 11)),
      trailing: CupertinoSwitch(
        activeColor: Theme.of(context).colorScheme.primary,
        trackColor: Colors.white12,
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1, 
      indent: 60, 
      endIndent: 20, 
      color: Colors.white.withOpacity(0.05)
    );
  }
}
