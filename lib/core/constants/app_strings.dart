/// All user-facing strings (button labels, screen titles, error messages).
library;

/// User-facing copy. Phase 1 only includes strings used by `main.dart` and the
/// onboarding screen; more get added as features are built.
abstract final class AppStrings {
  AppStrings._();

  static const String appName = 'CoachFinder';

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

  // Student search screen
  static const String searchHint = 'Search teachers & institutes...';
  static const String searchSegmentAll = 'All';
  static const String searchSegmentTeachers = 'Teachers';
  static const String searchSegmentInstitutes = 'Institutes';
  static const String searchBrowseByCategory = 'Browse by category';
  static const String searchRecentSearches = 'Recent searches';
  static const String searchFilters = 'Filters';
  static const String searchFoundPrefix = 'Found';
  static const String searchResultsWord = 'results';
  static const String searchTeachersWord = 'teachers';
  static const String searchInstitutesWord = 'institutes';
  static const String searchPerSessionSuffix = '/session';
  static const String searchCoursesSuffix = 'courses';
  static const String searchNoResultsTitle = 'No matches found';
  static const String searchNoResultsSubtitle =
      'Try a different search term or category.';

  // Student saved screen
  static const String savedTitle = 'Saved';
  static const String savedSearchHint = 'Search saved tutors & coachings...';
  static const String savedFilterAll = 'All';
  static const String savedFilterCoachings = 'Coachings';
  static const String savedFilterTutors = 'Tutors';
  static const String savedCountWord = 'saved';
  static const String savedRemoveTooltip = 'Remove from saved';
  static const String savedEmptyTitle = 'Nothing saved yet';
  static const String savedEmptySubtitle =
      'Bookmark tutors and coachings to find them here.';

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

  // Owner profile screen (reuses the shared profile* strings above)
  static const String ownerProfileBilling = 'Billing';

  // Owner dashboard screen
  static const String dashboardGreetingPrefix = 'Welcome back, ';
  static const String dashboardGreetingSuffix = ' 👋';
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
