import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:portfolio/core/app_theme.dart';
import 'package:portfolio/core/animations.dart';
import 'package:portfolio/core/responsive.dart';
import 'package:portfolio/services/api_service.dart';

class ContactPage extends StatefulWidget {
  const ContactPage({super.key});

  @override
  State<ContactPage> createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _contactController = TextEditingController();
  final _messageController = TextEditingController();

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
    _nameController.dispose();
    _emailController.dispose();
    _contactController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isSubmitting = true);

    try {
      final success = await ApiService.submitContactForm(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        contact: _contactController.text.trim(),
        message: _messageController.text.trim(),
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Message sent successfully!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        _nameController.clear();
        _emailController.clear();
        _contactController.clear();
        _messageController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
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
      child: Column(
        children: [
          // Section Header
          _SectionHeader(
            title: 'Get In Touch',
            subtitle: "Let's discuss your next project or opportunity",
          ),
          SizedBox(height: isMobile ? 32 : 48),

          // Content
          if (isMobile || isTablet)
            _buildMobileLayout(context, t)
          else
            _buildDesktopLayout(context, t),

          SizedBox(height: isMobile ? 48 : 64),

          // Footer
          _Footer(),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, AppThemeData t) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left: Contact info
        Expanded(
          flex: 4,
          child: _ContactInfo(),
        ),
        const SizedBox(width: 48),
        // Right: Contact form
        Expanded(
          flex: 5,
          child: _ContactForm(
            formKey: _formKey,
            nameController: _nameController,
            emailController: _emailController,
            contactController: _contactController,
            messageController: _messageController,
            isSubmitting: isSubmitting,
            onSubmit: _submitForm,
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context, AppThemeData t) {
    return Column(
      children: [
        _ContactInfo(),
        const SizedBox(height: 32),
        _ContactForm(
          formKey: _formKey,
          nameController: _nameController,
          emailController: _emailController,
          contactController: _contactController,
          messageController: _messageController,
          isSubmitting: isSubmitting,
          onSubmit: _submitForm,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section Header
// ─────────────────────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    final isMobile = Responsive.isMobile(context);
    final titleSize =
        Responsive.fontSize(context, mobile: 28, tablet: 32, desktop: 36);
    final subtitleSize =
        Responsive.fontSize(context, mobile: 14, tablet: 15, desktop: 16);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: isMobile ? 28 : 36,
              decoration: BoxDecoration(
                gradient: t.primaryGradient,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 16),
            ShaderMask(
              shaderCallback: (bounds) => t.primaryGradient.createShader(bounds),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: titleSize,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 20),
          child: Text(
            subtitle,
            style: TextStyle(
              fontSize: subtitleSize,
              color: t.textMuted,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Contact Info
// ─────────────────────────────────────────────────────────────────────────────
class _ContactInfo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    final isMobile = Responsive.isMobile(context);
    final iconBoxSize = isMobile ? 68.0 : 80.0;
    final headingSize =
        Responsive.fontSize(context, mobile: 22, tablet: 23, desktop: 24);

    return Container(
      padding: EdgeInsets.all(isMobile ? 24 : 32),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: t.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Illustration/Icon
          Container(
            width: iconBoxSize,
            height: iconBoxSize,
            decoration: BoxDecoration(
              gradient: t.primaryGradient,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: const Icon(
              Icons.mail_outline_rounded,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),

          Text(
            "Let's work together",
            style: TextStyle(
              fontSize: headingSize,
              fontWeight: FontWeight.w700,
              color: t.text,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "I'm always open to discussing new projects, creative ideas, or opportunities to be part of your vision.",
            style: t.bodyMD.copyWith(height: 1.7),
          ),
          const SizedBox(height: 32),

          // Contact methods
          _ContactMethod(
            icon: Icons.email_outlined,
            label: 'Email',
            value: 'charles@example.com',
            color: t.primary,
          ),
          const SizedBox(height: 16),
          _ContactMethod(
            icon: Icons.phone_outlined,
            label: 'Phone',
            value: '+1 (555) 123-4567',
            color: t.accent,
          ),
          const SizedBox(height: 16),
          _ContactMethod(
            icon: Icons.location_on_outlined,
            label: 'Location',
            value: 'San Francisco, CA',
            color: t.accentAlt,
          ),
          const SizedBox(height: 32),

          // Social links
          Text(
            'Connect with me',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: t.text,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _SocialButton(icon: FontAwesomeIcons.github),
              _SocialButton(icon: FontAwesomeIcons.linkedin),
              _SocialButton(icon: FontAwesomeIcons.xTwitter),
              _SocialButton(icon: FontAwesomeIcons.instagram),
            ],
          ),
        ],
      ),
    );
  }
}

class _ContactMethod extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _ContactMethod({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    final isMobile = Responsive.isMobile(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: t.textMuted,
                ),
              ),
              Text(
                value,
                softWrap: true,
                style: TextStyle(
                  fontSize: isMobile ? 14 : 15,
                  fontWeight: FontWeight.w600,
                  color: t.text,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SocialButton extends StatefulWidget {
  final IconData icon;

  const _SocialButton({required this.icon});

  @override
  State<_SocialButton> createState() => _SocialButtonState();
}

class _SocialButtonState extends State<_SocialButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: AppAnimations.fast,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _hovered ? t.primary.withValues(alpha: 0.1) : t.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: _hovered ? t.primary.withValues(alpha: 0.4) : t.border,
          ),
        ),
        child: FaIcon(
          widget.icon,
          size: 18,
          color: _hovered ? t.primary : t.textMuted,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Contact Form
// ─────────────────────────────────────────────────────────────────────────────
class _ContactForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController contactController;
  final TextEditingController messageController;
  final bool isSubmitting;
  final VoidCallback onSubmit;

  const _ContactForm({
    required this.formKey,
    required this.nameController,
    required this.emailController,
    required this.contactController,
    required this.messageController,
    required this.isSubmitting,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    final isMobile = Responsive.isMobile(context);
    final headingSize =
        Responsive.fontSize(context, mobile: 19, tablet: 20, desktop: 20);

    return Container(
      padding: EdgeInsets.all(isMobile ? 24 : 32),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: t.border),
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Send a Message',
              style: TextStyle(
                fontSize: headingSize,
                fontWeight: FontWeight.w700,
                color: t.text,
              ),
            ),
            const SizedBox(height: 24),

            // Name & Email row
            if (!isMobile)
              Row(
                children: [
                  Expanded(
                    child: _FormField(
                      controller: nameController,
                      label: 'Your Name',
                      hint: 'John Doe',
                      icon: Icons.person_outline,
                      validator: (v) =>
                          v?.isEmpty == true ? 'Name is required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _FormField(
                      controller: emailController,
                      label: 'Email Address',
                      hint: 'john@example.com',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v?.isEmpty == true) return 'Email is required';
                        if (!v!.contains('@')) return 'Invalid email';
                        return null;
                      },
                    ),
                  ),
                ],
              )
            else ...[
              _FormField(
                controller: nameController,
                label: 'Your Name',
                hint: 'John Doe',
                icon: Icons.person_outline,
                validator: (v) =>
                    v?.isEmpty == true ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
              _FormField(
                controller: emailController,
                label: 'Email Address',
                hint: 'john@example.com',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v?.isEmpty == true) return 'Email is required';
                  if (!v!.contains('@')) return 'Invalid email';
                  return null;
                },
              ),
            ],
            const SizedBox(height: 16),

            _FormField(
              controller: contactController,
              label: 'Phone Number',
              hint: '+1 (555) 123-4567',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: (v) =>
                  v?.isEmpty == true ? 'Phone is required' : null,
            ),
            const SizedBox(height: 16),

            _FormField(
              controller: messageController,
              label: 'Your Message',
              hint: 'Tell me about your project...',
              icon: Icons.message_outlined,
              maxLines: 5,
              validator: (v) =>
                  v?.isEmpty == true ? 'Message is required' : null,
            ),
            const SizedBox(height: 24),

            // Submit button
            _SubmitButton(
              isSubmitting: isSubmitting,
              onTap: onSubmit,
            ),
          ],
        ),
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _FormField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: t.text,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          style: TextStyle(color: t.text, fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: t.textMuted.withValues(alpha: 0.6)),
            prefixIcon: maxLines == 1
                ? Icon(icon, size: 20, color: t.textMuted)
                : null,
            filled: true,
            fillColor: t.surface,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: maxLines > 1 ? 16 : 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(color: t.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(color: t.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(color: t.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(color: AppColors.error),
            ),
          ),
        ),
      ],
    );
  }
}

class _SubmitButton extends StatefulWidget {
  final bool isSubmitting;
  final VoidCallback onTap;

  const _SubmitButton({required this.isSubmitting, required this.onTap});

  @override
  State<_SubmitButton> createState() => _SubmitButtonState();
}

class _SubmitButtonState extends State<_SubmitButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.isSubmitting ? null : widget.onTap,
        child: AnimatedContainer(
          duration: AppAnimations.fast,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: t.primaryGradient,
            borderRadius: BorderRadius.circular(AppRadius.md),
            boxShadow: [
              BoxShadow(
                color: t.primary.withValues(alpha: _hovered ? 0.4 : 0.25),
                blurRadius: _hovered ? 20 : 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: widget.isSubmitting
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Send Message',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      AnimatedContainer(
                        duration: AppAnimations.fast,
                        transform: Matrix4.translationValues(
                          _hovered ? 4 : 0,
                          0,
                          0,
                        ),
                        child: const Icon(
                          Icons.send_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Footer
// ─────────────────────────────────────────────────────────────────────────────
class _Footer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    final year = DateTime.now().year;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: t.border)),
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 4,
        runSpacing: 4,
        children: [
          Text(
            '© $year Portfolio. Built with ',
            style: TextStyle(fontSize: 13, color: t.textMuted),
          ),
          Icon(Icons.favorite, size: 14, color: t.primary),
          Text(
            ' using Flutter',
            style: TextStyle(fontSize: 13, color: t.textMuted),
          ),
        ],
      ),
    );
  }
}
