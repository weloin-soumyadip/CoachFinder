/// All user-facing strings (button labels, screen titles, error messages).
library;

/// User-facing copy. Phase 1 only includes strings used by `main.dart` and the
/// onboarding screen; more get added as features are built.
abstract final class AppStrings {
  AppStrings._();

  static const String appName = 'CoachFinder';

  // Splash
  static const String splashTagline = 'Your growth journey starts here.';

  // Onboarding role selector
  static const String onboardingTitle = 'How will you use CoachFinder?';
  static const String onboardingSubtitle =
      'Select the path that best describes your goals so we can customize your experience.';
  static const String roleStudentTitle = 'I am a student';
  static const String roleStudentBlurb =
      'Discover expert mentors, book personalized sessions, and accelerate your learning journey with the right coach.';
  static const String roleOwnerTitle = 'I am a Coaching Owner';
  static const String roleOwnerBlurb =
      'Manage your roster, streamline scheduling, and grow your coaching business with powerful management tools.';
  static const String roleTeacherTitle = 'I am a teacher';
  static const String roleTeacherBlurb =
      'Share your expertise on your own terms - tutor independently or join an organization, set your availability, and connect with the students who need you.';
  static const String onboardingContinue = 'Continue';

  // Auth - shared
  static const String fieldEmail = 'Email Address';
  static const String hintEmail = 'name@example.com';
  static const String fieldPassword = 'Password';
  static const String google = 'Google';
  static const String apple = 'Apple';

  // Auth - login screen
  static const String loginTitle = 'Welcome back';
  static const String loginSubtitle =
      'Sign in to continue your journey of growth.';
  static const String forgotPassword = 'Forgot Password?';
  static const String logInButton = 'Log In';
  static const String orContinueWith = 'or continue with';
  static const String dontHaveAccount = "Don't have an account?";
  static const String signUp = 'Sign Up';

  // Auth - register screen
  static const String registerTitle = 'Create Account';
  static const String registerSubtitle =
      'Start your journey with professional guidance today.';
  static const String orEmail = 'OR EMAIL';
  static const String fieldFullName = 'Full Name';
  static const String hintFullName = 'John Doe';
  static const String fieldConfirmPassword = 'Confirm Password';
  static const String termsPrefix = 'I agree to the ';
  static const String termsOfService = 'Terms of Service';
  static const String termsAnd = ' and ';
  static const String privacyPolicy = 'Privacy Policy';
  static const String createAccountButton = 'CREATE ACCOUNT';
  static const String alreadyHaveAccount = 'Already have an account?';
  static const String signIn = 'Sign In';

  // Auth - sign-up extra fields
  static const String fieldPhone = 'Phone Number';
  static const String hintPhone = '9876543210';

  // Auth - shared (redesign)
  static const String authOr = 'Or';
  static const String socialGoogle = 'Google';
  static const String socialFacebook = 'Facebook';

  // Auth - forgot password screen
  static const String forgotTitle = 'Forgot Password';
  static const String forgotSubtitle = 'Get your code';
  static const String forgotDescription =
      'Please enter the email address associated with your account.';
  static const String recoverPasswordButton = 'Recover Password';
  static const String forgotSuccess =
      'If that email is registered, a recovery link is on its way.';
  static const String forgotRememberPrefix = 'Remember your password?';

  // Auth - form validation
  static const String validatorRequired = 'This field is required.';
  static const String validatorEmail = 'Enter a valid email address.';
  static const String validatorPasswordShort =
      'Password must be at least 6 characters.';
  static const String validatorPasswordMatch = 'Passwords do not match.';
  static const String validatorPhone = 'Enter a valid phone number.';

  // Student home screen
  static const String homeGreetingPrefix = 'Hello, ';
  static const String homeGreetingSuffix = '! 👋';
  static const String homeSubtitle = 'Your growth journey continues today.';
  static const String homeNextSessionLabel = 'NEXT SESSION';
  static const String homeJoinSessionRoom = 'Join Session Room';
  static const String homeTrendingTopics = 'Trending Topics';
  static const String homeSeeAll = 'See all';
  static const String homeRecommendedForYou = 'Recommended For You';
  static const String homePersonalizedPath = 'Personalized Path';
  static const String homeCurrentFocus = 'Current Focus';
  static const String homeTrackProgress = 'Track Progress';
  static const String homeViewInsights = 'View Insights';
  static const String homePerHourSuffix = '/hr';
  static const String homeTopCenters = 'Top Centers';
  static const String homeUpcomingWebinars = 'Upcoming Webinars';
  static const String homeWebinarJoin = 'Join';
  static const String homeRetry = 'Retry';
  static const String homeNoData = 'No data found';

