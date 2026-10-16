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
  bool loading = true;
  String? _error;
  DateTime? _selectedFilterDate;

  @override
  void initState() {
    super.initState();
    _loadHackathons();
  }

  Future<void> getHackthonsInRange(DateTime filterDate) async {
    setState(() {
      loading = true;
      _error = null;
    });
    try {
      final snapshot = await db
          .collection("hackthons")
          .where("startDate", isGreaterThanOrEqualTo: filterDate)
          .orderBy('startDate', descending: true)
          .get();
      final hackathons =
          snapshot.docs.map((doc) => Hackathon.fromFirestore(doc)).toList();
      setState(() => _hackathons = hackathons);
    } catch (e) {
      debugPrint('Load hackathons error: $e');
      setState(() => _error = 'Could not load hackathons.');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _loadHackathons() async {
    setState(() {
      loading = true;
      _error = null;
    });
    try {
      final snapshot = await db.collection("hackthons").orderBy('startDate', descending: true).get();
      //converts each doc ino hackthon object
      final hackathons =snapshot.docs.map((doc) => Hackathon.fromFirestore(doc)).toList();
      setState(() => _hackathons = hackathons);
    } catch (e, stackTrace) {
      debugPrint('Load hackathons error: $e');
      debugPrintStack(stackTrace: stackTrace);
      setState(() => _error = 'Could not load hackathons.');
    } finally {
      if (mounted) setState(() => loading = false);
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
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Center(
              child: Material(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  onTap: _pickFilterDate,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_today, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          _selectedFilterDate == null
                              ? 'Filter'
                              : _formatDate(_selectedFilterDate),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (_selectedFilterDate != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Center(
                child: Material(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    onTap: _clearFilter,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.close, color: Colors.white, size: 18),
                          const SizedBox(width: 6),
                          const Text(
                            'Clear',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (loading) {
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
              itemBuilder: (context, i) => hackathonCard(_hackathons[i]),
            ),
    );
  }

  Future<void> _pickFilterDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedFilterDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _selectedFilterDate = picked);
      await getHackthonsInRange(picked);
    }
  }

  void _clearFilter() {
    setState(() => _selectedFilterDate = null);
    _loadHackathons();
  }

  Widget hackathonCard(Hackathon hackathon) {
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
