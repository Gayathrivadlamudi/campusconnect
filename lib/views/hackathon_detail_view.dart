import 'package:campusconnect/models/hackathon.dart';
import 'package:campusconnect/utils/constants.dart';
import 'package:campusconnect/views/student_hackathon_list_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Full details of one hackathon, passed as the route argument.
class HackathonDetailView extends StatelessWidget {
  const HackathonDetailView({super.key});
  static const routeName = "/HackathonDetailView";

  static const Color _background = Color(0xFFF4F7FC);
  static const Color _textDark = Color(0xFF16213E);
  static const Color _textMuted = Color(0xFF6B7A99);
  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  static const List<String> _weekdays = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
  ];

  @override
  Widget build(BuildContext context) {
    final Hackathon hackathon = Get.arguments;
    final days = hackathon.durationDays;

    return Scaffold(
      backgroundColor: _background,
      body: Column(
        children: [
          _buildHeader(hackathon),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
              children: [
                _card(
                  child: Column(
                    children: [
                      _infoRow(
                        icon: Icons.play_circle_outline_rounded,
                        label: 'Starts',
                        value: _formatDate(hackathon.startDate),
                      ),
                      _divider(),
                      _infoRow(
                        icon: Icons.flag_outlined,
                        label: 'Ends',
                        value: _formatDate(hackathon.endDate),
                      ),
                      if (days != null) ...[
                        _divider(),
                        _infoRow(
                          icon: Icons.schedule_rounded,
                          label: 'Duration',
                          value: days == 1 ? '1 day' : '$days days',
                        ),
                      ],
                    ],
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: _statTile(
                        icon: Icons.groups_outlined,
                        label: 'Team size',
                        value: hackathon.maxTeamSize == 1
                            ? 'Solo'
                            : 'Up to ${hackathon.maxTeamSize}',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _statTile(
                        icon: Icons.card_giftcard_rounded,
                        label: 'Prize',
                        value: hackathon.prize.isEmpty ? 'TBA' : hackathon.prize,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'About this hackathon',
                        style: TextStyle(
                          color: _textDark,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        hackathon.description.isEmpty
                            ? 'No description provided.'
                            : hackathon.description,
                        style: const TextStyle(
                          color: _textMuted,
                          fontSize: 14.5,
                          height: 1.55,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildRegisterBar(hackathon),
    );
  }

  void _register(Hackathon hackathon) {
    // TODO: register the current student for this hackathon.
    debugPrint('Register tapped for hackathon ${hackathon.id}');
  }

  Widget _buildRegisterBar(Hackathon hackathon) {
    final closed = hackathon.status == 'Completed';
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: closed
                ? null
                : const LinearGradient(
                    colors: [Constants.deepBlue, Constants.primaryBlue],
                  ),
            color: closed ? const Color(0xFFE3E8F2) : null,
            boxShadow: closed
                ? null
                : [
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
              onPressed: closed ? null : () => _register(hackathon),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                disabledBackgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
                disabledForegroundColor: _textMuted,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    closed ? Icons.lock_outline_rounded : Icons.how_to_reg_rounded,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    closed ? 'Registration Closed' : 'Register Now',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Hackathon hackathon) {
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
              padding: const EdgeInsets.fromLTRB(8, 4, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 20),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 12, top: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        HackathonStatusChip(
                            status: hackathon.status, onDark: true),
                        const SizedBox(height: 10),
                        Text(
                          hackathon.title.isEmpty
                              ? 'Untitled'
                              : hackathon.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined,
                                color: Colors.white.withValues(alpha: 0.9),
                                size: 18),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                hackathon.venue,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 14.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Constants.deepBlue.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: Constants.primaryBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Constants.primaryBlue, size: 20),
        ),
        const SizedBox(width: 14),
        Text(label, style: const TextStyle(color: _textMuted, fontSize: 14)),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            color: _textDark,
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _divider() => const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Divider(height: 1, color: Color(0xFFE3E8F2)),
      );

  Widget _statTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Constants.deepBlue.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Constants.primaryBlue, size: 24),
          const SizedBox(height: 10),
          Text(label, style: const TextStyle(color: _textMuted, fontSize: 12.5)),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _textDark,
              fontSize: 15.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime? d) => d == null
      ? '-'
      : '${_weekdays[d.weekday - 1]}, ${d.day} ${_months[d.month - 1]} ${d.year}';
}
