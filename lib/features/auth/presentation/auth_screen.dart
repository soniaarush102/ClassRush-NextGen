import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

enum AccountRole { teacher, student }

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _isCreatingAccount = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  AccountRole _role = AccountRole.student;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _continue() {
    if (!_formKey.currentState!.validate()) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'The sign-in interface is ready. Secure account connection is the next step.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 760;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(compact ? 20 : 36),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1040),
              child: compact
                  ? _buildFormPanel(context)
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: _buildWelcomePanel(context)),
                        const SizedBox(width: 28),
                        SizedBox(width: 430, child: _buildFormPanel(context)),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomePanel(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 650),
      padding: const EdgeInsets.all(42),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF8A35), Color(0xFFE95D12)],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Brand(),
          const Spacer(),
          const Icon(Icons.draw_rounded, color: Colors.white, size: 64),
          const SizedBox(height: 28),
          Text(
            'A better way\nto learn together.',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  height: 1.08,
                ),
          ),
          const SizedBox(height: 18),
          Text(
            'Meet live. Write together. Make every lesson interactive.',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.92),
                  height: 1.5,
                ),
          ),
          const Spacer(),
          const _BenefitRow(
            icon: Icons.video_call_outlined,
            text: 'Live video classrooms',
          ),
          const SizedBox(height: 16),
          const _BenefitRow(
            icon: Icons.gesture_rounded,
            text: 'One shared collaborative whiteboard',
          ),
          const SizedBox(height: 16),
          const _BenefitRow(
            icon: Icons.picture_as_pdf_outlined,
            text: 'Slides, PDFs and lesson resources',
          ),
        ],
      ),
    );
  }

  Widget _buildFormPanel(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              const _Brand(),
              const SizedBox(height: 30),
              Text(
                _isCreatingAccount ? 'Create your account' : 'Welcome back',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                _isCreatingAccount
                    ? 'Join CLASSRUSH and start learning together.'
                    : 'Sign in to continue to your classroom.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 24),
              Text(
                'I am joining as a',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _RoleChoice(
                      title: 'Student',
                      icon: Icons.school_outlined,
                      selected: _role == AccountRole.student,
                      onTap: () => setState(() => _role = AccountRole.student),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _RoleChoice(
                      title: 'Teacher',
                      icon: Icons.cast_for_education_outlined,
                      selected: _role == AccountRole.teacher,
                      onTap: () => setState(() => _role = AccountRole.teacher),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (_isCreatingAccount) ...[
                _FieldLabel('Full name'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    hintText: 'Enter your name',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Please enter your name'
                      : null,
                ),
                const SizedBox(height: 16),
              ],
              _FieldLabel('Email address'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(
                  hintText: 'you@example.com',
                  prefixIcon: Icon(Icons.mail_outline_rounded),
                ),
                validator: (value) {
                  final email = value?.trim() ?? '';
                  if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
                    return 'Enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _FieldLabel('Password'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                autofillHints: _isCreatingAccount
                    ? const [AutofillHints.newPassword]
                    : const [AutofillHints.password],
                decoration: InputDecoration(
                  hintText: 'Enter your password',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    icon: Icon(_obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.length < 8) {
                    return 'Use at least 8 characters';
                  }
                  return null;
                },
              ),
              if (_isCreatingAccount) ...[
                const SizedBox(height: 16),
                _FieldLabel('Confirm password'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _confirmController,
                  obscureText: _obscureConfirm,
                  decoration: InputDecoration(
                    hintText: 'Re-enter your password',
                    prefixIcon: const Icon(Icons.lock_reset_outlined),
                    suffixIcon: IconButton(
                      tooltip: _obscureConfirm ? 'Show password' : 'Hide password',
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                      icon: Icon(_obscureConfirm
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                    ),
                  ),
                  validator: (value) => value != _passwordController.text
                      ? 'Passwords do not match'
                      : null,
                ),
              ],
              if (!_isCreatingAccount)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Password recovery will be enabled with account services.'),
                      ),
                    ),
                    child: const Text('Forgot password?'),
                  ),
                ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _continue,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 17),
                ),
                child: Text(_isCreatingAccount ? 'Create account' : 'Sign in'),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_isCreatingAccount
                      ? 'Already have an account?'
                      : "Don't have an account?"),
                  TextButton(
                    onPressed: () => setState(
                      () => _isCreatingAccount = !_isCreatingAccount,
                    ),
                    child: Text(_isCreatingAccount ? 'Sign in' : 'Create one'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'By continuing, you agree to use CLASSRUSH responsibly and follow your school or classroom rules.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppTheme.brandOrange,
            borderRadius: BorderRadius.circular(13),
          ),
          child: const Center(
            child: Text(
              'CR',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                letterSpacing: -1,
              ),
            ),
          ),
        ),
        const SizedBox(width: 11),
        const Text(
          'CLASSRUSH',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.1),
        ),
      ],
    );
  }
}

class _RoleChoice extends StatelessWidget {
  const _RoleChoice({
    required this.title,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? AppTheme.brandOrange
        : Theme.of(context).colorScheme.outlineVariant;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.brandOrange.withValues(alpha: 0.09)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color, width: selected ? 1.6 : 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? AppTheme.brandOrange : null),
            const SizedBox(height: 6),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(label, style: Theme.of(context).textTheme.labelLarge);
  }
}

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
