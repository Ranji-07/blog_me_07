import 'package:flutter/material.dart';
import 'package:portfolio/core/app_theme.dart';
import 'package:portfolio/core/responsive.dart';
import 'package:portfolio/models/about_profile.dart';
import 'package:portfolio/screens/widgets/about_intro_card.dart';
import 'package:portfolio/screens/widgets/skill_category_grid.dart';
import 'package:portfolio/services/portfolio_api.dart';

class AboutScreen extends StatefulWidget {
  final Map<String, dynamic>? cachedContent;

  const AboutScreen({
    super.key,
    this.cachedContent,
  });

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  late final Future<AboutProfile> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _loadProfile();
  }

  Future<AboutProfile> _loadProfile() async {
    final cachedAbout = widget.cachedContent?['about'];
    if (cachedAbout is Map<String, dynamic>) {
      return AboutProfile.fromJson(cachedAbout);
    }
    return AboutProfile.fromJson(await PortfolioApi.fetchAbout());
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    final isMobile = Responsive.isMobile(context);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [t.background, t.surface, t.background],
        ),
      ),
      child: SafeArea(
        child: FutureBuilder<AboutProfile>(
          future: _profileFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return Center(child: CircularProgressIndicator(color: t.button));
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return Center(
                child: Text(
                  'Unable to load profile details right now.',
                  style: t.body.copyWith(color: t.text),
                ),
              );
            }

            final profile = snapshot.data!;
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 420),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) => Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 18 * (1 - value)),
                  child: child,
                ),
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  isMobile ? AppSpacing.md : AppSpacing.xl,
                  112,
                  isMobile ? AppSpacing.md : AppSpacing.xl,
                  AppSpacing.xxl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('A Little About Me', style: t.heading),
                    const SizedBox(height: AppSpacing.md),
                    AboutIntroCard(paragraphs: profile.aboutMe),
                    const SizedBox(height: AppSpacing.xl),
                    SkillCategoryGrid(categories: profile.skillCategories),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
