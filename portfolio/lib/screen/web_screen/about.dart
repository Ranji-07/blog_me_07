import 'package:flutter/material.dart';
import 'package:portfolio/services/api_service.dart';
import 'package:portfolio/widgets/glass_container.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  Map<String, dynamic>? aboutData;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    loadAboutData();
  }

  Future<void> loadAboutData() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final data = await ApiService.getAbout();
      setState(() {
        aboutData = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  bool get isMobile => MediaQuery.of(context).size.width < 768;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF00C6FF)),
      );
    }

    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 60, color: Colors.red),
              const SizedBox(height: 20),
              const Text(
                'Error Loading Data',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                error!,
                style: const TextStyle(fontSize: 14, color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: loadAboutData,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C6FF),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "About Me",
            style: TextStyle(
              fontSize: isMobile ? 28 : 36,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF00C6FF),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            aboutData?['bio'] ?? 'No bio available',
            style: TextStyle(
              fontSize: isMobile ? 14 : 18,
              color: Colors.white70,
              height: 1.6,
            ),
            textAlign: TextAlign.justify,
          ),
          const SizedBox(height: 24),
          isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SkillsSection(skills: aboutData?['skills'] ?? [], isMobile: true),
        const SizedBox(height: 24),
        const Text(
          "Education",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF00C6FF),
          ),
        ),
        const SizedBox(height: 12),
        EducationTimeline(education: aboutData?['education'] ?? [], isMobile: true),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkillsSection(skills: aboutData?['skills'] ?? [], isMobile: false),
              const SizedBox(height: 24),
              const Text(
                "Education",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00C6FF),
                ),
              ),
              const SizedBox(height: 12),
              EducationTimeline(education: aboutData?['education'] ?? [], isMobile: false),
            ],
          ),
        ),
        const SizedBox(width: 40),
        Expanded(
          flex: 1,
          child: GlassContainer(
            padding: EdgeInsets.zero,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                "assets/about.png",
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 400,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.person, size: 100, color: Colors.blueGrey),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class SkillsSection extends StatelessWidget {
  final List<dynamic> skills;
  final bool isMobile;

  const SkillsSection({super.key, required this.skills, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    if (skills.isEmpty) {
      return const Text(
        'No skills data available',
        style: TextStyle(color: Colors.white70),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Skills",
          style: TextStyle(
            fontSize: isMobile ? 24 : 28,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF00C6FF),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: isMobile ? 12 : 20,
          runSpacing: isMobile ? 12 : 20,
          children: skills.map((skill) {
            return Container(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 12 : 16,
                vertical: isMobile ? 8 : 12,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF00C6FF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF00C6FF).withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/${skill['icon']}',
                    width: isMobile ? 28 : 40,
                    height: isMobile ? 28 : 40,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.code,
                        size: isMobile ? 28 : 40,
                        color: const Color(0xFF00C6FF),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  Text(
                    skill['name'],
                    style: TextStyle(
                      fontSize: isMobile ? 12 : 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class EducationTimeline extends StatelessWidget {
  final List<dynamic> education;
  final bool isMobile;

  const EducationTimeline({super.key, required this.education, required this.isMobile});

  Color _getColor(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'blue':
        return Colors.blue;
      case 'purple':
        return Colors.purple;
      case 'green':
        return Colors.green;
      case 'red':
        return Colors.red;
      case 'orange':
        return const Color(0xFF00C6FF);
      default:
        return const Color(0xFF00C6FF);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (education.isEmpty) {
      return const Text(
        'No education data available',
        style: TextStyle(color: Colors.white70),
      );
    }

    return Column(
      children: education.map((edu) {
        final color = _getColor(edu['color'] ?? 'orange');
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: EdgeInsets.all(isMobile ? 12 : 16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                width: isMobile ? 50 : 60,
                height: isMobile ? 50 : 60,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    edu['year'] ?? '',
                    style: TextStyle(
                      fontSize: isMobile ? 12 : 14,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      edu['title'] ?? '',
                      style: TextStyle(
                        fontSize: isMobile ? 16 : 18,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      edu['subtitle'] ?? '',
                      style: TextStyle(
                        fontSize: isMobile ? 12 : 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
