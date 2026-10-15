import 'package:campusconnect/models/hackathon.dart';
import 'package:campusconnect/utils/constants.dart';
import 'package:campusconnect/views/hackathon_list_view.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Add a new hackathon, or edit one when a [Hackathon] is passed
/// as the route argument.
class HackathonFormView extends StatefulWidget {
  const HackathonFormView({super.key});
  static const routeName = "/HackathonFormView";
  @override
  State<HackathonFormView> createState() => _HackathonFormViewState();
}

class _HackathonFormViewState extends State<HackathonFormView> {
  static const Color _background = Color(0xFFF4F7FC);
  static const Color _fieldColor = Color(0xFFF1F4FA);
  static const Color _borderColor = Color(0xFFE3E8F2);
  static const Color _textDark = Color(0xFF16213E);
  static const Color _textMuted = Color(0xFF6B7A99);
  static const Color _errorColor = Color(0xFFE5484D);

  static const int _minTeamSize = 1;
  static const int _maxTeamSize = 10;
  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  static const List<String> _weekdays = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
  ];

  final Hackathon? _existing = Get.arguments;
  bool get _isEdit => _existing != null;
  final FirebaseFirestore db=FirebaseFirestore.instance;

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _venueController = TextEditingController();
  final _prizeController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  int _teamSize = 4;
  bool _saving = false;
  bool _showDateError = false;

  @override
  void initState() {
    super.initState();
    final hackathon = _existing;
    if (hackathon != null) {
      _titleController.text = hackathon.title;
      _descriptionController.text = hackathon.description;
      _venueController.text = hackathon.venue;
      _prizeController.text = hackathon.prize;
      _teamSize = hackathon.maxTeamSize;
      _startDate = hackathon.startDate;
      _endDate = hackathon.endDate;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _venueController.dispose();
    _prizeController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isStart) async {
    FocusScope.of(context).unfocus();
    final initial =
        (isStart ? _startDate : _endDate) ?? _startDate ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: isStart ? DateTime(2020) : (_startDate ?? DateTime(2020)),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context)
              .colorScheme
              .copyWith(primary: Constants.primaryBlue),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(picked)) _endDate = null;
      } else {
        _endDate = picked;
      }
      _showDateError = false;
    });
  }