  // Student search screen
  static const String searchHint = 'Search teachers, centers & webinars...';
  static const String searchSegmentAll = 'All';
  static const String searchSegmentTeachers = 'Teachers';
  static const String searchSegmentInstitutes = 'Institutes';
  static const String searchSegmentCenters = 'Centers';
  static const String searchSegmentWebinars = 'Webinars';
  static const String searchBrowseByCategory = 'Browse by category';
  static const String searchRecentSearches = 'Recent searches';
  static const String searchFilters = 'Filters';
  static const String searchClearFilters = 'Clear';
  static const String searchFoundPrefix = 'Found';
  static const String searchResultsWord = 'results';
  static const String searchTeachersWord = 'teachers';
  static const String searchInstitutesWord = 'institutes';
  static const String searchCentersWord = 'centers';
  static const String searchWebinarsWord = 'webinars';
  static const String searchPerSessionSuffix = '/session';
  static const String searchCoursesSuffix = 'courses';
  static const String searchCurrencyPrefix = '₹';
  static const String searchFeesRangeSeparator = '–';
  static const String searchExperienceSuffix = ' yrs exp';
  static const String searchVerified = 'Verified';
  static const String searchWebinarJoin = 'Join';
  static const String searchWebinarMinutesSuffix = ' min';
  static const String searchRetry = 'Retry';
  static const String searchLoadError = 'Could not load results.';
  static const String searchNoResultsTitle = 'No matches found';
  static const String searchNoResultsSubtitle =
      'Try a different search term or category.';

  // Student search filters screen
  static const String filterTitle = 'Filters';
  static const String filterSubjectLabel = 'Subject';
  static const String filterSubjectHint = 'e.g. Mathematics';
  static const String filterCityLabel = 'City';
  static const String filterCityHint = 'e.g. Bengaluru';
  static const String filterBoardLabel = 'Board';
  static const String filterRatingLabel = 'Minimum rating';
  static const String filterFeesLabel = 'Fees range';
  static const String filterMinFeesHint = 'Min';
  static const String filterMaxFeesHint = 'Max';
  static const String filterAny = 'Any';
  static const String filterRatingSuffix = '+';
  static const String filterApply = 'Apply filters';
  static const String filterReset = 'Reset';

  // Student saved screen
  static const String savedTitle = 'Saved';
  static const String savedSearchHint = 'Search saved tutors & coachings...';
  static const String savedFilterAll = 'All';
  static const String savedFilterCoachings = 'Coachings';
  static const String savedFilterTutors = 'Tutors';
  static const String savedFilterWebinars = 'Webinars';
  static const String savedCountWord = 'saved';
  static const String savedRemoveTooltip = 'Remove from saved';
  static const String savedSaveTooltip = 'Save';
  static const String savedRetry = 'Retry';
  static const String savedLoadError = 'Could not load your saved items.';
  static const String savedEmptyTitle = 'Nothing saved yet';
  static const String savedEmptySubtitle =
      'Bookmark tutors, coachings, and webinars to find them here.';

  // Student profile screen
  static const String profileTitle = 'Profile';
  static const String profileEditButton = 'Edit Profile';
  static const String profileAppearance = 'Appearance';
  static const String profileThemeSystem = 'System';
  static const String profileThemeLight = 'Light';
  static const String profileThemeDark = 'Dark';
  static const String profileSettings = 'Settings';
  static const String profileNotifications = 'Notifications';
  static const String profilePaymentMethods = 'Payment Methods';
  static const String profileHelpSupport = 'Help & Support';
  static const String profileAbout = 'About';
  static const String profileSignOut = 'Sign Out';
  static const String profileSignOutConfirmTitle = 'Sign out?';
  static const String profileSignOutConfirmBody =
      "You'll need to sign in again to access your account.";
  static const String profileSignOutCancel = 'Cancel';

