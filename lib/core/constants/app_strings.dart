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
  static const String onboardingContinue = 'Continue';

  // Auth - shared
  static const String fieldEmail = 'Email Address';
  static const String hintEmail = 'name@example.com';
  static const String fieldPassword = 'Password';
  static const String google = 'Google';
  static const String apple = 'Apple';

  // Auth - login screen
  static const String loginTitle = 'Welcome back';
  static const String loginSubtitle = 'Sign in to continue your journey of growth.';
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

  // Phase 1 stub messages
  static const String stubAuthNotImplemented =
      'Phase 1: auth backend not implemented yet.';
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

  // Bottom-nav labels
  static const String navHome = 'Home';
  static const String navSearch = 'Search';
  static const String navSaved = 'Saved';
  static const String navProfile = 'Profile';
  static const String navDashboard = 'Dashboard';
  static const String navCenter = 'Center';
  static const String navEnquiries = 'Enquiries';

  // Generic errors
  static const String errorNetwork =
      'Network problem. Check your connection and try again.';
  static const String errorServer =
      'Something went wrong on our end. Please try again.';
  static const String errorUnknown = 'An unexpected error occurred.';
  static const String errorUnauthorized = 'Please sign in again.';
}
