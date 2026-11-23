import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:portfolio/core/app_theme.dart';
import 'package:portfolio/models/technology.dart';

const aboutCoreNames = [
  'Python',
  'AWS',
  'Kubernetes',
  'Docker',
  'Terraform',
  'Jenkins',
  'Git',
  'Flutter',
  'Dart',
  'Scala',
  'Ansible',
  'Helm',
  'Prometheus',
  'Grafana'
];

List<Technology> aboutTechnologies(Map<String, List<String>> categories) {
  final seen = <String>{};
  return categories.values
      .expand((v) => v)
      .map(TechnologyCatalog.fromSkill)
      .where((t) => seen.add(switch (t.canonicalName) {
            'Amazon EKS' => 'EKS',
            'DockerHub' => 'Docker',
            'GitHub Webhooks' => 'GitHub',
            final name => name,
          }))
      .toList();
}

Color aboutAccent(AppThemeData t) =>
    t.isDark ? t.button : const Color(0xFF984B13);

TextStyle aboutMono(AppThemeData t, {double size = 12, Color? color}) =>
    GoogleFonts.jetBrainsMono(
      fontSize: size,
      height: 1.6,
      color: color ?? t.textMuted,
    );

class TechnologyIcon extends StatelessWidget {
  final Technology technology;
  final double size;
  final bool selected;
  final bool removeServiceBackground;
  const TechnologyIcon(
      {super.key,
      required this.technology,
      this.size = 24,
      this.selected = false,
      this.removeServiceBackground = false});

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    final color = selected ? aboutAccent(t) : t.textMuted;
    // The selected icon keeps its original brand colours; unselected icons
    // rest in a muted gray so the honeycomb stays calm around the focus.
    // The luminance matrix preserves the light/dark details inside
    // multicolour SVGs, which srcIn would flatten into a single fill.
    final matrix = selected
        ? null
        : <double>[
            for (final _ in const [0, 1, 2]) ...[
              .2126 * .35,
              .7152 * .35,
              .0722 * .35,
              0,
              255 * .30,
            ],
            0,
            0,
            0,
            1,
            0,
          ];
    return ExcludeSemantics(
        child: SizedBox(
            width: size,
            height: size,
            child: technology.logoAsset == null
                ? Icon(Icons.code_rounded, size: size, color: color)
                : SvgPicture.asset(technology.logoAsset!,
                    fit: BoxFit.contain,
                    colorMapper: removeServiceBackground
                        ? const _ServiceMarkColors()
                        : null,
                    colorFilter:
                        matrix == null ? null : ColorFilter.matrix(matrix))));
  }
}

/// The AWS assets contain a background group separate from the service mark.
/// Hide only that group; retain the original paths and details of each logo.
class _ServiceMarkColors extends ColorMapper {
  const _ServiceMarkColors();

  @override
  Color substitute(
          String? id, String elementName, String attributeName, Color color) =>
      id != null && id.startsWith('Icon-Architecture-BG/')
          ? Colors.transparent
          : color;
}
