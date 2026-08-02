// Project data model for dynamic project showcase

class ProjectModel {
  final String id;
  final String title;
  final String shortDescription;
  final String fullDescription;
  final String icon;
  final String? imageUrl;
  final List<String> technologies;
  final List<WorkflowStep> workflow;
  final List<String> features;
  final List<String> screenshots;
  final ProjectLinks links;
  final String? architectureDescription;
  final String? category;

  const ProjectModel({
    required this.id,
    required this.title,
    required this.shortDescription,
    required this.fullDescription,
    required this.icon,
    this.imageUrl,
    required this.technologies,
    this.workflow = const [],
    this.features = const [],
    this.screenshots = const [],
    required this.links,
    this.architectureDescription,
    this.category,
  });

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: json['title'] ?? 'Untitled Project',
      shortDescription: json['short_description'] ?? json['description'] ?? '',
      fullDescription: json['full_description'] ?? json['description'] ?? '',
      icon: json['icon'] ?? 'code',
      imageUrl: json['image_url'] ?? json['image'],
      technologies: List<String>.from(json['technologies'] ?? []),
      workflow: (json['workflow'] as List?)
              ?.map((w) => WorkflowStep.fromJson(w))
              .toList() ??
          [],
      features: List<String>.from(json['features'] ?? []),
      screenshots: List<String>.from(json['screenshots'] ?? []),
      links: ProjectLinks.fromJson(json['links'] ?? {}),
      architectureDescription: json['architecture_description'],
      category: json['category'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'short_description': shortDescription,
        'full_description': fullDescription,
        'icon': icon,
        'image_url': imageUrl,
        'technologies': technologies,
        'workflow': workflow.map((w) => w.toJson()).toList(),
        'features': features,
        'screenshots': screenshots,
        'links': links.toJson(),
        'architecture_description': architectureDescription,
        'category': category,
      };
}

class WorkflowStep {
  final int step;
  final String title;
  final String description;
  final String? icon;

  const WorkflowStep({
    required this.step,
    required this.title,
    required this.description,
    this.icon,
  });

  factory WorkflowStep.fromJson(Map<String, dynamic> json) {
    return WorkflowStep(
      step: json['step'] ?? 1,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      icon: json['icon'],
    );
  }

  Map<String, dynamic> toJson() => {
        'step': step,
        'title': title,
        'description': description,
        'icon': icon,
      };
}

class ProjectLinks {
  final String? github;
  final String? liveDemo;
  final String? documentation;
  final String? video;

  const ProjectLinks({
    this.github,
    this.liveDemo,
    this.documentation,
    this.video,
  });

  factory ProjectLinks.fromJson(Map<String, dynamic> json) {
    return ProjectLinks(
      github: json['github'],
      liveDemo: json['live_demo'] ?? json['demo'],
      documentation: json['documentation'] ?? json['docs'],
      video: json['video'],
    );
  }

  Map<String, dynamic> toJson() => {
        'github': github,
        'live_demo': liveDemo,
        'documentation': documentation,
        'video': video,
      };

  bool get hasAnyLink =>
      github != null ||
      liveDemo != null ||
      documentation != null ||
      video != null;
}

