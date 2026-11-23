class Project {
  final int id;
  final String title;
  final String category;
  final String shortDescription;
  final String description;
  final List<String> technologies;
  final String githubUrl;
  final String demoUrl;
  final String stackLine;
  final String summary;
  final List<String> bullets;
  final List<String> stack;
  final String? screenshot;
  final String iconKey;

  const Project({
    required this.id,
    required this.title,
    required this.category,
    this.shortDescription = '',
    this.description = '',
    this.technologies = const [],
    this.githubUrl = '',
    this.demoUrl = '',
    this.stackLine = '',
    this.summary = '',
    this.bullets = const [],
    this.stack = const [],
    this.screenshot,
    this.iconKey = 'nodes',
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    List<String> strings(dynamic value) =>
        (value is List ? value : const []).whereType<String>().toList();
    final technologies = strings(json['stack'] ?? json['technologies']);
    final summary =
        json['summary'] as String? ?? json['description'] as String? ?? '';
    final screenshots = strings(json['images']);
    final screenshot = json['screenshot'] as String? ??
        (screenshots.isEmpty ? null : screenshots.first);
    return Project(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      category: json['category'] as String? ?? '',
      shortDescription: json['short_description'] as String? ?? '',
      description: json['description'] as String? ?? summary,
      technologies: technologies,
      githubUrl: json['github'] as String? ?? '',
      demoUrl: json['live_demo'] as String? ?? '',
      stackLine: json['stackLine'] as String? ??
          json['stack_line'] as String? ??
          technologies.take(2).join(' · '),
      summary: summary,
      bullets: strings(json['bullets'] ?? json['features']).take(3).toList(),
      stack: technologies,
      screenshot: screenshot == null || screenshot.trim().isEmpty
          ? null
          : screenshot.trim(),
      iconKey:
          json['iconKey'] as String? ?? json['icon_key'] as String? ?? 'nodes',
    );
  }
}
