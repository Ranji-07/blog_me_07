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
                  backgroundColor: const Color(0xFF00C6FF),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final careers = experienceData?['careers'] as List<dynamic>? ?? [];
    final internships = experienceData?['internships'] as List<dynamic>? ?? [];
    final certifications = experienceData?['certifications'] as List<dynamic>? ?? [];
    final academic = experienceData?['academic'] as List<dynamic>? ?? [];

    if (careers.isEmpty && internships.isEmpty && certifications.isEmpty && academic.isEmpty) {
      return const Center(
        child: Text(
          'No experience timeline data available',
          style: TextStyle(fontSize: 18, color: Colors.white),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (careers.isNotEmpty) ...[
          _buildCategoryHeader("Professional Experience", Icons.work),
          _buildCompanyTimeline(careers),
          const SizedBox(height: 40),
        ],
        if (internships.isNotEmpty) ...[
          _buildCategoryHeader("Internships", Icons.handshake),
          _buildCompanyTimeline(internships),
          const SizedBox(height: 40),
        ],
        if (certifications.isNotEmpty) ...[
           _buildCategoryHeader("Certifications", Icons.workspace_premium),
          _buildAchievementTimeline(certifications),
          const SizedBox(height: 40),
        ],
        if (academic.isNotEmpty) ...[
           _buildCategoryHeader("Academic Highlights", Icons.school),
          _buildAchievementTimeline(academic),
          const SizedBox(height: 40),
        ],
      ],
    );
  }

  Widget _buildCategoryHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0, left: 8.0),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF00C6FF), size: 28),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyTimeline(List<dynamic> items) {
    return Column(
      children: List.generate(items.length, (index) {
        final companyData = items[index];
        final bool isLast = index == items.length - 1;
        
        return TimelineNode(
          isLast: isLast,
          child: CompanyExperienceCard(data: companyData),
        );
      }),
    );
  }

  Widget _buildAchievementTimeline(List<dynamic> items) {
    return Column(
      children: List.generate(items.length, (index) {
        final achievementData = items[index];
        final bool isLast = index == items.length - 1;
        
        return TimelineNode(
          isLast: isLast,
          child: AchievementCard(data: achievementData),
          nodeColor: const Color(0xFF9333EA), // Purple accent for secondaries
        );
      }),
    );
  }
}

class TimelineNode extends StatelessWidget {
  final Widget child;
  final bool isLast;
  final Color nodeColor;

  const TimelineNode({
    super.key,
    required this.child,
    this.isLast = false,
    this.nodeColor = const Color(0xFF00C6FF),
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline Stem
          Column(
            children: [
              Container(
                width: 20,
                height: 20,
                margin: const EdgeInsets.only(top: 32, left: 8, right: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  shape: BoxShape.circle,
                  border: Border.all(color: nodeColor, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: nodeColor.withOpacity(0.5),
                      blurRadius: 8,
                      spreadRadius: 2,
                    )
                  ],
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: nodeColor.withOpacity(0.3),
                    margin: const EdgeInsets.only(top: 8, bottom: 8),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          // Content Payload
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 32.0),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

class CompanyExperienceCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const CompanyExperienceCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final String companyName = data['company'] ?? 'Unknown Company';
    final String companyLogo = data['logo'] ?? 'default.png';
    final List<dynamic> positions = data['positions'] ?? [];
    bool isMobile = MediaQuery.of(context).size.width < 800;

    return GlassContainer(
      padding: EdgeInsets.all(isMobile ? 20.0 : 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Company Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'assets/$companyLogo',
                    width: isMobile ? 40 : 50,
                    height: isMobile ? 40 : 50,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: isMobile ? 40 : 50,
                        height: isMobile ? 40 : 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(8),
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
                  style: TextStyle(
                    fontSize: isMobile ? 20 : 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
            ],
          ),
          if (positions.isNotEmpty) const SizedBox(height: 24),
          // Progression Roles
          ...List.generate(positions.length, (index) {
            final pos = positions[index];
            final bool isLastPos = index == positions.length - 1;
            
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Inner progression stem
                  Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 6, left: 16, right: 16),
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF00C6FF),
                          shape: BoxShape.circle,
                        ),
                      ),
                      if (!isLastPos)
                        Expanded(
                          child: Container(
                            width: 1,
                            color: Colors.white24,
                            margin: const EdgeInsets.only(top: 4, bottom: 4),
                          ),
                        ),
                    ],
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: isLastPos ? 0 : 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pos['position'] ?? 'Role',
                            style: TextStyle(
                              fontSize: isMobile ? 16 : 18,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF00C6FF),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${pos['startDate'] ?? ''} - ${pos['endDate'] ?? ''}",
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white60,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (pos['description'] != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              pos['description'],
                              style: TextStyle(
                                fontSize: isMobile ? 14 : 15,
                                color: Colors.white.withOpacity(0.85),
                                height: 1.6,
                              ),
                            ),
                          ]
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class AchievementCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const AchievementCard({super.key, required this.data});

  IconData _getIconData(String? iconName) {
    switch (iconName) {
      case 'certificate': return Icons.card_membership;
      case 'workspace_premium': return Icons.workspace_premium;
      case 'emoji_events': return Icons.emoji_events;
      case 'military_tech': return Icons.military_tech;
      default: return Icons.star;
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 800;
    
    return GlassContainer(
      padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF9333EA).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF9333EA).withOpacity(0.3)),
            ),
            child: Icon(
              _getIconData(data['icon']),
              size: 32,
              color: const Color(0xFFD8B4FE), // Light purple
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['title'] ?? 'Achievement',
                  style: TextStyle(
                    fontSize: isMobile ? 18 : 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      data['issuer'] ?? data['institution'] ?? 'Organization',
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFFD8B4FE), // Light purple accent
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text("•", style: TextStyle(color: Colors.white54)),
                    ),
                    Text(
                      data['date'] ?? '',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
                if (data['description'] != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    data['description'],
                    style: TextStyle(
                      fontSize: isMobile ? 14 : 15,
                      color: Colors.white.withOpacity(0.85),
                      height: 1.5,
                    ),
                  ),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }
}