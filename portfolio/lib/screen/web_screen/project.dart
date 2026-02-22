import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:portfolio/services/api_service.dart';
import 'package:portfolio/widgets/glass_container.dart';

class ProjectPage extends StatefulWidget {
  const ProjectPage({super.key});

  @override
  State<ProjectPage> createState() => _ProjectPageState();
}

class _ProjectPageState extends State<ProjectPage> {
  Map<String, dynamic>? projectData;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    loadProjectData();
  }

  Future<void> loadProjectData() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final data = await ApiService.getProjects();
      setState(() {
        projectData = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  IconData _getIcon(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'camera':
        return Icons.camera;
      case 'agriculture':
        return Icons.agriculture;
      case 'delete':
        return Icons.delete;
      case 'code':
        return Icons.code;
      case 'computer':
        return Icons.computer;
      case 'phone':
        return Icons.phone_android;
      default:
        return Icons.work;
    }
  }

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
                'Error Loading Projects',
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
                onPressed: loadProjectData,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF00C6FF),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    List<dynamic> projects = projectData?['projects'] ?? [];

    if (projects.isEmpty) {
      return const Center(
        child: Text(
          'No projects available',
          style: TextStyle(fontSize: 18, color: Colors.white),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 15),
        const Text(
          "My Work",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF00C6FF),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(8),
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height * .79,
          child: CarouselSlider(
            items: projects.map((project) {
              return buildProject(
                context,
                project['title'] ?? 'Untitled Project',
                project['description'] ?? 'No description',
                _getIcon(project['icon'] ?? 'code'),
                List<String>.from(project['technologies'] ?? []),
              );
            }).toList(),
            options: CarouselOptions(
              autoPlay: true,
              enlargeCenterPage: true,
              aspectRatio: 16 / 9,
              viewportFraction: 1,
              autoPlayInterval: const Duration(seconds: 5),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildProject(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    List<String> technologies,
  ) {
    bool isMobile = MediaQuery.of(context).size.width < 800;

    return GlassContainer(
      padding: EdgeInsets.all(isMobile ? 20 : 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00C6FF).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, size: 40, color: const Color(0xFF00C6FF)),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                        height: 1.5,
                      ),
                    ),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00C6FF).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, size: 80, color: const Color(0xFF00C6FF)),
                    ),
                    const SizedBox(width: 30),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.1,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            description,
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.white70,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
          SizedBox(height: isMobile ? 20 : 30),
          if (technologies.isNotEmpty)
            Wrap(
              spacing: isMobile ? 8 : 12,
              runSpacing: isMobile ? 8 : 12,
              children: technologies.map((tech) {
                return Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 12 : 16, 
                    vertical: isMobile ? 6 : 8
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C6FF).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF00C6FF).withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    tech,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: isMobile ? 12 : 14,
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}