import 'package:flutter/material.dart';
import 'package:portfolio/services/api_service.dart';
import 'package:portfolio/widgets/glass_container.dart';

class ExperiancePage extends StatefulWidget {
  const ExperiancePage({super.key});

  @override
  State<ExperiancePage> createState() => _ExperiancePageState();
}

class _ExperiancePageState extends State<ExperiancePage> {
  Map<String, dynamic>? experienceData;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    loadExperienceData();
  }

  Future<void> loadExperienceData() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final data = await ApiService.getExperience();
      setState(() {
        experienceData = data;
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
                'Error Loading Experience',
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
                onPressed: loadExperienceData,
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

    List<dynamic> experiences = experienceData?['experiences'] ?? [];

    if (experiences.isEmpty) {
      return const Center(
        child: Text(
          'No experience data available',
          style: TextStyle(fontSize: 18, color: Colors.white),
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          Wrap(
            spacing: 20,
            runSpacing: 20,
            children: experiences.map<Widget>((exp) {
              return ExperienceCard(
                companyName: exp['company'] ?? 'Company',
                companyLogo: exp['logo'] ?? 'default.png',
                experiences: (exp['positions'] as List?)
                        ?.map((pos) => Experience(
                              position: pos['position'] ?? 'Position',
                              startDate: pos['startDate'] ?? 'Start',
                              endDate: pos['endDate'] ?? 'End',
                            ))
                        .toList() ??
                    [],
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class ExperienceCard extends StatelessWidget {
  final String companyName;
  final String companyLogo;
  final List<Experience> experiences;

  const ExperienceCard({
    super.key,
    required this.companyName,
    required this.companyLogo,
    required this.experiences,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * .4,
      constraints: BoxConstraints(
        minHeight: MediaQuery.of(context).size.height * .5,
      ),
      child: GlassContainer(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      'assets/$companyLogo',
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.business, color: Colors.white70),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    companyName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ...experiences.map((exp) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF00C6FF),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exp.position,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF00C6FF),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "${exp.startDate} - ${exp.endDate}",
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}

class Experience {
  final String position;
  final String startDate;
  final String endDate;

  Experience({
    required this.position,
    required this.startDate,
    required this.endDate,
  });
}