class JourneyContent {
  final String title;
  final String subtitle;
  final List<JourneyEvent> events;

  const JourneyContent(
      {required this.title, required this.subtitle, required this.events});

  factory JourneyContent.fromPortfolio(Map<String, dynamic> content) {
    final journey = content['journey'] as Map<String, dynamic>? ?? const {};
    return JourneyContent.fromJson(journey);
  }

  factory JourneyContent.fromJson(Map<String, dynamic> journey) {
    final events = (journey['events'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(JourneyEvent.fromJson)
        .toList()
      ..sort((a, b) => a.sortKey.compareTo(b.sortKey));
    return JourneyContent(
      title: journey['title'] as String? ?? 'The Journey So Far',
      subtitle: journey['subtitle'] as String? ?? '',
      events: events,
    );
  }
}

class JourneyEvent {
  final String kind;
  final String year;
  final String title;
  final String label;
  final String organization;
  final String date;
  final String sortDate;
  final String description;
  final List<String> technologies;
  final List<String> highlights;
  final String link;
  final bool isCurrent;

  const JourneyEvent({
    required this.kind,
    required this.year,
    required this.title,
    required this.label,
    required this.organization,
    required this.date,
    required this.sortDate,
    required this.description,
    this.technologies = const [],
    this.highlights = const [],
    this.link = '',
    this.isCurrent = false,
  });

  factory JourneyEvent.fromJson(Map<String, dynamic> json) => JourneyEvent(
        kind: json['type'] as String? ?? 'Work',
        year: _yearFrom(json['date']),
        title: json['title'] as String? ?? '',
        label: json['timeline_label'] as String? ??
            (json['title'] as String? ?? ''),
        organization: json['organization'] as String? ?? '',
        date: json['date'] as String? ?? '',
        sortDate: json['timeline_date'] as String? ?? '',
        description: json['description'] as String? ?? '',
        technologies: _strings(json['technologies']),
        highlights: _strings(json['highlights']),
        link: json['link'] as String? ?? '',
        isCurrent: json['current'] as bool? ?? false,
      );

  String get shortDate =>
      RegExp(r'^[A-Za-z]{3}\s+\d{4}|^\d{4}').firstMatch(date)?.group(0) ?? date;

  int get sortKey {
    final match = RegExp(r'^\d{4}-(\d{2})-(\d{2})').firstMatch(sortDate);
    if (match != null) {
      return int.tryParse(match.group(0)!.replaceAll('-', '')) ?? 0;
    }
    return (int.tryParse(_yearFrom(date)) ?? 0) * 10000;
  }

  static List<String> _strings(Object? value) =>
      (value as List<dynamic>? ?? const []).whereType<String>().toList();
  static String _yearFrom(Object? value) =>
      RegExp(r'\d{4}').firstMatch(value?.toString() ?? '')?.group(0) ?? '';
}
