// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Xenova Health';

  @override
  String get welcomeMessage => 'Welcome to Xenova Health';

  @override
  String get login => 'Log In';

  @override
  String get register => 'Sign Up';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get resetPassword => 'Reset Password';

  @override
  String get orContinueWith => 'Or continue with';

  @override
  String get google => 'Google';

  @override
  String get apple => 'Apple';

  @override
  String get name => 'Name';

  @override
  String get age => 'Age';

  @override
  String get gender => 'Gender';

  @override
  String get male => 'Male';

  @override
  String get female => 'Female';

  @override
  String get other => 'Other';

  @override
  String get height => 'Height';

  @override
  String get weight => 'Weight';

  @override
  String get currentWeight => 'Current Weight';

  @override
  String get targetWeight => 'Target Weight';

  @override
  String get activityLevel => 'Activity Level';

  @override
  String get sedentary => 'Sedentary';

  @override
  String get lightlyActive => 'Lightly Active';

  @override
  String get moderatelyActive => 'Moderately Active';

  @override
  String get veryActive => 'Very Active';

  @override
  String get extraActive => 'Extra Active';

  @override
  String get bmi => 'BMI';

  @override
  String get bmr => 'BMR';

  @override
  String get tdee => 'TDEE';

  @override
  String get calories => 'Calories';

  @override
  String get protein => 'Protein';

  @override
  String get carbs => 'Carbs';

  @override
  String get fat => 'Fat';

  @override
  String get fiber => 'Fiber';

  @override
  String get water => 'Water';

  @override
  String get breakfast => 'Breakfast';

  @override
  String get lunch => 'Lunch';

  @override
  String get dinner => 'Dinner';

  @override
  String get snacks => 'Snacks';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get profile => 'Profile';

  @override
  String get settings => 'Settings';

  @override
  String get weightTracker => 'Weight Tracker';

  @override
  String get nutrition => 'Nutrition';

  @override
  String get mealLog => 'Meal Log';

  @override
  String get fasting => 'Fasting';

  @override
  String get measurements => 'Measurements';

  @override
  String get progressPhotos => 'Progress Photos';

  @override
  String get aiCoach => 'AI Coach';

  @override
  String get reports => 'Reports';

  @override
  String get exportData => 'Export Data';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get add => 'Add';

  @override
  String get search => 'Search';

  @override
  String get noData => 'No data available';

  @override
  String get loading => 'Loading...';

  @override
  String get error => 'Something went wrong';

  @override
  String get tryAgain => 'Try Again';

  @override
  String get success => 'Success';

  @override
  String get offline => 'You are offline';

  @override
  String get syncing => 'Syncing...';

  @override
  String get syncComplete => 'Sync complete';

  @override
  String get logWeight => 'Log Weight';

  @override
  String get logMeal => 'Log Meal';

  @override
  String get startFasting => 'Start Fasting';

  @override
  String get stopFasting => 'Stop Fasting';

  @override
  String get takePhoto => 'Take Photo';

  @override
  String get chooseFromGallery => 'Choose from Gallery';

  @override
  String get caloriesConsumed => 'Calories Consumed';

  @override
  String get caloriesRemaining => 'Calories Remaining';

  @override
  String get calorieDeficit => 'Calorie Deficit';

  @override
  String get expectedWeightLoss => 'Expected Weight Loss';

  @override
  String get weeklyReport => 'Weekly Report';

  @override
  String get monthlyReport => 'Monthly Report';

  @override
  String get trend => 'Trend';

  @override
  String get progress => 'Progress';

  @override
  String get streak => 'Streak';

  @override
  String days(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String get kg => 'kg';

  @override
  String get lbs => 'lbs';

  @override
  String get cm => 'cm';

  @override
  String get inches => 'in';

  @override
  String get kcal => 'kcal';

  @override
  String get grams => 'g';

  @override
  String get ml => 'ml';

  @override
  String get liters => 'L';

  @override
  String get logout => 'Log Out';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get lightMode => 'Light Mode';

  @override
  String get systemMode => 'System';

  @override
  String get language => 'Language';

  @override
  String get notifications => 'Notifications';

  @override
  String get premium => 'Premium';

  @override
  String get upgradeToPremium => 'Upgrade to Premium';

  @override
  String get free => 'Free';

  @override
  String version(String version) {
    return 'Version $version';
  }
}
