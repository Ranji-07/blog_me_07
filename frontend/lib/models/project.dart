class Project {
  final int id;
  final String title;
  final String category;
  final String description;
  final List<String> technologies;
  final String githubUrl;
  final String demoUrl;

  const Project({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.technologies,
    required this.githubUrl,
    required this.demoUrl,
  });

  factory Project.fromJson(Map<String, dynamic> json) => Project(
        id: json['id'] as int? ?? 0,
        title: json['title'] as String? ?? '',
        category: json['category'] as String? ?? '',
        description: json['description'] as String? ?? '',
        technologies: (json['technologies'] as List<dynamic>? ?? const [])
            .whereType<String>()
            .toList(),
        githubUrl: json['github'] as String? ?? '',
        demoUrl: json['live_demo'] as String? ?? '',
      );
}