save() async {
    FocusScope.of(context).unfocus();
    final formValid = _formKey.currentState!.validate();
    final datesValid = _startDate != null && _endDate != null;
    setState(() => _showDateError = !datesValid);
    if (!formValid || !datesValid) {
      _showSnack('Please fill in all required fields.', _errorColor);
      return;
    }
    final data = {
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'venue': _venueController.text.trim(),
      'prize': _prizeController.text.trim(),
      'maxTeamSize': _teamSize,
      'startDate': _startDate,
      'endDate': _endDate,
    };
    setState(() => _saving = true);
    try {
      final hackthonDoc=await db.collection("hackthons").add(data);
      debugPrint('Added hackathon: ${hackthonDoc.id}');
      // Replace the form with the list, so back goes to the admin home.
      _showSnack('Hackathon added.', const Color(0xFF1FA463));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  updateChanges()async{
    FocusScope.of(context).unfocus();
    final formValid = _formKey.currentState!.validate();
    final datesValid = _startDate != null && _endDate != null;
    setState(() => _showDateError = !datesValid);
    if (!formValid || !datesValid) {
      _showSnack('Please fill in all required fields.', _errorColor);
      return;
    }
    // Only keep the fields that differ from the original hackathon.
    final old = _existing!;
    final Map<String, dynamic> changes = {};
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final venue = _venueController.text.trim();
    final prize = _prizeController.text.trim();
    if (title != old.title) changes['title'] = title;
    if (description != old.description) changes['description'] = description;
    if (venue != old.venue) changes['venue'] = venue;
    if (prize != old.prize) changes['prize'] = prize;
    if (_teamSize != old.maxTeamSize) changes['maxTeamSize'] = _teamSize;
    if (_startDate != old.startDate) changes['startDate'] = _startDate;
    if (_endDate != old.endDate) changes['endDate'] = _endDate;

    if (changes.isEmpty) {
      _showSnack('No changes to save.', _textMuted);
      return;
    }
    setState(() => _saving = true);
    try {
      await db.collection("hackthons").doc(old.id).update(changes);
      debugPrint('Updated fields: ${changes.keys.toList()}');
      // Return to the list it was opened from; the list reloads itself.
      Get.back();
      _showSnack('Hackathon updated.', const Color(0xFF1FA463));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }


  void _showSnack(String message, Color color) {
    Get.showSnackbar(GetSnackBar(
      message: message,
      backgroundColor: color,
      duration: const Duration(seconds: 2),
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
    ));
  }

  int? get _durationDays => (_startDate == null || _endDate == null)
      ? null
      : _endDate!.difference(_startDate!).inDays + 1;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _buildScaffold(),
        // Full-screen loader while saving; blocks taps on the form.
        if (_saving)
          Positioned.fill(
            child: ColoredBox(
              color: Colors.black.withValues(alpha: 0.35),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const CircularProgressIndicator(
                    color: Constants.primaryBlue,
                    strokeWidth: 3,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildScaffold() {
    return Scaffold(
      backgroundColor: _background,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                children: [
                  _section(
                    icon: Icons.info_outline_rounded,
                    title: 'Basic details',
                    subtitle: 'What is this hackathon about?',
                    children: [
                      _label('Hackathon title', required: true),
                      _buildField(
                        controller: _titleController,
                        hint: 'e.g. CodeSprint 2026',
                        icon: Icons.emoji_events_outlined,
                        textCapitalization: TextCapitalization.words,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Please enter a title.'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      _label('Description', required: true),
                      _buildField(
                        controller: _descriptionController,
                        hint: 'Theme, rules, who can participate...',
                        maxLines: 5,
                        maxLength: 500,
                        textCapitalization: TextCapitalization.sentences,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Please enter a description.'
                            : null,
                      ),
                      const SizedBox(height: 4),
                      _label('Venue', required: true),
                      _buildField(
                        controller: _venueController,
                        hint: 'e.g. Main Auditorium, Block A',
                        icon: Icons.location_on_outlined,
                        textCapitalization: TextCapitalization.words,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Please enter the venue.'
                            : null,
                      ),
                    ],
                  ),
                  _section(
                    icon: Icons.event_outlined,
                    title: 'Schedule',
                    subtitle: 'When does it start and end?',
                    children: [
                      Row(
                        children: [
                          Expanded(child: _dateCard('Starts', _startDate, true)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              color: _textMuted.withValues(alpha: 0.6),
                              size: 20,
                            ),
                          ),
                          Expanded(child: _dateCard('Ends', _endDate, false)),
                        ],
                      ),
                      if (_durationDays != null) ...[
                        const SizedBox(height: 14),
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color:
                                  Constants.primaryBlue.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.schedule_rounded,
                                    color: Constants.primaryBlue, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  _durationDays == 1
                                      ? '1 day event'
                                      : '$_durationDays days event',
                                  style: const TextStyle(
                                    color: Constants.primaryBlue,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      if (_showDateError) ...[
                        const SizedBox(height: 10),
                        const Text(
                          'Please select both start and end dates.',
                          style: TextStyle(color: _errorColor, fontSize: 12.5),
                        ),
                      ],
                    ],
                  ),
                  _section(
                    icon: Icons.workspace_premium_outlined,
                    title: 'Teams & prizes',
                    subtitle: 'Participation details',
                    children: [
                      _label('Max team size'),
                      _teamSizeStepper(),
                      const SizedBox(height: 16),
                      _label('Prize'),
                      _buildField(
                        controller: _prizeController,
                        hint: 'e.g. ₹50,000 + internships',
                        icon: Icons.card_giftcard_rounded,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildHeader() {
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
              padding: const EdgeInsets.fromLTRB(8, 4, 20, 26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            _isEdit
                                ? Icons.edit_note_rounded
                                : Icons.rocket_launch_outlined,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isEdit ? 'Edit Hackathon' : 'New Hackathon',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _isEdit
                                    ? 'Update the event details below'
                                    : 'Fill in the details to publish an event',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: 14,
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

  Widget _section({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
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
                      title,
                      style: const TextStyle(
                        color: _textDark,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(color: _textMuted, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, color: _borderColor),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _label(String text, {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 2),
      child: Text.rich(
        TextSpan(
          text: text,
          children: [
            if (required)
              const TextSpan(
                text: ' *',
                style: TextStyle(color: _errorColor),
              ),
          ],
        ),
        style: const TextStyle(
          color: _textDark,
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _dateCard(String label, DateTime? date, bool isStart) {
    final hasError = _showDateError && date == null;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _pickDate(isStart),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: date == null
              ? _fieldColor
              : Constants.primaryBlue.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasError
                ? _errorColor
                : date == null
                    ? Colors.transparent
                    : Constants.primaryBlue.withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                color: _textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            if (date == null)
              const Row(
                children: [
                  Icon(Icons.calendar_today_outlined,
                      color: Constants.primaryBlue, size: 18),
                  SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Select date',
                      style: TextStyle(
                        color: Constants.primaryBlue,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    date.day.toString().padLeft(2, '0'),
                    style: const TextStyle(
                      color: _textDark,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_months[date.month - 1]} ${date.year}',
                          style: const TextStyle(
                            color: _textDark,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _weekdays[date.weekday - 1],
                          style: const TextStyle(
                              color: _textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _teamSizeStepper() {
    Widget stepButton(IconData icon, VoidCallback? onTap) {
      return Material(
        color: onTap == null
            ? _fieldColor
            : Constants.primaryBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(
              icon,
              color: onTap == null ? _textMuted : Constants.primaryBlue,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: _fieldColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const SizedBox(width: 10),
          const Icon(Icons.groups_outlined,
              color: Constants.primaryBlue, size: 21),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _teamSize == 1 ? 'Solo (1 member)' : '$_teamSize members',
              style: const TextStyle(
                color: _textDark,
                fontSize: 15.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          stepButton(
            Icons.remove_rounded,
            _teamSize > _minTeamSize
                ? () => setState(() => _teamSize--)
                : null,
          ),
          const SizedBox(width: 8),
          stepButton(
            Icons.add_rounded,
            _teamSize < _maxTeamSize
                ? () => setState(() => _teamSize++)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
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
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 54,
                child: OutlinedButton(
                  onPressed: _saving ? null : () => Get.back(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _textDark,
                    side: const BorderSide(color: _borderColor, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _saving ? 0.7 : 1,
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
                      onPressed: _saving
                          ? null
                          : (_isEdit ? updateChanges : save),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        disabledBackgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        disabledForegroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _isEdit
                                      ? Icons.check_rounded
                                      : Icons.publish_rounded,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _isEdit ? 'Save Changes' : 'Publish',
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    IconData? icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    int maxLines = 1,
    int? maxLength,
  }) {
    OutlineInputBorder border(Color color) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: color, width: 1.5),
        );

    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      maxLines: maxLines,
      maxLength: maxLength,
      cursorColor: Constants.primaryBlue,
      style: const TextStyle(color: _textDark, fontSize: 15.5),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: _textMuted.withValues(alpha: 0.8)),
        prefixIcon: icon == null
            ? null
            : Icon(icon, color: Constants.primaryBlue, size: 21),
        filled: true,
        fillColor: _fieldColor,
        counterStyle: const TextStyle(color: _textMuted, fontSize: 11.5),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
