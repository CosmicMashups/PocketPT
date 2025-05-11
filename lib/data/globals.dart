import 'dart:io';

// Class: AppDetails
class AppDetails {
  static bool isLogin = false;
}

// Class: Details of the User
class UserDetails {
  static String firstName = 'Yuri';
  static String lastName = 'Brown';
  static String email = 'bym0866@dlsud.edu.ph';
  static String password = '1234';
  static List<String> notifications = [
    'You have a new workout plan: Push-Ups 3 sets, 10 reps.',
    'Reminder: Complete your lateral raise exercises today.',
    'Your streak is 5 days. Keep up the good work!',
    'It\'s time for your next workout session.',
    'You completed 3 exercises today! Great job.',
    'New workout suggestion: 3 sets of Squats.',
    'Time to hydrate after your workout. Drink water!',
    'You\'ve reached 70% of your weekly goal. Keep going!',
    'Reminder: Check your progress and update your stats.',
    'You\'ve burned 200 calories today. Well done!',
  ];
}

// Class: Tracking the progress of the user
class UserProgress {
  static String title = 'Initiator';
  static String titleColor = '';
  static int streak = 0;
  static int totalDays = 0;
  static int totalExercises = 0;
  static int totalMinutes = (totalSeconds / 60).toInt();
  static int totalSeconds = 0;
  static String? notes;
}

// Class: Initial Assessment Data
class UserAssess {
  static String rehabGoal = '';
  static String generalMuscle = '';
  static String specificMuscle = '';
  static File? painVideo;
  static int painScale = 0;
  static String painLevel = '';
  static String painType = '';
  static String painDuration = '';
  static bool isInjured = false;
  static bool isAssessed = false;
}

// Class: Preferences of the User
class UserSettings {
  static bool isDailyReminder = true;
  static bool isStreakAlert = true;
}