  // Student edit-profile form
  static const String studentEditTitle = 'Edit Profile';
  static const String studentSectionPersonal = 'Personal Details';
  static const String studentSectionAcademic = 'Academic';
  static const String studentFieldName = 'Name';
  static const String studentFieldEmail = 'Email';
  static const String studentFieldPhone = 'Phone';
  static const String studentFieldCity = 'City';
  static const String studentFieldDob = 'Date of Birth';
  static const String studentFieldGender = 'Gender';
  static const String studentFieldClass = 'Class';
  static const String studentFieldBoard = 'Board';
  static const String studentDobSelect = 'Select date';
  static const String studentSelectHint = 'Select';
  static const String studentClassPrefix = 'Class ';
  static const String studentEmailReadonlyHint = "Email can't be changed.";
  static const String studentSave = 'Save Changes';
  static const String studentSavedSnack = 'Profile saved.';
  static const String studentSaveError =
      'Could not save your profile. Please try again.';
  static const String profileLoadError = 'Could not load your profile.';
  static const String profileRetry = 'Retry';

  // Student change-password screen
  static const String profileChangePassword = 'Change Password';
  static const String changePasswordSubtitle =
      'Enter your current password, then choose a new one.';
  static const String changePasswordCurrent = 'Current Password';
  static const String changePasswordNew = 'New Password';
  static const String changePasswordConfirm = 'Confirm New Password';
  static const String changePasswordSubmit = 'Update Password';
  static const String changePasswordSuccessSnack = 'Password updated.';
  static const String changePasswordSameAsOld =
      'New password must differ from the current one.';

  // Owner profile screen (reuses the shared profile* strings above)
  static const String ownerProfileBilling = 'Billing';

  // Owner profile - backend-wired edit form (read uses GET /auth/me)
  static const String ownerEditTitle = 'Edit Profile';
  static const String ownerFieldName = 'Full name';
  static const String ownerFieldEmail = 'Email';
  static const String ownerFieldPhone = 'Phone';
  static const String ownerProfileSavedSnack = 'Profile saved.';
  static const String ownerProfileSaveError =
      'Could not save your profile. Please try again.';

  // Owner dashboard screen
  static const String dashboardGreetingPrefix = 'Welcome back, ';
  static const String dashboardGreetingSuffix = ' 👋';

  /// Greeting when the owner's name isn't available (keeps it from reading
  /// "Welcome back,  👋" with a gap).
  static const String dashboardGreetingNoName = 'Welcome back 👋';
  static const String dashboardSubtitle = "Here's how your centre is doing.";
  static const String dashboardStatProfileViews = 'Profile Views';
  static const String dashboardStatNewEnquiries = 'New Enquiries';
  static const String dashboardStatRating = 'Avg. Rating';
  static const String dashboardStatActiveStudents = 'Active Students';
  static const String dashboardViewsChartTitle = 'Profile Views';
  static const String dashboardViewsChartSubtitle = 'Last 7 days';
  static const String dashboardQuickActions = 'Quick Actions';
  static const String dashboardActionEditCenter = 'Edit Center';
  static const String dashboardActionManageCourses = 'Manage Courses';
  static const String dashboardActionViewEnquiries = 'View Enquiries';
  static const String dashboardActionShareLink = 'Share Link';
  static const String dashboardRecentEnquiries = 'Recent Enquiries';
  static const String dashboardViewAll = 'View all';
  static const String dashboardEnquiryNew = 'NEW';
  static const String dashboardReviewsSuffix = ' reviews';
  static const String dashboardLoadError = 'Could not load your dashboard.';
  static const String dashboardRetry = 'Retry';
  static const String dashboardNoEnquiries = 'No enquiries yet.';
  static const String timeJustNow = 'Just now';
  static const String timeYesterday = 'Yesterday';
  static const String timeMinutesAgoSuffix = 'm ago';
  static const String timeHoursAgoSuffix = 'h ago';
  static const String timeDaysAgoSuffix = 'd ago';

