/// Backend settings shared with the ExamsAi website (billachusim/examsai).
/// The anon key is public by design; every table is protected by row-level
/// security and all paid features are enforced in edge functions.
class AppConfig {
  static const supabaseUrl = 'https://qmshqibcpetahlmcacjw.supabase.co';
  static const supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFtc2hxaWJjcGV0YWhsbWNhY2p3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk5MzYzMjUsImV4cCI6MjA3NTUxMjMyNX0.75OLovq2gg9JJLIH_7DW5_1wBSz8n6pNMklq79379MU';

  static const websiteUrl = 'https://examsai.lovable.app';
  static const privacyUrl = '$websiteUrl/privacy';
  static const deleteAccountInfoUrl = '$websiteUrl/delete-account';
  static const supportEmail = 'thetechfaculty@gmail.com';

  /// Store product IDs. Must match STORE_PRODUCTS in the backend config.
  static const productDayPass = 'examsai_day_pass';
  static const productMonthly = 'examsai_premium_monthly';
  static const productIds = {productDayPass, productMonthly};
}
