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

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 768;

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "About Me",
          style: TextStyle(
            fontSize: isMobile ? 32 : 42,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF00C6FF),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 24),
        Container(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Text(
            aboutData?['bio'] ?? 'No bio available',
            style: TextStyle(
              fontSize: isMobile ? 15 : 18,
              color: Colors.white.withOpacity(0.85),
              height: 1.8,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.left,
          ),
        ),
        const SizedBox(height: 48),
        isMobile ? _buildMobileLayout(isMobile) : _buildDesktopLayout(isMobile),
      ],
    );
  }

  Widget _buildMobileLayout(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SkillsSection(skillsData: aboutData?['skills'] ?? [], isMobile: isMobile),
        const SizedBox(height: 40),
        const Text(
          "Education & Timeline",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF00C6FF),
          ),
        ),
        const SizedBox(height: 24),
        EducationTimeline(education: aboutData?['education'] ?? [], isMobile: isMobile),
      ],
    );
  }

  Widget _buildDesktopLayout(bool isMobile) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkillsSection(skillsData: aboutData?['skills'] ?? [], isMobile: false),
              const SizedBox(height: 40),
              const Text(
                "Education & Timeline",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00C6FF),
                ),
              ),
              const SizedBox(height: 24),
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
  final dynamic skillsData;
  final bool isMobile;

  const SkillsSection({super.key, required this.skillsData, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    if (skillsData == null) {
      return const Text(
        'No skills data available',
        style: TextStyle(color: Colors.white70),
      );
    }

    Map<String, dynamic> categories = {};
    if (skillsData is Map) {
      categories = Map<String, dynamic>.from(skillsData);
    } else if (skillsData is List) {
       categories = {'All Skills': skillsData};
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Core Competencies",
          style: TextStyle(
            fontSize: isMobile ? 24 : 28,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF00C6FF),
          ),
        ),
        const SizedBox(height: 24),
        ...categories.entries.map((entry) {
          final categoryName = entry.key;
          final categorySkills = List<dynamic>.from(entry.value);

          return Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: GlassContainer(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                    categoryName,
                    style: TextStyle(
                      fontSize: isMobile ? 18 : 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: isMobile ? 12 : 16,
                    runSpacing: isMobile ? 12 : 16,
                    children: categorySkills.map((skill) {
                      return Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 12 : 16,
                          vertical: isMobile ? 8 : 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              'assets/${skill['icon']}',
                              width: isMobile ? 20 : 24,
                              height: isMobile ? 20 : 24,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.code,
                                  size: isMobile ? 20 : 24,
                                  color: const Color(0xFF00C6FF),
                                );
                              },
                            ),
                            const SizedBox(width: 10),
                            Text(
                              skill['name'],
                              style: TextStyle(
                                fontSize: isMobile ? 13 : 15,
                                fontWeight: FontWeight.w500,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }
}

class EducationTimeline extends StatelessWidget {
  final List<dynamic> education;
  final bool isMobile;

  const EducationTimeline({super.key, required this.education, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    if (education.isEmpty) {
      return const Text(
        'No education data available',
        style: TextStyle(color: Colors.white70),
      );
    }

    return Column(
      children: List.generate(education.length, (index) {
        final edu = education[index];
        final bool isLast = index == education.length - 1;
        
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeline Node & Line
              Column(
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    margin: const EdgeInsets.only(top: 24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF00C6FF), width: 3),
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: const Color(0xFF00C6FF).withOpacity(0.3),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 20),
              
              // Education Card
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: GlassContainer(
                    padding: EdgeInsets.all(isMobile ? 16 : 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          edu['year'] ?? '',
                          style: TextStyle(
                            fontSize: isMobile ? 14 : 16,
                            color: const Color(0xFF00C6FF),
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          edu['title'] ?? '',
                          style: TextStyle(
                            fontSize: isMobile ? 18 : 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          edu['subtitle'] ?? '',
                          style: TextStyle(
                            fontSize: isMobile ? 14 : 16,
                            color: Colors.white70,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