  // Owner enquiries - inbox
  static const String enquiriesTitle = 'Enquiries';
  static const String enquiriesSearchHint = 'Search enquiries...';
  static const String enquiriesFilterAll = 'All';
  static const String enquiriesFilterNew = 'New';
  static const String enquiriesFilterReplied = 'Replied';
  static const String enquiriesFilterArchived = 'Archived';
  static const String enquiriesUnreadSuffix = 'unread';
  static const String enquiriesNewBadge = 'NEW';
  static const String enquiriesEmptyTitle = 'No enquiries here';
  static const String enquiriesEmptySubtitle =
      'When students reach out, their messages will appear here.';

  // Owner manage-center - read view
  static const String centerTabTitle = 'My Center';
  static const String centerEdit = 'Edit';
  static const String centerStatViews = 'Views';
  static const String centerStatRating = 'Rating';
  static const String centerStatReviews = 'Reviews';
  static const String centerSectionAbout = 'About';
  static const String centerSectionSubjects = 'Subjects Offered';
  static const String centerSectionBoards = 'Boards / Curriculum';
  static const String centerSectionTimings = 'Class Timings';
  static const String centerSectionPhotos = 'Photos';
  static const String centerSectionContact = 'Contact';
  static const String centerSectionFees = 'Courses & Fees';
  static const String centerTimingClosed = 'Closed';
  static const String centerTimingTo = 'to';

  // Owner manage-center - edit form
  static const String centerEditTitle = 'Edit Center';
  static const String centerSave = 'Save Changes';
  static const String centerSavedSnack = 'Center details saved.';
  static const String centerPhotoAdd = 'Add Photo';
  static const String centerAddCourse = 'Add Course';
  static const String centerOpenLabel = 'Open';
  static const String centerFieldName = 'Center Name';
  static const String centerFieldTagline = 'Tagline';
  static const String centerFieldLocation = 'Location';
  static const String centerFieldAddress = 'Address';
  static const String centerFieldAbout = 'About';
  static const String centerFieldPhone = 'Phone';
  static const String centerFieldEmail = 'Email';
  static const String centerFieldCourseName = 'Course name';
  static const String centerFieldFee = 'Fee';

  // Owner manage-center - backend-wired read view + edit form
  static const String centerFieldArea = 'Area';
  static const String centerFieldCity = 'City';
  static const String centerFieldState = 'State';
  static const String centerFieldPincode = 'PIN code';
  static const String centerFieldAlternatePhone = 'Alternate phone';
  static const String centerFieldWebsite = 'Website';
  static const String centerFieldDescription = 'Description';
  static const String centerSectionClasses = 'Classes';
  static const String centerFieldClassFrom = 'From class';
  static const String centerFieldClassTo = 'To class';
  static const String centerClassAny = 'Any';
  static const String centerClassPrefix = 'Class ';
  static const String centerFeeMin = 'Minimum fee';
  static const String centerFeeMax = 'Maximum fee';
  static const String centerFeeCurrency = 'Currency';
  static const String centerFeeRangeSep = ' – ';
  static const String centerNotSet = 'Not set';
  static const String centerLoadError = 'Could not load your center.';
  static const String centerSaveError =
      'Could not save your changes. Please try again.';
  static const String centerSelectHint = 'Select';

  // Student coaching-center detail screen
  static const String centerDetailLoadError = 'Could not load this center.';
  static const String centerDetailVerified = 'Verified';
  static const String centerDetailReviews = 'Reviews';
  static const String centerDetailNoReviews = 'No reviews yet.';
  static const String centerDetailEnquire = 'Enquire';
  static const String centerEnquiryTitle = 'Send an enquiry';
  static const String centerEnquiryMessageLabel = 'Your message';
  static const String centerEnquiryMessageHint =
      "Hi, I'd like to know more about your courses…";
  static const String centerEnquirySubjectLabel = 'Subject (optional)';
  static const String centerEnquirySubjectNone = 'General enquiry';
  static const String centerEnquirySend = 'Send enquiry';
  static const String centerEnquirySuccess = 'Enquiry sent.';
  static const String centerEnquiryError =
      'Could not send your enquiry. Please try again.';

