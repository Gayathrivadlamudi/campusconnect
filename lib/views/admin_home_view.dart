import 'package:campusconnect/utils/constants.dart';
import 'package:campusconnect/views/hackathon_form_view.dart';
import 'package:campusconnect/views/hackathon_list_view.dart';
import 'package:campusconnect/views/login_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AdminHomeView extends StatelessWidget {
  const AdminHomeView({super.key});
  static const routeName = "/AdminHomeView";

  static const Color _background = Color(0xFFF4F7FC);
  static const Color _textDark = Color(0xFF16213E);
  static const Color _textMuted = Color(0xFF6B7A99);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Constants.primaryBlue,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Get.offAllNamed(LoginView.routeName);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Welcome, Admin',
              style: TextStyle(
                color: _textDark,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Manage campus hackathons.',
              style: TextStyle(color: _textMuted, fontSize: 14),
            ),
            const SizedBox(height: 20),
            _moduleCard(
              icon: Icons.add_circle_outline_rounded,
              color: const Color(0xFF1FA463),
              title: 'Add Hackathon',
              subtitle: 'Create a new hackathon event',
              onTap: () => Get.toNamed(HackathonFormView.routeName),
            ),
            _moduleCard(
              icon: Icons.edit_outlined,
              color: Constants.primaryBlue,
              title: 'Edit Hackathon',
              subtitle: 'Update details of an existing hackathon',
              onTap: () => Get.toNamed(
                HackathonListView.routeName,
                arguments: HackathonListMode.edit,
              ),
            ),
            _moduleCard(
              icon: Icons.delete_outline_rounded,
              color: const Color(0xFFE5484D),
              title: 'Delete Hackathon',
              subtitle: 'Remove a hackathon permanently',
              onTap: () => Get.toNamed(
                HackathonListView.routeName,
                arguments: HackathonListMode.delete,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _moduleCard({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: _textDark,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(color: _textMuted, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: _textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
