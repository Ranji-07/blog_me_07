import 'package:flutter/material.dart';
import 'package:portfolio/core/app_theme.dart';
import 'package:portfolio/core/responsive.dart';
import 'package:portfolio/models/journey_content.dart';
import 'package:portfolio/screens/widgets/journey_timeline.dart';
import 'package:portfolio/services/portfolio_api.dart';

class JourneyPage extends StatefulWidget {
  const JourneyPage({super.key});

  @override
  State<JourneyPage> createState() => _JourneyPageState();
}

class _JourneyPageState extends State<JourneyPage> {
  late Future<JourneyContent> _journeyFuture;

  @override
  void initState() {
    super.initState();
    _journeyFuture = _loadJourney();
  }

  Future<JourneyContent> _loadJourney() async =>
      JourneyContent.fromJson(await PortfolioApi.fetchJourney());

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    final mobile = Responsive.isMobile(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(mobile ? AppSpacing.md : AppSpacing.xl, 112,
          mobile ? AppSpacing.md : AppSpacing.xl, AppSpacing.xxl),
      child: FutureBuilder<JourneyContent>(
        future: _journeyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return Center(child: CircularProgressIndicator(color: t.button));
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Text('Unable to load the journey right now.', style: t.body);
          }
          final journey = snapshot.data!;
          if (journey.events.isEmpty) {
            return Text('Journey details will be available soon.',
                style: t.body);
          }
          return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(journey.title, style: t.display.copyWith(color: t.button)),
                if (journey.subtitle.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(journey.subtitle, style: t.body)
                ],
                const SizedBox(height: AppSpacing.xl),
                JourneyTimeline(entries: journey.events),
              ]);
        },
      ),
    );
  }
}
