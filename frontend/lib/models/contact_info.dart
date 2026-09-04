class ContactInfo {
  final String email;
  final String githubUrl;
  final String linkedinUrl;

  const ContactInfo({
    required this.email,
    required this.githubUrl,
    required this.linkedinUrl,
  });

  factory ContactInfo.fromJson(Map<String, dynamic> json) {
    final social = (json['social'] as Map<String, dynamic>?) ?? const {};
    return ContactInfo(
      email: (json['email'] as String?) ?? '',
      githubUrl: (social['github'] as String?) ?? '',
      linkedinUrl: (social['linkedin'] as String?) ?? '',
    );
  }
}
