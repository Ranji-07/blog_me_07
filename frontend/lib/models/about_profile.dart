class AboutProfile {
  final List<String> aboutMe;
  final Map<String, List<String>> skillCategories;
  final List<EducationTimelineEntry> timeline;

  const AboutProfile({
    required this.aboutMe,
    required this.skillCategories,
    required this.timeline,
  });

  factory AboutProfile.fromJson(Map<String, dynamic> json) {
    final rawCategories = (json['skill_categories'] as Map<String, dynamic>?) ??
        (json['skills'] as Map<String, dynamic>?) ??
        const {};
    return AboutProfile(
      aboutMe: (json['about_me'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(),
      skillCategories: rawCategories.map(
        (key, value) => MapEntry(
          key,
          (value as List<dynamic>? ?? const []).whereType<String>().toList(),
        ),
      ),
      timeline: (json['education_timeline'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(EducationTimelineEntry.fromJson)
          .toList(),
    );
  }
}

class EducationTimelineEntry {
  final String year;
  final String type;
  final String title;
  final String organization;
  final String date;
  final String description;
  final String credentialId;
  final String credentialUrl;
  final String assetUrl;

  String get certificateUrl =>
      credentialUrl.isNotEmpty ? credentialUrl : assetUrl;

  const EducationTimelineEntry({
    required this.year,
    required this.type,
    required this.title,
    required this.organization,
    required this.date,
    required this.description,
    required this.credentialId,
    required this.credentialUrl,
    required this.assetUrl,
  });

  factory EducationTimelineEntry.fromJson(Map<String, dynamic> json) =>
      EducationTimelineEntry(
        year: (json['year'] as String?) ?? '',
        type: (json['type'] as String?) ?? '',
        title: (json['title'] as String?) ?? '',
        organization: (json['organization'] as String?) ?? '',
        date: (json['date'] as String?) ?? '',
        description: (json['description'] as String?) ?? '',
        credentialId: (json['credential_id'] as String?) ?? '',
        credentialUrl: (json['credential_url'] as String?) ?? '',
        assetUrl: (json['asset_url'] as String?) ?? '',
      );
}
