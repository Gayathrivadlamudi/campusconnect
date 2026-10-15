import 'package:campusconnect/utils/constants.dart';
import 'package:campusconnect/views/admin_home_view.dart';
import 'package:campusconnect/views/student_home_view.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key, this.isAdmin = false});
  static const routeName="/LoginView";
  static const adminRouteName="/AdminLoginView";

  /// Same screen for admins, with admin labels and no sign up.
  final bool isAdmin;
  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  static const Color _background = Color(0xFFF4F7FC);
  static const Color _fieldColor = Color(0xFFF1F4FA);
  static const Color _textDark = Color(0xFF16213E);
  static const Color _textMuted = Color(0xFF6B7A99);
  static const Color _errorColor = Color(0xFFE5484D);

  // Sign in and sign up each get their own form key and controllers so
  // switching modes never leaks input from one form into the other.
  final _signInFormKey = GlobalKey<FormState>();
  final _signInEmailController = TextEditingController();
  final _signInPasswordController = TextEditingController();

  final _signUpFormKey = GlobalKey<FormState>();
  final _signUpNameController = TextEditingController();
  final _signUpEmailController = TextEditingController();
  final _signUpPasswordController = TextEditingController();
  final _signUpConfirmController = TextEditingController();

  static final FirebaseAuth auth=FirebaseAuth.instance;
  static final FirebaseFirestore db=FirebaseFirestore.instance;

  bool _isSignIn = true;
  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _loading = false;

  @override
  void dispose() {
    _signInEmailController.dispose();
    _signInPasswordController.dispose();
    _signUpNameController.dispose();
    _signUpEmailController.dispose();
    _signUpPasswordController.dispose();
    _signUpConfirmController.dispose();
    super.dispose();
  }

  void _setMode(bool signIn) {
    if (signIn == _isSignIn) return;
    setState(() => _isSignIn = signIn);
  }
