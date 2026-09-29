import 'package:campusconnect/utils/constants.dart';
import 'package:flutter/material.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});
  static const routeName="/LoginView";
  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  static const Color _background = Color(0xFFF4F7FC);
  static const Color _fieldColor = Color(0xFFF1F4FA);
  static const Color _textDark = Color(0xFF16213E);
  static const Color _textMuted = Color(0xFF6B7A99);
  static const Color _errorColor = Color(0xFFE5484D);

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _isSignIn = true;
  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _setMode(bool signIn) {
    if (signIn == _isSignIn) return;
    setState(() {
      _isSignIn = signIn;
      _formKey.currentState?.reset();
    });
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    // TODO: hook up Firebase Auth sign in / sign up here.
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => _loading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: _textDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(
          _isSignIn ? 'Signed in successfully' : 'Account created successfully',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            Transform.translate(
              offset: const Offset(0, -60),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: _buildCard(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return ClipPath(
      clipper: _WaveClipper(),
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Constants.deepBlue,
              Constants.primaryBlue,
              Constants.lightBlue,
            ],
          ),
        ),

        child: Stack(
          children: [
            // Soft decorative bubbles.
            Positioned(top: -70, right: -30, child: _bubble(160, 0.10)),
            Positioned(top: 90, left: -50, child: _bubble(120, 0.08)),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 110),
                child: Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: Image.asset(
                          '${Constants.ImagePath}logo.png',
                          height: 84,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'CampusConnect',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Your campus, all in one place',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bubble(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
      ),
    );
  }

  Widget _buildCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Constants.deepBlue.withValues(alpha: 0.12),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildModeToggle(),
          const SizedBox(height: 22),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SizeTransition(
                sizeFactor: animation,
                axisAlignment: -1,
                child: child,
              ),
            ),
            child: _buildForm(),
          ),
        ],
      ),
    );
  }

  Widget _buildModeToggle() {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _fieldColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            alignment:
                _isSignIn ? Alignment.centerLeft : Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              heightFactor: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: [
              _toggleLabel('Sign In', true),
              _toggleLabel('Sign Up', false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _toggleLabel(String text, bool signIn) {
    final selected = _isSignIn == signIn;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _setMode(signIn),
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              color: selected ? Constants.primaryBlue : _textMuted,
              fontSize: 15,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
            child: Text(text),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        // Key changes with the mode so AnimatedSwitcher animates the swap.
        key: ValueKey(_isSignIn),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _isSignIn ? 'Welcome back 👋' : 'Create your account',
            style: const TextStyle(
              color: _textDark,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _isSignIn
                ? 'Sign in to continue to your campus.'
                : 'Join your campus community in seconds.',
            style: const TextStyle(color: _textMuted, fontSize: 14),
          ),
          const SizedBox(height: 20),
          if (!_isSignIn) ...[
            _buildField(
              controller: _nameController,
              hint: 'Full name',
              icon: Icons.person_outline_rounded,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Please enter your name.'
                  : null,
            ),
            const SizedBox(height: 14),
          ],
          _buildField(
            controller: _emailController,
            hint: 'Email address',
            icon: Icons.alternate_email_rounded,
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              final value = v?.trim() ?? '';
              if (value.isEmpty) return 'Please enter your email.';
              if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) {
                return 'Please enter a valid email.';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          _buildField(
            controller: _passwordController,
            hint: 'Password',
            icon: Icons.lock_outline_rounded,
            obscure: _obscurePassword,
            suffix: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: _textMuted,
                size: 20,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Please enter your password.';
              if (v.length < 6) {
                return 'Password must be at least 6 characters.';
              }
              return null;
            },
          ),
          if (!_isSignIn) ...[
            const SizedBox(height: 14),
            _buildField(
              controller: _confirmController,
              hint: 'Confirm password',
              icon: Icons.lock_outline_rounded,
              obscure: _obscurePassword,
              validator: (v) => v != _passwordController.text
                  ? 'Passwords do not match.'
                  : null,
            ),
          ],
          const SizedBox(height: 8),
          if (_isSignIn)
            Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: _rememberMe,
                    onChanged: (v) => setState(() => _rememberMe = v ?? false),
                    activeColor: Constants.primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                    side: const BorderSide(color: _textMuted, width: 1.2),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Remember me',
                  style: TextStyle(color: _textMuted, fontSize: 13.5),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {},
                  child: const Text(
                    'Forgot password?',
                    style: TextStyle(
                      color: Constants.primaryBlue,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            )
          else
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Text(
                'By signing up you agree to our Terms of Use and Privacy Policy.',
                style: TextStyle(color: _textMuted, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          const SizedBox(height: 12),
          _buildPrimaryButton(),
          const SizedBox(height: 22),
          const Row(
            children: [
              Expanded(child: Divider(color: Color(0xFFE3E8F2))),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'or continue with',
                  style: TextStyle(color: _textMuted, fontSize: 13),
                ),
              ),
              Expanded(child: Divider(color: Color(0xFFE3E8F2))),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.g_mobiledata_rounded, size: 32),
              label: const Text(
                'Google',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: _textDark,
                side: const BorderSide(color: Color(0xFFE3E8F2), width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _isSignIn
                    ? "Don't have an account?"
                    : 'Already have an account?',
                style: const TextStyle(color: _textMuted, fontSize: 14),
              ),
              TextButton(
                onPressed: () => _setMode(!_isSignIn),
                child: Text(
                  _isSignIn ? 'Sign up' : 'Sign in',
                  style: const TextStyle(
                    color: Constants.primaryBlue,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton() {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: _loading ? 0.7 : 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            colors: [Constants.deepBlue, Constants.primaryBlue],
          ),
          boxShadow: [
            BoxShadow(
              color: Constants.primaryBlue.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: SizedBox(
          height: 54,
          child: ElevatedButton(
            onPressed: _loading ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              disabledBackgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              foregroundColor: Colors.white,
              disabledForegroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: _loading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isSignIn ? 'Sign In' : 'Create Account',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 20),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    bool obscure = false,
    Widget? suffix,
  }) {
    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: color, width: 1.5),
    );

    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      obscureText: obscure,
      cursorColor: Constants.primaryBlue,
      style: const TextStyle(color: _textDark, fontSize: 15.5),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _textMuted),
        prefixIcon: Icon(icon, color: Constants.primaryBlue, size: 21),
        suffixIcon: suffix,
        filled: true,
        fillColor: _fieldColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 17,
        ),
        border: border(Colors.transparent),
        enabledBorder: border(Colors.transparent),
        focusedBorder: border(Constants.primaryBlue),
        errorBorder: border(_errorColor),
        focusedErrorBorder: border(_errorColor),
        errorStyle: const TextStyle(color: _errorColor),
      ),
    );
  }
}

/// Curved bottom edge for the gradient header.
class _WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()..lineTo(0, size.height - 50);
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height,
      size.width * 0.5,
      size.height - 30,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height - 60,
      size.width,
      size.height - 20,
    );
    path
      ..lineTo(size.width, 0)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
