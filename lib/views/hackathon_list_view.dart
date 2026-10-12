import 'package:campusconnect/models/hackathon.dart';
import 'package:campusconnect/utils/constants.dart';
import 'package:campusconnect/views/hackathon_form_view.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum HackathonListMode { edit, delete }

/// Lists all hackathons. In edit mode tapping one opens the form;
/// in delete mode each one has a delete button.
class HackathonListView extends StatefulWidget {
  const HackathonListView({super.key});
  static const routeName = "/HackathonListView";
  @override
  State<HackathonListView> createState() => _HackathonListViewState();
}

class _HackathonListViewState extends State<HackathonListView> {
  static const Color _background = Color(0xFFF4F7FC);
  static const Color _textDark = Color(0xFF16213E);
  static const Color _textMuted = Color(0xFF6B7A99);
  static const Color _errorColor = Color(0xFFE5484D);

  final HackathonListMode _mode = Get.arguments ?? HackathonListMode.edit;
  bool get _isEdit => _mode == HackathonListMode.edit;

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
      final snapshot = await db.collection("hackthons").orderBy('startDate', descending: true).get();
      //converts each doc ino hackthon object
      final hackathons =snapshot.docs.map((doc) => Hackathon.fromFirestore(doc)).toList();
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
        title: Text(_isEdit ? 'Edit Hackathon' : 'Delete Hackathon'),
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
                  child: Text('No hackathons yet.',
                      style: TextStyle(color: _textMuted, fontSize: 15)),
                ),
              ],
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: _hackathons.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, i) => _hackathonCard(_hackathons[i]),
            ),
    );
  }

  Widget _hackathonCard(Hackathon hackathon) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _isEdit
            ? () async {
                await Get.toNamed(HackathonFormView.routeName,
                    arguments: hackathon);
                // Reload in case the hackathon was changed.
                _loadHackathons();
              }
            : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hackathon.title.isEmpty ? 'Untitled' : hackathon.title,
                      style: const TextStyle(
                        color: _textDark,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${hackathon.venue}  •  ${_formatDate(hackathon.startDate)} – ${_formatDate(hackathon.endDate)}',
                      style: const TextStyle(color: _textMuted, fontSize: 13),
                    ),
                  ],
                ),
              ),
              _isEdit
                  ? const Icon(Icons.edit_outlined, color: Constants.primaryBlue)
                  : IconButton(
                      icon: const Icon(Icons.delete_outline_rounded,
                          color: _errorColor),
                      onPressed: () => _confirmDelete(hackathon),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(Hackathon hackathon) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete hackathon?'),
        content: Text('"${hackathon.title}" will be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _deleteHackathon(hackathon);
            },
            child: const Text('Delete', style: TextStyle(color: _errorColor)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteHackathon(Hackathon hackathon) async {
    try {
      await db.collection("hackthons").doc(hackathon.id).delete();
      if (!mounted) return;
      // Remove it from the screen without reloading everything.
      setState(() => _hackathons.removeWhere((h) => h.id == hackathon.id));
      Get.showSnackbar(const GetSnackBar(
        message: 'Hackathon deleted',
        backgroundColor: Color(0xFF1FA463),
        duration: Duration(seconds: 2),
      ));
    } catch (e) {
      debugPrint('Delete hackathon error: $e');
      Get.showSnackbar(const GetSnackBar(
        message: 'Could not delete hackathon. Please try again.',
        backgroundColor: _errorColor,
        duration: Duration(seconds: 2),
      ));
    }
  }

  static String _formatDate(DateTime? d) => d == null
      ? '-'
      : '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