//streambuilder is a flutter widget that listens to the data and updated the ui automatically
  //Imagine your app needs to know whether a student is logged in.
  //If the student is logged in → Show the Home Screen.
  // If the student is not logged in → Show the Login Screen.
  //stream:continuosly sends the updates
  //streamBuilder:listens to the updates
  //ui:updates the ui
  //StreamBuilder<User?>(
  //StreamBuilder is the Flutter widget.,User is the Firebase Authentication user type.,? means the value can also be null.
 // stream: FirebaseAuth.instance.authStateChanges(),
  // FirebaseAuth.instance.authStateChanges(), it is the sensor
  submit() async {
    FocusScope.of(context).unfocus();
    final formKey = _isSignIn ? _signInFormKey : _signUpFormKey;
    if (!formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try  {
      if(_isSignIn){
          final UserCredential credential=await auth.signInWithEmailAndPassword(
              email: _signInEmailController.text.trim(),
              password: _signInPasswordController.text.trim());
          if (widget.isAdmin) {
            // Only users with a document in the `admins` collection are admins.
            final adminDoc = await db.collection('adminProfiles')
                .doc(credential.user!.uid)
                .get();
            if (!adminDoc.exists) {
              debugPrint('No admin doc at admins/${credential.user!.uid} '
                  'for ${credential.user!.email}');
              await auth.signOut();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('This account does not have admin access.'),
                backgroundColor: _errorColor,
                behavior: SnackBarBehavior.floating,
              ));
              return;
            }
            debugPrint('Admin login successful: ${credential.user?.email}');
            Get.offNamed(AdminHomeView.routeName);
            return;
          }
          debugPrint('Login successful');
          debugPrint('UID: ${credential.user?.uid}');
          debugPrint('Email: ${credential.user?.email}');
      }
      //creating new user
      else{
        final UserCredential credential=await auth.createUserWithEmailAndPassword(
          email:  _signUpEmailController.text.trim(),
          password:_signUpPasswordController.text.trim());
        // Save the user's name in their Firebase Auth profile.
        await credential.user?.updateDisplayName(
          _signUpNameController.text.trim(),);
        // Reload so the user object carries the new display name.
        await credential.user?.reload();
        final User? user = auth.currentUser;
        if (user != null) {
          await saveUserProfile(user);
        }

        debugPrint('Account created successfully');
        debugPrint('UID: ${credential.user?.uid}');
        debugPrint('Email: ${credential.user?.email}');
        debugPrint('Name: ${credential.user?.displayName}');
      }
      if(!mounted){
        return;
    }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:Text(
          _isSignIn?"Signed in successfully":"Created account successfully"
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ));
      Get.offAllNamed(StudentHomeView.routeName);
    }
    on FirebaseAuthException catch (e) {
      String message;

      switch (e.code) {
        case 'invalid-email':
          message = 'Please enter a valid email address.';
          break;
        case 'email-already-in-use':
          message = 'An account already exists with this email.';
          break;
        case 'weak-password':
          message = 'Please choose a stronger password.';
          break;
        case 'user-not-found':
          message = 'No account found. Please sign up first.';
          break;
        case 'wrong-password':
          message = 'Incorrect email or password.';
          break;
        case 'invalid-credential':
          message = 'Invalid email or password. Please check your details or sign up.';
          break;
        case 'user-disabled':
          message = 'This account has been disabled.';
          break;
        case 'too-many-requests':
          message = 'Too many attempts. Please try again later.';
          break;
        case 'network-request-failed':
          message = 'Check your internet connection.';
          break;
        default:
          message = 'Authentication failed. Please try again.';
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: _errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    catch(e,stackTrace){
      debugPrint('Authentication error: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Something went wrong. Please try again.'),
          backgroundColor: _errorColor,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
    }


    Future<void> saveUserProfile(User user)async{
      try{
        await db.collection('userProfiles').doc(user.uid).set({
          'uid': user.uid,
          'name': user.displayName,
          'email': user.email,
          'role':"student",
          'createdAt': DateTime.now(),
        });
        debugPrint('User profile saved successfully.');
      }
      on FirebaseException catch(e,stackTrace){
        debugPrint('Firestore error: ${e.code}');
        debugPrint('Error message: ${e.message}');
        debugPrintStack(stackTrace: stackTrace);
      }
      catch(e,stackTrace){
        debugPrint('Unexpected error while saving profile: $e');
        debugPrintStack(stackTrace: stackTrace);
      }
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
            // Card is shifted up by 60, so pull the admin link up to match.
            Transform.translate(
              offset: const Offset(0, -48),
              child: TextButton.icon(
                onPressed: () => widget.isAdmin
                    ? Get.back()
                    : Get.toNamed(LoginView.adminRouteName),
                icon: Icon(
                  widget.isAdmin
                      ? Icons.school_outlined
                      : Icons.admin_panel_settings_outlined,
                  color: _textMuted,
                  size: 20,
                ),
                label: Text(
                  widget.isAdmin ? 'Login as Student' : 'Login as Admin',
                  style: const TextStyle(
                    color: _textMuted,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
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
                        widget.isAdmin
                            ? 'Admin Portal'
                            : 'Your campus, all in one place',
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
          if (!widget.isAdmin) ...[
            _buildModeToggle(),
            const SizedBox(height: 22),
          ],
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
    final emailController =
        _isSignIn ? _signInEmailController : _signUpEmailController;
    final passwordController =
        _isSignIn ? _signInPasswordController : _signUpPasswordController;
    return Form(
      // Key changes with the mode so AnimatedSwitcher animates the swap.
      key: _isSignIn ? _signInFormKey : _signUpFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.isAdmin
                ? 'Admin Login'
                : _isSignIn ? 'Welcome back 👋' : 'Create your account',
            style: const TextStyle(
              color: _textDark,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.isAdmin
                ? 'Sign in with your admin account.'
                : _isSignIn
                    ? 'Sign in to continue to your campus.'
                    : 'Join your campus community in seconds.',
            style: const TextStyle(color: _textMuted, fontSize: 14),
          ),
          const SizedBox(height: 20),
          if (!_isSignIn) ...[
            _buildField(
              controller: _signUpNameController,
              hint: 'Full name',
              icon: Icons.person_outline_rounded,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Please enter your name.'
                  : null,
            ),
            const SizedBox(height: 14),
          ],
          _buildField(
            controller: emailController,
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
            controller: passwordController,
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
              controller: _signUpConfirmController,
              hint: 'Confirm password',
              icon: Icons.lock_outline_rounded,
              obscure: _obscurePassword,
              validator: (v) => v != _signUpPasswordController.text
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
                  onPressed: _showForgotPasswordSheet,
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
          if (!widget.isAdmin) ...[
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
        ],
      ),
    );

  }
  void _showForgotPasswordSheet() {
    FocusScope.of(context).unfocus();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ForgotPasswordSheet(
        initialEmail: _signInEmailController.text.trim(),
        auth: auth,
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
            onPressed: _loading ? null : submit,
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
                        widget.isAdmin
                            ? 'Login as Admin'
                            : _isSignIn ? 'Sign In' : 'Create Account',
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

/// Bottom sheet that asks for an email and sends a Firebase password reset link.
class _ForgotPasswordSheet extends StatefulWidget {
  const _ForgotPasswordSheet({required this.initialEmail, required this.auth});

  final String initialEmail;
  final FirebaseAuth auth;

  @override
  State<_ForgotPasswordSheet> createState() => _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends State<_ForgotPasswordSheet> {
  static const Color _fieldColor = Color(0xFFF1F4FA);
  static const Color _textDark = Color(0xFF16213E);
  static const Color _textMuted = Color(0xFF6B7A99);
  static const Color _errorColor = Color(0xFFE5484D);

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController =
      TextEditingController(text: widget.initialEmail);

  bool _sending = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendLink() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await widget.auth.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );
      if (!mounted) return;
      setState(() => _sent = true);
    } on FirebaseAuthException catch (e) {
      debugPrint('Password reset error: ${e.code}');
      String message;
      switch (e.code) {
        case 'invalid-email':
          message = 'Please enter a valid email address.';
          break;
        case 'user-not-found':
          message = 'No account found with this email.';
          break;
        case 'too-many-requests':
          message = 'Too many attempts. Please try again later.';
          break;
        case 'network-request-failed':
          message = 'Check your internet connection.';
          break;
        default:
          message = 'Unable to send reset email. Please try again.';
      }
      if (!mounted) return;
      setState(() => _error = message);
    } catch (e) {
      debugPrint('Password reset error: $e');
      if (!mounted) return;
      setState(() => _error = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Lift the sheet above the keyboard.
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _sent ? _buildSuccess() : _buildForm(),
          ),
        ),
      ),
    );
  }

  Widget _handle() {
    return Center(
      child: Container(
        width: 44,
        height: 5,
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFE3E8F2),
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }

  Widget _iconBadge(IconData icon) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Constants.primaryBlue.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Constants.primaryBlue, size: 34),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        key: const ValueKey('form'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _handle(),
          _iconBadge(Icons.lock_reset_rounded),
          const SizedBox(height: 16),
          const Text(
            'Forgot password?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _textDark,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "Enter the email linked to your account and we'll send you a link to reset your password.",
            textAlign: TextAlign.center,
            style: TextStyle(color: _textMuted, fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 22),
          TextFormField(
            controller: _emailController,
            autofocus: widget.initialEmail.isEmpty,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.send,
            onFieldSubmitted: (_) => _sending ? null : _sendLink(),
            cursorColor: Constants.primaryBlue,
            style: const TextStyle(color: _textDark, fontSize: 15.5),
            validator: (v) {
              final value = v?.trim() ?? '';
              if (value.isEmpty) return 'Please enter your email.';
              if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) {
                return 'Please enter a valid email.';
              }
              return null;
            },
            decoration: InputDecoration(
              hintText: 'Email address',
              hintStyle: const TextStyle(color: _textMuted),
              prefixIcon: const Icon(
                Icons.alternate_email_rounded,
                color: Constants.primaryBlue,
                size: 21,
              ),
              filled: true,
              fillColor: _fieldColor,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 17,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: Constants.primaryBlue,
                  width: 1.5,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _errorColor, width: 1.5),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _errorColor, width: 1.5),
              ),
              errorStyle: const TextStyle(color: _errorColor),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(
              _error!,
              style: const TextStyle(color: _errorColor, fontSize: 13),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: _sending ? null : _sendLink,
              style: ElevatedButton.styleFrom(
                backgroundColor: Constants.primaryBlue,
                disabledBackgroundColor:
                    Constants.primaryBlue.withValues(alpha: 0.7),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _sending
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Send reset link',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
            ),
          ),
          const SizedBox(height: 6),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Back to sign in',
              style: TextStyle(
                color: _textMuted,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess() {
    return Column(
      key: const ValueKey('success'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _handle(),
        _iconBadge(Icons.mark_email_read_outlined),
        const SizedBox(height: 16),
        const Text(
          'Check your inbox',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _textDark,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text.rich(
          TextSpan(
            text: 'If an account exists for ',
            children: [
              TextSpan(
                text: _emailController.text.trim(),
                style: const TextStyle(
                  color: _textDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const TextSpan(
                text:
                    ", you'll get a link to reset your password. Don't forget to check your spam folder.",
              ),
            ],
          ),
          textAlign: TextAlign.center,
          style: const TextStyle(color: _textMuted, fontSize: 14, height: 1.4),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 54,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Constants.primaryBlue,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Back to sign in',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(height: 6),
        TextButton(
          onPressed: _sending
              ? null
              : () => setState(() {
                    _sent = false;
                    _error = null;
                  }),
          child: const Text(
            "Didn't get it? Try again",
            style: TextStyle(
              color: Constants.primaryBlue,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
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
