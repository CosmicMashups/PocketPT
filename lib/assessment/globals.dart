import 'dart:io';

class AppDetails {
  static bool isLogin = false;
}

class UserDetails {
  static String firstName = 'Yuri';
  static String lastName = 'Brown';
  static String email = 'bym0866@dlsud.edu.ph';
  static String password = '1234';
}

class UserProgress {
  static String title = 'Initiator';
  static String titleColor = '';
  static int streak = 0;
  static int totalDays = 0;
  static int totalExercises = 0;
  static int totalMinutes = 0;
}

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
}

class UserSettings {
  static bool isDailyReminder = false;
  static bool isStreakAlert = false;
}