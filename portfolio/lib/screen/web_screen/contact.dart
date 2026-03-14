import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:portfolio/core/app_theme.dart';
import 'package:portfolio/core/animations.dart';
import 'package:portfolio/core/responsive.dart';
import 'package:portfolio/widgets/details_screen.dart';
import 'package:portfolio/services/api_service.dart';
import 'package:portfolio/widgets/glass_container.dart';

class ContactPage extends StatefulWidget {
  const ContactPage({super.key});

  @override
  State<ContactPage> createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController contactController = TextEditingController();
  final TextEditingController messageController = TextEditingController();

  bool isSubmitting = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: AppAnimations.entranceFade,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: AppCurves.smoothDecelerate,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    nameController.dispose();
    emailController.dispose();
    contactController.dispose();
    messageController.dispose();
    super.dispose();
  }

  Future<void> submitForm() async {
    if (nameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        contactController.text.trim().isEmpty ||
        messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!emailController.text.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid email'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => isSubmitting = true);

    try {
      final success = await ApiService.submitContactForm(
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        contact: contactController.text.trim(),
        message: messageController.text.trim(),
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Message sent successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        nameController.clear();
        emailController.clear();
        contactController.clear();
        messageController.clear();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send message. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    final isMobile = Responsive.isMobile(context);
    final isTablet = Responsive.isTablet(context);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 20,
          vertical: isMobile ? 20 : 30,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            isMobile || isTablet
                ? _buildMobileLayout(context, t, isMobile)
                : _buildDesktopLayout(context, t),
            _buildFooter(context, t, isMobile),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context, AppThemeData t, bool isMobile) {
    return Column(
      children: [
        EntranceAnimation(
          delay: const Duration(milliseconds: 100),
          child: Image.asset(
            'assets/contact.png',
            width: MediaQuery.of(context).size.width * 0.8,
            height: isMobile ? 200 : 300,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: MediaQuery.of(context).size.width * 0.8,
                height: isMobile ? 200 : 300,
                decoration: BoxDecoration(
                  color: t.card,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(Icons.contact_mail, size: 80, color: t.textMuted),
              );
            },
          ),
        ),
        const SizedBox(height: 32),
        EntranceAnimation(
          delay: const Duration(milliseconds: 200),
          child: GlassContainer(
            width: MediaQuery.of(context).size.width * 0.9,
            padding: const EdgeInsets.all(24),
            child: DetailSection(
              nameController: nameController,
              emailController: emailController,
              contactController: contactController,
              messageController: messageController,
              text: isSubmitting ? "Sending..." : "Send Message",
              onPressed: isSubmitting ? null : submitForm,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context, AppThemeData t) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Flexible(
          child: EntranceAnimation(
            delay: const Duration(milliseconds: 100),
            slideOffset: const Offset(-0.05, 0),
            child: Image.asset(
              'assets/contact.png',
              width: 500,
              height: 600,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 500,
                  height: 600,
                  decoration: BoxDecoration(
                    color: t.card,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(Icons.contact_mail, size: 100, color: t.textMuted),
                );
              },
            ),
          ),
        ),
        Flexible(
          child: EntranceAnimation(
            delay: const Duration(milliseconds: 200),
            slideOffset: const Offset(0.05, 0),
            child: GlassContainer(
              padding: const EdgeInsets.all(40),
              child: DetailSection(
                nameController: nameController,
                emailController: emailController,
                contactController: contactController,
                messageController: messageController,
                text: isSubmitting ? "Sending..." : "Send Message",
                onPressed: isSubmitting ? null : submitForm,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context, AppThemeData t, bool isMobile) {
    final year = DateTime.now().year;

    if (isMobile) {
      return Column(
        children: [
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _SocialIconButton(icon: FontAwesomeIcons.squarePhone),
              const SizedBox(width: 12),
              _SocialIconButton(icon: FontAwesomeIcons.instagram),
              const SizedBox(width: 12),
              _SocialIconButton(icon: FontAwesomeIcons.github),
              const SizedBox(width: 12),
              _SocialIconButton(icon: FontAwesomeIcons.linkedin),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            "© $year MyPortfolio",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: t.text,
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          children: [
            _SocialIconButton(icon: FontAwesomeIcons.squarePhone),
            const SizedBox(width: 12),
            _SocialIconButton(icon: FontAwesomeIcons.instagram),
            const SizedBox(width: 12),
            _SocialIconButton(icon: FontAwesomeIcons.github),
            const SizedBox(width: 12),
            _SocialIconButton(icon: FontAwesomeIcons.linkedin),
          ],
        ),
        Row(
          children: [
            Text(
              "Last updated: ${_getMonth()} $year",
              style: TextStyle(fontSize: 12, color: t.textMuted),
            ),
            const SizedBox(width: 40),
            Text(
              "© $year MyPortfolio",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: t.text,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _getMonth() {
    const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    return months[DateTime.now().month - 1];
  }
}

class _SocialIconButton extends StatefulWidget {
  final IconData icon;

  const _SocialIconButton({required this.icon});

  @override
  State<_SocialIconButton> createState() => _SocialIconButtonState();
}

class _SocialIconButtonState extends State<_SocialIconButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () {},
        child: AnimatedContainer(
          duration: AppAnimations.fast,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _hovered
                ? t.primary.withValues(alpha: 0.15)
                : t.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: t.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                    ),
                  ]
                : [],
          ),
          child: FaIcon(
            widget.icon,
            size: 18,
            color: _hovered ? t.primary : t.primary.withValues(alpha: 0.8),
          ),
        ),
      ),
    );
  }
}
