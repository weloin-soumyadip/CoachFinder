/// Models + fixtures backing the teacher schedule (week strip + a day's
/// sessions) until the backend lands.
library;

/// How a session is delivered (drives the row's trailing icon).
enum SessionMode {
  /// Conducted over video.
  online,

  /// Conducted in person.
  inPerson,
}

/// One teaching session on a given day, with a start/end time range.
class ScheduleSession {
  const ScheduleSession({
    required this.startTime,
    required this.endTime,
    required this.subject,
    required this.group,
    required this.mode,
  });

  /// Display start time, e.g. "4:00 PM".
  final String startTime;

  /// Display end time, e.g. "5:00 PM".
  final String endTime;

  /// Subject taught, e.g. "Physics".
  final String subject;

  /// Batch / level label, e.g. "Class 12 · Board prep".
  final String group;

  /// Delivery mode (drives the trailing icon).
  final SessionMode mode;
}

/// A single day in the week strip: its labels, whether it is today, and the
/// sessions scheduled on it.
class ScheduleDay {
  const ScheduleDay({
    required this.weekday,
    required this.dayNum,
    required this.fullLabel,
    required this.isToday,
    required this.sessions,
  });

  /// Short weekday label for the strip, e.g. "Wed".
  final String weekday;

  /// Day-of-month number for the strip, e.g. "30".
  final String dayNum;

  /// Full header label for the selected day, e.g. "Wednesday, 30 May".
  final String fullLabel;

  /// Whether this is the current day (highlighted in the strip).
  final bool isToday;

  /// Sessions on this day, ordered by start time.
  final List<ScheduleSession> sessions;
}

/// The signed-in teacher's week. Fixture-backed until the backend lands; resets
/// on restart. "Today" is the third entry so the strip opens mid-week.
const List<ScheduleDay> mockScheduleWeek = <ScheduleDay>[
  ScheduleDay(
    weekday: 'Mon',
    dayNum: '28',
    fullLabel: 'Monday, 28 May',
    isToday: false,
    sessions: <ScheduleSession>[],
  ),
  ScheduleDay(
    weekday: 'Tue',
    dayNum: '29',
    fullLabel: 'Tuesday, 29 May',
    isToday: false,
    sessions: <ScheduleSession>[
      ScheduleSession(
        startTime: '5:00 PM',
        endTime: '6:30 PM',
        subject: 'Mathematics',
        group: 'JEE batch',
        mode: SessionMode.online,
      ),
    ],
  ),
  ScheduleDay(
    weekday: 'Wed',
    dayNum: '30',
    fullLabel: 'Wednesday, 30 May',
    isToday: true,
    sessions: <ScheduleSession>[
      ScheduleSession(
        startTime: '4:00 PM',
        endTime: '5:00 PM',
        subject: 'Physics',
        group: 'Class 12 · Board prep',
        mode: SessionMode.online,
      ),
      ScheduleSession(
        startTime: '6:30 PM',
        endTime: '8:00 PM',
        subject: 'Mathematics',
        group: 'JEE batch',
        mode: SessionMode.online,
      ),
      ScheduleSession(
        startTime: '8:00 PM',
        endTime: '8:45 PM',
        subject: 'Physics',
        group: 'Doubt-clearing · 1-on-1',
        mode: SessionMode.inPerson,
      ),
    ],
  ),
  ScheduleDay(
    weekday: 'Thu',
    dayNum: '31',
    fullLabel: 'Thursday, 31 May',
    isToday: false,
    sessions: <ScheduleSession>[
      ScheduleSession(
        startTime: '5:00 PM',
        endTime: '6:00 PM',
        subject: 'Physics',
        group: 'Class 11 · Mechanics',
        mode: SessionMode.online,
      ),
      ScheduleSession(
        startTime: '7:00 PM',
        endTime: '8:30 PM',
        subject: 'Mathematics',
        group: 'Class 12 · Calculus',
        mode: SessionMode.online,
      ),
    ],
  ),
  ScheduleDay(
    weekday: 'Fri',
    dayNum: '1',
    fullLabel: 'Friday, 1 June',
    isToday: false,
    sessions: <ScheduleSession>[
      ScheduleSession(
        startTime: '6:00 PM',
        endTime: '7:30 PM',
        subject: 'Physics',
        group: 'JEE batch · Optics',
        mode: SessionMode.online,
      ),
    ],
  ),
  ScheduleDay(
    weekday: 'Sat',
    dayNum: '2',
    fullLabel: 'Saturday, 2 June',
    isToday: false,
    sessions: <ScheduleSession>[
      ScheduleSession(
        startTime: '10:00 AM',
        endTime: '12:00 PM',
        subject: 'Physics',
        group: 'Weekend batch · Full revision',
        mode: SessionMode.inPerson,
      ),
      ScheduleSession(
        startTime: '1:00 PM',
        endTime: '2:30 PM',
        subject: 'Mathematics',
        group: 'Weekend batch · Problem solving',
        mode: SessionMode.inPerson,
      ),
    ],
  ),
  ScheduleDay(
    weekday: 'Sun',
    dayNum: '3',
    fullLabel: 'Sunday, 3 June',
    isToday: false,
    sessions: <ScheduleSession>[],
  ),
];
