class AboutProfile {
  final List<String> aboutMe;
  final Map<String, List<String>> skillCategories;

  const AboutProfile({
    required this.aboutMe,
    required this.skillCategories,
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
    );
  }
}
