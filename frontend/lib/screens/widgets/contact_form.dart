import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:portfolio/core/app_theme.dart';
import 'package:portfolio/core/responsive.dart';
import 'package:portfolio/screens/widgets/contact_success_dialog.dart';
import 'package:portfolio/services/portfolio_api.dart';

class ContactForm extends StatefulWidget {
  final String ownerName;
  final String recipientEmail;

  const ContactForm({
    super.key,
    required this.ownerName,
    required this.recipientEmail,
  });

  @override
  State<ContactForm> createState() => _ContactFormState();
}

class _ContactFormState extends State<ContactForm> {
  static const _emailDomains = [
    'gmail.com',
    'outlook.com',
    'icloud.com',
    'company.in',
  ];
  static const _messageSuggestions = [
    "I'd like to discuss a collaboration.",
    "I'm interested in learning more about your work.",
    "Let's connect regarding an opportunity.",
    "I have an exciting project I'd like to discuss.",
    "I'd like to know if you are available to work together.",
  ];

  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _message = TextEditingController();
  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _messageFocus = FocusNode();
  int _messageSuggestionIndex = 0;
  bool _dismissedNameSuggestion = false;
  bool _isSubmitting = false;
  bool _submitHovered = false;

  @override
  void initState() {
    super.initState();
    _name.addListener(_onNameChanged);
    _email.addListener(_refresh);
    _message.addListener(_refresh);
    _nameFocus.addListener(_refresh);
    _emailFocus.addListener(_refresh);
    _messageFocus.addListener(_refresh);
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _message.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _messageFocus.dispose();
    super.dispose();
  }

