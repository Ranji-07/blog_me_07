import 'package:portfolio/models/contact_info.dart';

class PortfolioContent {
  final Map<String, dynamic> raw;

  const PortfolioContent(this.raw);

  Map<String, dynamic> get about =>
      (raw['about'] as Map<String, dynamic>?) ?? const {};

  ContactInfo get contact => ContactInfo.fromJson(
        (raw['contact'] as Map<String, dynamic>?) ?? const {},
      );
}
