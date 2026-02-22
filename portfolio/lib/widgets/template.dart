import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:ui';

import 'package:portfolio/screen/web_screen/about.dart';
import 'package:portfolio/screen/web_screen/contact.dart';
import 'package:portfolio/screen/web_screen/experiance_page.dart';
import 'package:portfolio/screen/web_screen/project.dart';

class ProfileTemplate extends StatefulWidget {
  const ProfileTemplate({super.key});

  @override
  State<ProfileTemplate> createState() => _ProfileTemplateState();
}

class _ProfileTemplateState extends State<ProfileTemplate> {
  int _selectedIndex = 0;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  bool get isMobile => MediaQuery.of(context).size.width < 768;
  bool get isTablet => MediaQuery.of(context).size.width >= 768 && MediaQuery.of(context).size.width < 1024;

  double get sectionHeight {
    if (isMobile) return MediaQuery.of(context).size.height * 1.2;
    return MediaQuery.of(context).size.height - 80;
  }

  void _onScroll() {
    final scrollPosition = _scrollController.offset;
    final height = sectionHeight;
    
    int newIndex = 0;
    if (scrollPosition >= height * 3 - 200) {
      newIndex = 3;
    } else if (scrollPosition >= height * 2 - 200) {
      newIndex = 2;
    } else if (scrollPosition >= height - 200) {
      newIndex = 1;
    }
    
    if (newIndex != _selectedIndex) {
      setState(() {
        _selectedIndex = newIndex;
      });
    }
  }

  void _scrollToSection(int index) {
    final targetOffset = index * sectionHeight;
    
    _scrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
    );
    
    setState(() {
      _selectedIndex = index;
    });

    if (isMobile) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _downloadResume() async {
    try {
      const url = 'assets/resume.pdf';
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Resume not available')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: isMobile ? _buildDrawer() : null,
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E1E2C), Color(0xFF020617)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  children: [
                    _buildSection(const AboutPage(), 0),
                    _buildSection(const ProjectPage(), 1),
                    _buildSection(const ExperiancePage(), 2),
                    _buildSection(const ContactPage(), 3),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(Widget child, int index) {
    return Container(
      constraints: BoxConstraints(minHeight: sectionHeight),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 48,
        vertical: 24,
      ),
      child: child,
    );
  }

  Widget _buildHeader() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : 24,
            vertical: isMobile ? 12 : 20,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: isMobile ? _buildMobileHeader() : _buildDesktopHeader(),
        ),
      ),
    );
  }

  Widget _buildMobileHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "Portfolio",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF00C6FF),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
      ],
    );
  }

  Widget _buildDesktopHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "Charles Kasasira",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF00C6FF),
            letterSpacing: 1.2,
          ),
        ),
        Row(
          children: [
            _navItem("About", 0),
            SizedBox(width: isTablet ? 12 : 24),
            _navItem("Projects", 1),
            SizedBox(width: isTablet ? 12 : 24),
            _navItem("Experience", 2),
            SizedBox(width: isTablet ? 12 : 24),
            _navItem("Contact", 3),
            SizedBox(width: isTablet ? 24 : 48),
            _resumeButton(),
          ],
        ),
      ],
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: Colors.black87,
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            const Text(
              "Portfolio",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFFE76F51),
              ),
            ),
            const SizedBox(height: 40),
            _drawerItem("About", 0),
            _drawerItem("Projects", 1),
            _drawerItem("Experience", 2),
            _drawerItem("Contact", 3),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(20),
              child: _resumeButton(),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(String text, int index) {
    final isSelected = _selectedIndex == index;
    return ListTile(
      title: Text(
        text,
        style: TextStyle(
          fontSize: 18,
          color: isSelected ? const Color(0xFF00C6FF) : Colors.white,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        ),
      ),
      selected: isSelected,
      selectedTileColor: const Color(0xFF00C6FF).withOpacity(0.1),
      onTap: () => _scrollToSection(index),
    );
  }

  Widget _navItem(String text, int index) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _scrollToSection(index),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 12 : 16,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            border: isSelected 
                ? const Border(bottom: BorderSide(color: Color(0xFF00C6FF), width: 3))
                : null,
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: isTablet ? 16 : 18,
              color: isSelected ? const Color(0xFF00C6FF) : Colors.white70,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _resumeButton() {
    return GestureDetector(
      onTap: _downloadResume,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF00C6FF), Color(0xFF0072FF)],
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00C6FF).withOpacity(0.4),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Text(
            "Resume",
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
