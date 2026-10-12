import 'package:campusconnect/models/hackathon.dart';
import 'package:campusconnect/utils/constants.dart';
import 'package:campusconnect/views/hackathon_detail_view.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Read-only list of hackathons for students.
class StudentHackathonListView extends StatefulWidget {
  const StudentHackathonListView({super.key});
  static const routeName = "/StudentHackathonListView";
  @override
  State<StudentHackathonListView> createState() =>
      _StudentHackathonListViewState();
}

class _StudentHackathonListViewState extends State<StudentHackathonListView> {
  static const Color _background = Color(0xFFF4F7FC);
  static const Color _textDark = Color(0xFF16213E);
  static const Color _textMuted = Color(0xFF6B7A99);
  static const List<String> _months = [
    'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
    'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
  ];

  final FirebaseFirestore db = FirebaseFirestore.instance;

  List<Hackathon> _hackathons = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHackathons();
  }

  Future<void> _loadHackathons() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final snapshot = await db
          .collection("hackthons")
          .orderBy('startDate', descending: true)
          .get();
      final hackathons =
          snapshot.docs.map((doc) => Hackathon.fromFirestore(doc)).toList();
      if (!mounted) return;
      setState(() => _hackathons = hackathons);
    } catch (e, stackTrace) {
      debugPrint('Load hackathons error: $e');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      setState(() => _error = 'Could not load hackathons.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        title: const Text('Hackathons'),
        backgroundColor: Constants.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Constants.primaryBlue),
      );
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!,
                style: const TextStyle(color: _textMuted, fontSize: 15)),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _loadHackathons,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      color: Constants.primaryBlue,
      onRefresh: _loadHackathons,
      child: _hackathons.isEmpty
          // ListView so pull-to-refresh still works when empty.
          ? ListView(
              children: const [
                SizedBox(height: 200),
                Center(
                  child: Text('No hackathons yet. Check back soon!',
                      style: TextStyle(color: _textMuted, fontSize: 15)),
                ),
              ],
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _hackathons.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, i) => _hackathonCard(_hackathons[i]),
            ),
    );
  }

  Widget _hackathonCard(Hackathon hackathon) {
    final start = hackathon.startDate;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () =>
            Get.toNamed(HackathonDetailView.routeName, arguments: hackathon),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Date badge.
              Container(
                width: 58,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Constants.primaryBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    Text(
                      start == null ? '--' : start.day.toString().padLeft(2, '0'),
                      style: const TextStyle(
                        color: Constants.primaryBlue,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                    Text(
                      start == null ? '' : _months[start.month - 1],
                      style: const TextStyle(
                        color: Constants.primaryBlue,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HackathonStatusChip(status: hackathon.status),
                    const SizedBox(height: 6),
                    Text(
                      hackathon.title.isEmpty ? 'Untitled' : hackathon.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _textDark,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            color: _textMuted, size: 15),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            hackathon.venue,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: _textMuted, fontSize: 13),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.groups_outlined,
                            color: _textMuted, size: 15),
                        const SizedBox(width: 3),
                        Text(
                          'Up to ${hackathon.maxTeamSize}',
                          style:
                              const TextStyle(color: _textMuted, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded, color: _textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small coloured label for Upcoming / Ongoing / Completed.
class HackathonStatusChip extends StatelessWidget {
  const HackathonStatusChip({super.key, required this.status, this.onDark = false});

  final String status;

  /// Use white styling when shown on the blue gradient header.
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final Color color = switch (status) {
      'Upcoming' => Constants.primaryBlue,
      'Ongoing' => const Color(0xFF1FA463),
      _ => const Color(0xFF6B7A99),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: onDark
            ? Colors.white.withValues(alpha: 0.2)
            : color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: onDark ? Colors.white : color,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
