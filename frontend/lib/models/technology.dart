class Technology {
  final String name;
  final String canonicalName;
  final String? logoAsset;

  const Technology({
    required this.name,
    required this.canonicalName,
    required this.logoAsset,
  });
}

/// Visual metadata for the technology names supplied by portfolio.json.
/// The category map remains the source of truth for which technologies appear.
class TechnologyCatalog {
  TechnologyCatalog._();

  static const _assetPrefix = 'assets/images/technologies/';

  static const Map<String, String> _logos = {
    'C++': '${_assetPrefix}cpp.svg',
    'Python': '${_assetPrefix}python.svg',
    'Scala': '${_assetPrefix}scala.svg',
    'Dart': '${_assetPrefix}dart.svg',
    'Shell / Bash': '${_assetPrefix}bash.svg',
    'AWS': '${_assetPrefix}aws.svg',
    'Docker': '${_assetPrefix}docker.svg',
    'Kubernetes': '${_assetPrefix}kubernetes.svg',
    'Terraform': '${_assetPrefix}terraform.svg',
    'Jenkins': '${_assetPrefix}jenkins.svg',
    'GitHub': '${_assetPrefix}github.svg',
    'GitLab': '${_assetPrefix}gitlab.svg',
    'Prometheus': '${_assetPrefix}prometheus.svg',
    'Grafana': '${_assetPrefix}grafana.svg',
    'Django': '${_assetPrefix}django.svg',
    'Flutter': '${_assetPrefix}flutter.svg',
    'JavaScript': '${_assetPrefix}javascript.svg',
    'HTML': '${_assetPrefix}html5.svg',
    'CSS': '${_assetPrefix}css3.svg',
    'Streamlit': '${_assetPrefix}streamlit.svg',
    'Git': '${_assetPrefix}git.svg',
    'Windows': '${_assetPrefix}windows.svg',
    'Linux (Ubuntu)': '${_assetPrefix}linux.svg',
    'Azure': '${_assetPrefix}azure.svg',
    'Ansible': '${_assetPrefix}ansible.svg',
    'Helm': '${_assetPrefix}helm.svg',
    'PostgreSQL': '${_assetPrefix}postgresql.svg',
    'Firebase': '${_assetPrefix}firebase.svg',
    'React.js': '${_assetPrefix}react.svg',
    'Node.js': '${_assetPrefix}nodejs.svg',
    'MongoDB': '${_assetPrefix}mongodb.svg',
  };

  static Technology fromSkill(String skill) {
    final canonicalName =
        skill.replaceFirst(RegExp(r' - (Learning|Familiar)$'), '').trim();
    return Technology(
      name: skill,
      canonicalName: canonicalName,
      logoAsset: _logos[canonicalName],
    );
  }
}