// Sample projects for fallback/demo
class SampleProjects {
  static List<ProjectModel> get projects => [
        ProjectModel(
          id: '1',
          title: 'Smart Agriculture IoT System',
          shortDescription: 'Real-time crop monitoring with ESP32 sensors',
          fullDescription:
              'A comprehensive IoT solution for smart agriculture that monitors soil moisture, temperature, humidity, and light levels in real-time. The system uses ESP32 microcontrollers with various sensors to collect environmental data, which is then transmitted via LoRaWAN to a cloud backend for analysis and visualization.',
          icon: 'agriculture',
          technologies: ['ESP32', 'LoRaWAN', 'MQTT', 'Python', 'Flutter', 'PostgreSQL'],
          workflow: [
            WorkflowStep(step: 1, title: 'Data Collection', description: 'ESP32 sensors collect environmental data every 5 minutes', icon: 'sensors'),
            WorkflowStep(step: 2, title: 'Transmission', description: 'Data sent via LoRaWAN to gateway nodes', icon: 'cell_tower'),
            WorkflowStep(step: 3, title: 'Processing', description: 'Cloud backend processes and stores data in PostgreSQL', icon: 'cloud'),
            WorkflowStep(step: 4, title: 'Visualization', description: 'Flutter app displays real-time dashboards and alerts', icon: 'dashboard'),
          ],
          features: [
            'Real-time sensor monitoring',
            'Automated irrigation triggers',
            'Weather prediction integration',
            'Mobile push notifications',
            'Historical data analytics',
          ],
          links: ProjectLinks(github: 'https://github.com/example/smart-agri'),
          category: 'IoT',
        ),
        ProjectModel(
          id: '2',
          title: 'AI-Powered Portfolio Generator',
          shortDescription: 'Generate stunning portfolios with AI assistance',
          fullDescription:
              'An intelligent portfolio generation system that uses machine learning to analyze user data and automatically create beautiful, responsive portfolio websites. Features include content suggestions, layout optimization, and automated SEO improvements.',
          icon: 'auto_awesome',
          technologies: ['Flutter', 'FastAPI', 'TensorFlow', 'Docker', 'Firebase'],
          workflow: [
            WorkflowStep(step: 1, title: 'Input', description: 'User provides basic information and preferences', icon: 'input'),
            WorkflowStep(step: 2, title: 'Analysis', description: 'AI analyzes content and suggests improvements', icon: 'psychology'),
            WorkflowStep(step: 3, title: 'Generation', description: 'System generates responsive portfolio design', icon: 'design_services'),
            WorkflowStep(step: 4, title: 'Deployment', description: 'One-click deployment to hosting platform', icon: 'rocket_launch'),
          ],
          features: [
            'AI content suggestions',
            'Responsive design templates',
            'SEO optimization',
            'Custom domain support',
            'Analytics dashboard',
          ],
          links: ProjectLinks(
            github: 'https://github.com/example/ai-portfolio',
            liveDemo: 'https://ai-portfolio.demo.com',
          ),
          category: 'AI/ML',
        ),
        ProjectModel(
          id: '3',
          title: 'Secure Waste Management System',
          shortDescription: 'Smart waste collection with route optimization',
          fullDescription:
              'An end-to-end waste management solution featuring smart bins with fill-level sensors, route optimization for collection trucks, and a citizen reporting app. The system reduces operational costs by 30% through intelligent scheduling.',
          icon: 'delete',
          technologies: ['React', 'Node.js', 'MongoDB', 'Google Maps API', 'Arduino'],
          workflow: [
            WorkflowStep(step: 1, title: 'Monitoring', description: 'Smart bins report fill levels via GSM', icon: 'monitor'),
            WorkflowStep(step: 2, title: 'Optimization', description: 'AI calculates optimal collection routes', icon: 'route'),
            WorkflowStep(step: 3, title: 'Dispatch', description: 'Routes sent to driver mobile apps', icon: 'local_shipping'),
            WorkflowStep(step: 4, title: 'Analytics', description: 'Dashboard shows collection metrics and trends', icon: 'analytics'),
          ],
          features: [
            'Real-time bin monitoring',
            'Dynamic route optimization',
            'Citizen complaint portal',
            'Driver mobile app',
            'Management dashboard',
          ],
          links: ProjectLinks(github: 'https://github.com/example/waste-mgmt'),
          category: 'Smart City',
        ),
        ProjectModel(
          id: '4',
          title: 'Real-time Collaboration Platform',
          shortDescription: 'Team collaboration with live editing and video calls',
          fullDescription:
              'A comprehensive collaboration platform featuring real-time document editing, video conferencing, task management, and team chat. Built with WebRTC for low-latency communication and CRDT for conflict-free concurrent editing.',
          icon: 'groups',
          technologies: ['Flutter Web', 'WebRTC', 'Socket.io', 'Redis', 'PostgreSQL', 'Docker'],
          workflow: [
            WorkflowStep(step: 1, title: 'Connect', description: 'Users join workspace via secure invitation', icon: 'link'),
            WorkflowStep(step: 2, title: 'Collaborate', description: 'Real-time editing with presence awareness', icon: 'edit'),
            WorkflowStep(step: 3, title: 'Communicate', description: 'Video calls and chat for instant feedback', icon: 'video_call'),
            WorkflowStep(step: 4, title: 'Track', description: 'Task boards and progress tracking', icon: 'task_alt'),
          ],
          features: [
            'Real-time document editing',
            'HD video conferencing',
            'Kanban task boards',
            'File sharing and versioning',
            'Integration APIs',
          ],
          links: ProjectLinks(
            github: 'https://github.com/example/collab-platform',
            liveDemo: 'https://collab.demo.com',
          ),
          category: 'Productivity',
        ),
      ];
}
