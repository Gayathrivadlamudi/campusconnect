import 'package:cloud_firestore/cloud_firestore.dart';

class Hackathon {
  final String id;
  final String title;
  final String description;
  final String venue;
  final String prize;
  final int maxTeamSize;
  final DateTime? startDate;
  final DateTime? endDate;

  Hackathon({
    required this.id,
    required this.title,
    required this.description,
    required this.venue,
    required this.prize,
    required this.maxTeamSize,
    this.startDate,
    this.endDate,
  });

  /// 'Upcoming', 'Ongoing' or 'Completed' based on today's date.
  String get status {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (startDate != null && today.isBefore(startDate!)) return 'Upcoming';
    if (endDate != null && today.isAfter(endDate!)) return 'Completed';
    return 'Ongoing';
  }

  /// Number of days the event runs, counting both start and end day.
  int? get durationDays => (startDate == null || endDate == null)
      ? null
      : endDate!.difference(startDate!).inDays + 1;

  /// Builds a Hackathon from a Firestore document.
  factory Hackathon.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Hackathon(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      venue: data['venue'] ?? '',
      prize: data['prize'] ?? '',
      maxTeamSize: data['maxTeamSize'] ?? 4,
      startDate: (data['startDate'] as Timestamp?)?.toDate(),
      endDate: (data['endDate'] as Timestamp?)?.toDate(),
    );
  }
}