  // Student teacher detail screen (reuses teacherSectionAbout /
  // teacherSectionSubjects defined for the teacher shell).
  static const String teacherDetailLoadError = 'Could not load this teacher.';
  static const String teacherSectionBoards = 'Boards';
  static const String teacherSectionClasses = 'Classes';
  static const String teacherSectionExperience = 'Experience';
  static const String teacherSectionLanguages = 'Languages';
  static const String teacherSectionFees = 'Fees';
  static const String teacherSectionEducation = 'Education';
  static const String teacherSectionBatches = 'Batches';
  static const String teacherYearsSuffix = ' years';

  // Owner manage-center - create flow (POST /api/centers)
  static const String centerCreateTitle = 'Add Coaching Center';
  static const String centerCreateIntro =
      'Tell students about your center. You can add subjects, fees, timings, and '
      'photos later from the Edit screen.';
  static const String centerCreateSectionBasics = 'Basics';
  static const String centerCreateSectionLocation = 'Location & Contact';
  static const String centerCreateFieldDescription = 'Description';
  static const String centerCreateFieldDescriptionHint =
      'A short intro to your center (optional)';
  static const String centerCreateFieldCity = 'City';
  static const String centerCreateFieldState = 'State';
  static const String centerCreateFieldPincode = 'PIN code';
  static const String centerCreateSubmit = 'Create Center';
  static const String centerCreatedSnack = 'Coaching center created.';
  static const String centerCreateError =
      'Could not create your center. Please try again.';

  // Owner create-center wizard (3 steps) + setup gate.
  static const String centerWizardStepBasics = 'Basics';
  static const String centerWizardStepLocation = 'Location & contact';
  static const String centerWizardStepReview = 'Review & create';
  static const String centerWizardNext = 'Next';
  static const String centerWizardBack = 'Back';
  static const String centerWizardReviewHint =
      'Check your details, then create your center.';
  static const String centerWizardNotProvided = 'Not provided';
  static const String centerSetupError =
      'Could not check your center. Please try again.';

  // Owner enquiries - detail
  static const String enquiryReplyHint = 'Type your reply...';
  static const String enquiryReplyJustNow = 'Just now';
  static const String enquiryContactCall = 'Call';
  static const String enquiryContactEmail = 'Email';
  static const String enquiryActionArchive = 'Archive';
  static const String enquiryActionUnarchive = 'Unarchive';
  static const String enquiryStatusNew = 'New';
  static const String enquiryStatusReplied = 'Replied';
  static const String enquiryStatusArchived = 'Archived';
  static const String enquiryConversationLabel = 'Conversation';
  static const String enquiryNotFound = 'This enquiry is no longer available.';

  // Owner enquiries - backend-wired (status: new / contacted / closed)
  static const String enquiriesFilterContacted = 'Contacted';
  static const String enquiriesFilterClosed = 'Closed';
  static const String enquiryStatusContacted = 'Contacted';
  static const String enquiryStatusClosed = 'Closed';
  static const String enquiriesLoadError = 'Could not load enquiries.';
  static const String enquiryMessageLabel = 'Message';
  static const String enquiryStatusLabel = 'Status';
  static const String enquiryNotesLabel = 'Private notes';
  static const String enquiryNotesHint =
      'Notes for yourself — the student never sees these.';
  static const String enquiryNotesSave = 'Save notes';
  static const String enquiryNotesSavedSnack = 'Notes saved.';
  static const String enquiryStatusUpdatedSnack = 'Status updated.';
  static const String enquiryUpdateError =
      'Could not update. Please try again.';

  // Phase 1 stub messages
  static const String stubGoogleSignIn =
      'Phase 1: Google sign-in not implemented yet.';
  static const String stubAppleSignIn =
      'Phase 1: Apple sign-in not implemented yet.';
  static const String stubForgotPassword =
      'Phase 1: password reset not implemented yet.';
  static const String stubTermsTap =
      'Phase 1: terms / privacy pages not implemented yet.';
  static const String stubTermsRequired =
      'Please accept the Terms of Service and Privacy Policy to continue.';
  static const String stubComingSoon = 'Coming soon.';