  void _onNameChanged() {
    if (_name.text.isNotEmpty) _dismissedNameSuggestion = true;
    _refresh();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  String get _suggestedName {
    if (_dismissedNameSuggestion || _name.text.isNotEmpty) return '';
    final localPart = _email.text.trim().split('@').first;
    if (!RegExp(r'^[a-zA-Z][a-zA-Z._-]*$').hasMatch(localPart)) return '';
    final firstPart = localPart.split(RegExp(r'[._-]+')).first;
    if (firstPart.length < 2) return '';
    return '${firstPart[0].toUpperCase()}${firstPart.substring(1).toLowerCase()}';
  }

  String get _emailSuffix {
    final value = _email.text.trim();
    if (value.isEmpty || value.endsWith('@')) {
      return value.endsWith('@') ? 'gmail.com' : '';
    }
    if (value.contains('@')) {
      final parts = value.split('@');
      if (parts.length != 2 || parts.first.isEmpty) return '';
      final match = _emailDomains.cast<String?>().firstWhere(
            (domain) => domain!.startsWith(parts.last.toLowerCase()),
            orElse: () => null,
          );
      return match == null ? '' : match.substring(parts.last.length);
    }
    return RegExp(r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+$").hasMatch(value)
        ? '@gmail.com'
        : '';
  }

  String _completedEmail() => '${_email.text}$_emailSuffix';

  bool get _showMessageSuggestions =>
      _messageFocus.hasFocus && _message.text.trim().isEmpty;

  KeyEventResult _handleNameKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent || _suggestedName.isEmpty) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.tab) {
      _name.value = TextEditingValue(
        text: _suggestedName,
        selection: TextSelection.collapsed(offset: _suggestedName.length),
      );
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.space) {
      setState(() => _dismissedNameSuggestion = true);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  KeyEventResult _handleEmailKey(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent &&
        (event.logicalKey == LogicalKeyboardKey.tab ||
            event.logicalKey == LogicalKeyboardKey.enter) &&
        _emailSuffix.isNotEmpty) {
      final email = _completedEmail();
      _email.value = TextEditingValue(
        text: email,
        selection: TextSelection.collapsed(offset: email.length),
      );
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  KeyEventResult _handleMessageKey(FocusNode node, KeyEvent event) {
    if (!_showMessageSuggestions || event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      setState(() {
        _messageSuggestionIndex =
            (_messageSuggestionIndex + 1) % _messageSuggestions.length;
      });
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      setState(() {
        _messageSuggestionIndex =
            (_messageSuggestionIndex - 1 + _messageSuggestions.length) %
                _messageSuggestions.length;
      });
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.tab ||
        event.logicalKey == LogicalKeyboardKey.enter) {
      _useMessageSuggestion(_messageSuggestionIndex);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _useMessageSuggestion(int index) {
    final suggestion = _messageSuggestions[index];
    _message.text = suggestion;
    _message.selection = TextSelection.collapsed(offset: suggestion.length);
    _messageFocus.requestFocus();
  }

  String? _validateName(String? value) {
    return _meaningfulText(
      value,
      field: 'name',
      minLength: 2,
      maxLength: 30,
      alphabeticOnly: true,
    );
  }

  String? _validateMessage(String? value) => _meaningfulText(
        value,
        field: 'message',
        minLength: 15,
        maxLength: 500,
      );

  String? _meaningfulText(
    String? value, {
    required String field,
    required int minLength,
    required int maxLength,
    bool alphabeticOnly = false,
  }) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Please enter your $field.';
    if (text.length < minLength) {
      return '$field must be at least $minLength characters.';
    }
    if (text.length > maxLength) {
      return '$field must be $maxLength characters or fewer.';
    }
    if (RegExp(r'^(.)\1{2,}$').hasMatch(text.toLowerCase()) ||
        const {'xxx', 'test', 'abc', '123', 'asdf'}
            .contains(text.toLowerCase())) {
      return 'Please enter a meaningful $field.';
    }
    if (alphabeticOnly &&
        !RegExp(r"^[a-zA-Z]+(?:[ '-][a-zA-Z]+)*$").hasMatch(text)) {
      return 'Use alphabetic characters only.';
    }
    return null;
  }

  Uri _mailtoUri() {
    final body = '''Hello ${widget.ownerName},

Someone would like to connect with you through your portfolio.

Name: ${_name.text.trim()}

Email: ${_email.text.trim()}

Message: ${_message.text.trim()}

---

Sent from your Portfolio Website''';
    return Uri(
      scheme: 'mailto',
      path: widget.recipientEmail,
      queryParameters: {
        'subject': 'Portfolio Contact Request - ${_name.text.trim()}',
        'body': body,
      },
    );
  }

  Future<void> _submit() async {
    if (_isSubmitting || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSubmitting = true);
    try {
      await PortfolioApi.submitContactForm(
        name: _name.text.trim(),
        email: _email.text.trim(),
        message: _message.text.trim(),
      );
      if (!mounted) return;
      await ContactSuccessDialog.show(context, _mailtoUri());
      if (!mounted) return;
      _formKey.currentState?.reset();
      _name.clear();
      _email.clear();
      _message.clear();
      setState(() {
        _dismissedNameSuggestion = false;
        _messageSuggestionIndex = 0;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              error.toString().replaceFirst('Exception: ', ''),
            ),
          ),
        );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  InputDecoration _decoration(
    BuildContext context, {
    required String label,
    required String hint,
    bool hideHint = false,
  }) {
    final t = AppTheme.of(context);
    final border = UnderlineInputBorder(
      borderSide: BorderSide(color: t.border),
    );
    return InputDecoration(
      labelText: label,
      hintText: hideHint ? null : hint,
      filled: false,
      isDense: true,
      contentPadding: const EdgeInsets.fromLTRB(0, 16, 0, 12),
      hintStyle: t.body.copyWith(color: t.text.withValues(alpha: 0.36)),
      labelStyle: t.label.copyWith(color: t.textMuted),
      errorStyle: t.label.copyWith(color: AppColors.danger),
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: BorderSide(color: t.button, width: 1.5),
      ),
      errorBorder: border.copyWith(
        borderSide: const BorderSide(color: AppColors.danger),
      ),
      focusedErrorBorder: border.copyWith(
        borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
      ),
    );
  }

  Widget _nameField(BuildContext context) => Focus(
        onKeyEvent: _handleNameKey,
        child: TextFormField(
          controller: _name,
          focusNode: _nameFocus,
          autofillHints: const [AutofillHints.name],
          textInputAction: TextInputAction.next,
          decoration: _decoration(
            context,
            label: 'Name',
            hint: _suggestedName.isEmpty
                ? 'Your name'
                : 'Suggested: $_suggestedName (Tab to use)',
            hideHint: _nameFocus.hasFocus,
          ),
          validator: _validateName,
        ),
      );

  Widget _emailField(BuildContext context) => Focus(
        onKeyEvent: _handleEmailKey,
        child: TextFormField(
          controller: _email,
          focusNode: _emailFocus,
          autofillHints: const [AutofillHints.email],
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          decoration: _decoration(
            context,
            label: 'Email',
            hint: 'you@example.com',
            hideHint: _emailFocus.hasFocus,
          ),
          validator: (value) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                  .hasMatch(value?.trim() ?? '')
              ? null
              : 'Please enter a valid email address.',
        ),
      );

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.of(context);
    return AutofillGroup(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (Responsive.isMobile(context)) ...[
              _nameField(context),
              const SizedBox(height: AppSpacing.lg),
              _emailField(context),
            ] else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _nameField(context)),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(child: _emailField(context)),
                ],
              ),
            AnimatedSize(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOutCubic,
              child: _emailFocus.hasFocus && _emailSuffix.isNotEmpty
                  ? Align(
                      alignment: Alignment.centerLeft,
                      child: Semantics(
                        button: true,
                        label: 'Use suggested email ${_completedEmail()}',
                        child: TextButton(
                          onPressed: () {
                            final completed = _completedEmail();
                            _email.value = TextEditingValue(
                              text: completed,
                              selection: TextSelection.collapsed(
                                offset: completed.length,
                              ),
                            );
                            _emailFocus.requestFocus();
                          },
                          style: TextButton.styleFrom(
                            minimumSize: const Size(48, 40),
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm),
                            foregroundColor: t.text.withValues(alpha: 0.58),
                          ),
                          child: Text(_completedEmail()),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            const SizedBox(height: AppSpacing.lg),
            Focus(
              onKeyEvent: _handleMessageKey,
              child: TextFormField(
                controller: _message,
                focusNode: _messageFocus,
                minLines: 5,
                maxLines: 7,
                maxLength: 500,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                decoration: _decoration(
                  context,
                  label: 'Message',
                  hint:
                      'Share a meaningful message. Emoji and links are welcome.',
                  hideHint: _messageFocus.hasFocus,
                ),
                validator: _validateMessage,
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              child: _showMessageSuggestions
                  ? Container(
                      height: 52,
                      margin: const EdgeInsets.only(top: AppSpacing.xs),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: t.border),
                        ),
                      ),
                      child: Semantics(
                        label:
                            'Message suggestions. Use arrow keys and Tab, or tap a suggestion.',
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.xs),
                          itemCount: _messageSuggestions.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: AppSpacing.sm),
                          itemBuilder: (context, index) => ChoiceChip(
                            label: Text(_messageSuggestions[index]),
                            selected: index == _messageSuggestionIndex,
                            onSelected: (_) => _useMessageSuggestion(index),
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Your information is used only to respond to your inquiry. It is stored securely for that purpose and is not shared.',
              style: t.label,
            ),
            const SizedBox(height: AppSpacing.md),
            Align(
              alignment: Alignment.centerLeft,
              child: MouseRegion(
                onEnter: (_) => setState(() => _submitHovered = true),
                onExit: (_) => setState(() => _submitHovered = false),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  transform: Matrix4.translationValues(
                    0,
                    _submitHovered ? -2 : 0,
                    0,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    boxShadow: _submitHovered
                        ? [
                            BoxShadow(
                              color: t.button.withValues(alpha: 0.28),
                              blurRadius: 16,
                              offset: const Offset(0, 7),
                            ),
                          ]
                        : null,
                  ),
                  child: FilledButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(172, 50),
                      backgroundColor: t.button,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Start a Conversation'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
