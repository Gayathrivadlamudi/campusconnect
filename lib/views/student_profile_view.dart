import 'dart:io';
import 'package:campusconnect/utils/constants.dart';
import 'package:campusconnect/views/login_view.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class StudentProfileView extends StatefulWidget {
  const StudentProfileView({super.key});
  static const routeName = "/StudentProfileView";

  @override
  State<StudentProfileView> createState() => _StudentProfileViewState();
}

class _StudentProfileViewState extends State<StudentProfileView> {
  static const Color _background = Color(0xFFF4F7FC);
  static const Color _textDark = Color(0xFF16213E);
  static const Color _textMuted = Color(0xFF6B7A99);
  static const Color _errorColor = Color(0xFFE5484D);
  static const Color _fieldColor = Color(0xFFF1F4FA);

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _bioController;
  late TextEditingController _departmentController;
  late TextEditingController _yearController;
  late TextEditingController _studentIdController;
  late TextEditingController _campusController;
  late TextEditingController _interestsController;

  bool _isEditing = false;
  bool _isSaving = false;
  bool _isUploadingImage = false;
  Map<String, dynamic>? _profileData;
  File? _selectedImage;
  String? _profileImageUrl;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final user = _auth.currentUser;
    _nameController =
        TextEditingController( text: user?.displayName?.trim()?? 'Student');
    _phoneController = TextEditingController();
    _bioController = TextEditingController();
    _departmentController = TextEditingController();
    _yearController = TextEditingController();
    _studentIdController = TextEditingController();
    _campusController = TextEditingController();
    _interestsController = TextEditingController();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await _db.collection('userProfiles').doc(user.uid).get();
        if (doc.exists) {
          setState(() {
            _profileData = doc.data();
            _profileImageUrl = _profileData?['profileImageUrl'];
          });
          _phoneController.text = _profileData?['phone'] ?? '';
          _bioController.text = _profileData?['bio'] ?? '';
          _departmentController.text = _profileData?['department'] ?? '';
          _yearController.text = _profileData?['year'] ?? '';
          _studentIdController.text = _profileData?['studentId'] ?? '';
          _campusController.text = _profileData?['campus'] ?? '';
          _interestsController.text = _profileData?['interests'] ?? '';
        }
      }
    } catch (e) {
      debugPrint('Error loading profile data: $e');
    }
  }

  Future<void> _pickImage() async {
    try{
      final XFile? pickedFile=await _imagePicker.pickImage(
        source: ImageSource.gallery,
      imageQuality: 80);
      if(pickedFile!=null){
        setState(() {
          _selectedImage=File(pickedFile.path);
        });
        _showUploadDialog();
      }
    }
    catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _showUploadDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Profile Picture'),
        content: const Text('Do you want to upload this image as your profile picture?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _selectedImage = null);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _uploadProfileImage();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Constants.primaryBlue,
            ),
            child: const Text('Upload'),
          ),
        ],
      ),
    );
  }

  Future<void> _uploadProfileImage() async {
    if (_selectedImage == null) return;

    setState(() => _isUploadingImage = true);
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final fileName = '${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final storageRef = FirebaseStorage.instance.ref().child('profile_images/$fileName');

        await storageRef.putFile(_selectedImage!);
        final downloadUrl = await storageRef.getDownloadURL();

        await _db.collection('userProfiles').doc(user.uid).update({
          'profileImageUrl': downloadUrl,
          'updatedAt': DateTime.now(),
        });

        if (!mounted) return;
        setState(() {
          _profileImageUrl = downloadUrl;
          _selectedImage = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture updated successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error uploading image: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to upload image: $e'),
          backgroundColor: _errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _departmentController.dispose();
    _yearController.dispose();
    _studentIdController.dispose();
    _campusController.dispose();
    _interestsController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Name cannot be empty'),
          backgroundColor: _errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.updateDisplayName(_nameController.text.trim());
        await user.reload();

        await _db.collection('userProfiles').doc(user.uid).update({
          'name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'bio': _bioController.text.trim(),
          'department': _departmentController.text.trim(),
          'year': _yearController.text.trim(),
          'studentId': _studentIdController.text.trim(),
          'campus': _campusController.text.trim(),
          'interests': _interestsController.text.trim(),
          'updatedAt': DateTime.now(),
        });

        if (!mounted) return;
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error updating profile: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile: $e'),
          backgroundColor: _errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _logout() async {
    await _auth.signOut();
    Get.offAllNamed(LoginView.routeName);
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Constants.primaryBlue,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileHeader(user),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildEditableNameSection(),
                  const SizedBox(height: 24),
                  _buildInfoSection(user),
                  const SizedBox(height: 24),
                  _buildActionButtons(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(User? user) {
    return Container(
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
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Stack(
        children: [
          Positioned(top: -60, right: -40, child: _bubble(150, 0.10)),
          Positioned(bottom: -50, left: -30, child: _bubble(110, 0.08)),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      children: [
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Constants.primaryBlue, Constants.lightBlue],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: _selectedImage != null
                              ? ClipOval(
                                  child: Image.file(
                                    _selectedImage!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : _profileImageUrl != null
                                  ? ClipOval(
                                      child: Image.network(
                                        _profileImageUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Center(
                                            child: Text(
                                              (user?.displayName?.trim() ?? 'S')
                                                  .characters
                                                  .first
                                                  .toUpperCase(),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 44,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    )
                                  : Center(
                                      child: Text(
                                        (user?.displayName?.trim() ?? 'S')
                                            .characters
                                            .first
                                            .toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 44,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                            child: Icon(
                              Icons.camera_alt_rounded,
                              size: 18,
                              color: Constants.primaryBlue,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user?.displayName?.trim() ?? 'Student',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Student Account',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableNameSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Constants.deepBlue.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Personal Information',
                style: TextStyle(
                  color: _textDark,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (!_isEditing)
                TextButton.icon(
                  onPressed: () => setState(() => _isEditing = true),
                  icon: const Icon(Icons.edit_rounded, size: 18),
                  label: const Text('Edit'),
                  style: TextButton.styleFrom(
                    foregroundColor: Constants.primaryBlue,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isEditing) ...[
            _buildEditField(
              controller: _nameController,
              label: 'Full Name',
              icon: Icons.person_outline_rounded,
            ),
            const SizedBox(height: 12),
            _buildEditField(
              controller: _phoneController,
              label: 'Phone Number',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            _buildEditField(
              controller: _bioController,
              label: 'Bio',
              icon: Icons.description_outlined,
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            _buildEditField(
              controller: _studentIdController,
              label: 'Student ID',
              icon: Icons.badge_outlined,
            ),
            const SizedBox(height: 12),
            _buildEditField(
              controller: _departmentController,
              label: 'Department/Course',
              icon: Icons.school_outlined,
            ),
            const SizedBox(height: 12),
            _buildEditField(
              controller: _yearController,
              label: 'Year/Semester',
              icon: Icons.calendar_month_outlined,
            ),
            const SizedBox(height: 12),
            _buildEditField(
              controller: _campusController,
              label: 'Campus',
              icon: Icons.location_on_outlined,
            ),
            const SizedBox(height: 12),
            _buildEditField(
              controller: _interestsController,
              label: 'Interests & Skills',
              icon: Icons.star_outline_rounded,
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        _isSaving ? null : () => setState(() => _isEditing = false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _textMuted,
                      side: const BorderSide(color: Color(0xFFE3E8F2)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Constants.primaryBlue,
                      disabledBackgroundColor:
                          Constants.primaryBlue.withValues(alpha: 0.6),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Save Changes'),
                  ),
                ),
              ],
            ),
          ] else ...[
            _buildViewField(
              label: 'Name',
              value: _nameController.text.isNotEmpty
                  ? _nameController.text
                  : 'Not set',
              icon: Icons.person_outline_rounded,
            ),
            const SizedBox(height: 12),
            _buildViewField(
              label: 'Phone',
              value: _phoneController.text.isNotEmpty
                  ? _phoneController.text
                  : 'Not set',
              icon: Icons.phone_outlined,
            ),
            const SizedBox(height: 12),
            _buildViewField(
              label: 'Bio',
              value: _bioController.text.isNotEmpty
                  ? _bioController.text
                  : 'Not set',
              icon: Icons.description_outlined,
            ),
            const SizedBox(height: 12),
            _buildViewField(
              label: 'Student ID',
              value: _studentIdController.text.isNotEmpty
                  ? _studentIdController.text
                  : 'Not set',
              icon: Icons.badge_outlined,
            ),
            const SizedBox(height: 12),
            _buildViewField(
              label: 'Department',
              value: _departmentController.text.isNotEmpty
                  ? _departmentController.text
                  : 'Not set',
              icon: Icons.school_outlined,
            ),
            const SizedBox(height: 12),
            _buildViewField(
              label: 'Year',
              value: _yearController.text.isNotEmpty
                  ? _yearController.text
                  : 'Not set',
              icon: Icons.calendar_month_outlined,
            ),
            const SizedBox(height: 12),
            _buildViewField(
              label: 'Campus',
              value: _campusController.text.isNotEmpty
                  ? _campusController.text
                  : 'Not set',
              icon: Icons.location_on_outlined,
            ),
            const SizedBox(height: 12),
            _buildViewField(
              label: 'Interests',
              value: _interestsController.text.isNotEmpty
                  ? _interestsController.text
                  : 'Not set',
              icon: Icons.star_outline_rounded,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEditField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _textDark,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: !_isSaving,
          maxLines: maxLines,
          keyboardType: keyboardType,
          cursorColor: Constants.primaryBlue,
          style: const TextStyle(color: _textDark, fontSize: 15),
          decoration: InputDecoration(
            hintStyle: const TextStyle(color: _textMuted),
            prefixIcon: Icon(icon, color: Constants.primaryBlue, size: 20),
            filled: true,
            fillColor: _fieldColor,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Constants.primaryBlue,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildViewField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Constants.primaryBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Constants.primaryBlue, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: _textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _textDark,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection(User? user) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Constants.deepBlue.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Account Details',
            style: TextStyle(
              color: _textDark,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoTile(
            icon: Icons.alternate_email_rounded,
            label: 'Email',
            value: user?.email ?? 'N/A',
          ),
          const SizedBox(height: 12),
          _buildInfoTile(
            icon: Icons.school_outlined,
            label: 'Account Type',
            value: 'Student',
          ),
          const SizedBox(height: 12),
          _buildInfoTile(
            icon: Icons.access_time_outlined,
            label: 'Member Since',
            value: _profileData != null
                ? _formatDate(_profileData!['createdAt'])
                : 'Today',
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    try {
      final date = (timestamp as Timestamp).toDate();
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'N/A';
    }
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Constants.primaryBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Constants.primaryBlue, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: _textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _textDark,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: _logout,
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Logout'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _errorColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
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
}