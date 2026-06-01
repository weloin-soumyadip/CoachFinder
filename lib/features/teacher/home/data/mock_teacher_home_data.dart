/// Models + fixtures backing the teacher home (activity control center) until
/// the backend lands. The headline stats come from the teacher profile fixture
/// and the recent-enquiries preview from the enquiries feature
/// (`mock_teacher_enquiry_data.dart`); this file supplies the day's sessions.
library;

/// How a session is delivered.
enum SessionMode {
  /// Conducted over video.
  online,

  /// Conducted in person.
  inPerson,
}

/// One teaching session on the teacher's schedule for the day.
class TeacherSession {
  const TeacherSession({
    required this.time,
    required this.subject,
    required this.group,
    required this.mode,
  });

  /// Display start time, e.g. "4:00 PM".
  final String time;

  /// Subject taught, e.g. "Physics".
  final String subject;

  /// Batch / level label, e.g. "Class 12 · JEE batch".
  final String group;

  /// Delivery mode (drives the trailing icon).
  final SessionMode mode;
}

/// Today's sessions for the signed-in teacher. Fixture-backed until the backend
/// lands; resets on restart.
const List<TeacherSession> mockTeacherSessions = <TeacherSession>[
  TeacherSession(
    time: '4:00 PM',
    subject: 'Physics',
    group: 'Class 12 · Board prep',
    mode: SessionMode.online,
  ),
  TeacherSession(
    time: '6:30 PM',
    subject: 'Mathematics',
    group: 'JEE batch',
    mode: SessionMode.online,
  ),
  TeacherSession(
    time: '8:00 PM',
    subject: 'Physics',
    group: 'Doubt-clearing · 1-on-1',
    mode: SessionMode.inPerson,
  ),
];
