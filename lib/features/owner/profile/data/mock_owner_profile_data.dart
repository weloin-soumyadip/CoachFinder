/// Fixture data backing the owner Profile screen until the real backend lands.
library;

/// The signed-in coaching owner's personal name (header title).
const String mockOwnerName = 'Rajesh Kumar';

/// The owner's coaching business / centre name (header subtitle).
const String mockOwnerBusinessName = 'Apex Coaching Centre';

/// The owner's contact email shown beneath the business name.
const String mockOwnerEmail = 'rajesh@apexcoaching.com';

/// First letter of the owner's name, used as the avatar initial.
String get mockOwnerInitial =>
    mockOwnerName.isEmpty ? '?' : mockOwnerName[0].toUpperCase();

/// The owner's first name, used by greetings (e.g. the dashboard header).
String get mockOwnerFirstName =>
    mockOwnerName.isEmpty ? '' : mockOwnerName.split(' ').first;