  // Bottom-nav labels
  static const String navHome = 'Home';
  static const String navSearch = 'Search';
  static const String navSaved = 'Saved';
  static const String navProfile = 'Profile';
  static const String navDashboard = 'Dashboard';
  static const String navCenter = 'Center';
  static const String navEnquiries = 'Enquiries';
  static const String navSchedule = 'Schedule';

  // Teacher placeholder screens (Phase 1 - real UIs land per design later)
  static const String teacherComingSoon = 'Coming soon';

  // Teacher home - activity control center
  static const String teacherHomeGreetingPrefix = 'Good morning, ';
  static const String teacherHomeGreetingSuffix = ' 👋';
  static const String teacherHomeTodaySessions = "Today's Sessions";
  static const String teacherHomeNoSessions = 'No sessions scheduled today.';
  static const String teacherHomeRecentEnquiries = 'Recent Enquiries';
  static const String teacherHomeNoEnquiries = 'No new enquiries yet.';
  static const String teacherHomeViewAll = 'View all';
  static const String teacherHomeEditProfile = 'Edit Profile';
  static const String teacherHomeShareProfile = 'Share Profile';
  static const String teacherHomeEnquiryWantsPrefix = 'Wants ';

  // Teacher schedule - week strip + a day's sessions
  static const String teacherScheduleTitle = 'Schedule';
  static const String teacherScheduleSession = 'session';
  static const String teacherScheduleSessions = 'sessions';
  static const String teacherScheduleNoSessions =
      'No sessions scheduled for this day.';
  static const String teacherScheduleToday = 'Today';

  // Teacher search - find a coaching center to affiliate with
  static const String teacherSearchHint = 'Search coaching centers...';
  static const String teacherSearchHiringFilter = 'Hiring now';
  static const String teacherSearchHiringBadge = 'Hiring';
  static const String teacherSearchBrowseSubject = 'Browse by subject';
  static const String teacherSearchRecent = 'Recent searches';
  static const String teacherSearchRequestAffiliate = 'Request to affiliate';
  static const String teacherSearchFoundPrefix = 'Found';
  static const String teacherSearchCentersWord = 'centers';
  static const String teacherSearchNoResultsTitle = 'No centers found';
  static const String teacherSearchNoResultsSubtitle =
      'Try a different subject or turn off the Hiring filter.';

  // Teacher profile - read view
  static const String teacherProfileTitle = 'Profile';
  static const String teacherProfileEdit = 'Edit';
  static const String teacherStatusIndependent = 'Independent Tutor';
  static const String teacherStatusAffiliatedPrefix = 'At ';
  static const String teacherStatViews = 'Views';
  static const String teacherStatStudents = 'Students';
  static const String teacherStatRating = 'Rating';
  static const String teacherStatResponse = 'Response';
  static const String teacherSectionAbout = 'About';
  static const String teacherSectionSubjects = 'Subjects & Expertise';
  static const String teacherSectionRate = 'Rate & Experience';
  static const String teacherRatePerHourSuffix = '/hr';
  static const String teacherExperienceSuffix = 'yrs experience';
  static const String teacherSettingsAvailability = 'Availability';
  static const String teacherSettingsPayouts = 'Payouts';

  // Teacher profile - edit form
  static const String teacherEditTitle = 'Edit Profile';
  static const String teacherFieldName = 'Name';
  static const String teacherFieldHeadline = 'Headline';
  static const String teacherFieldEmail = 'Email';
  static const String teacherFieldBio = 'About';
  static const String teacherFieldExpertise = 'Expertise / specialization';
  static const String teacherFieldRate = 'Hourly rate (₹)';
  static const String teacherFieldExperience = 'Years of experience';
  static const String teacherFieldIndependent = 'Independent tutor';
  static const String teacherFieldAffiliation = 'Affiliated center';
  static const String teacherSavedSnack = 'Profile saved.';
  static const String teacherSave = 'Save Changes';

  // Generic errors
  static const String errorNetwork =
      'Network problem. Check your connection and try again.';
  static const String errorServer =
      'Something went wrong on our end. Please try again.';
  static const String errorUnknown = 'An unexpected error occurred.';
  static const String errorUnauthorized = 'Please sign in again.';
}
