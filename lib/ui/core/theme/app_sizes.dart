/// Nest structural size tokens — fixed shell dimensions and icon sizes.
abstract final class AppSizes {
  /// Height of the top bar.
  static const double topbarHeight = 56;

  /// Width of the persistent sidebar on large viewports.
  static const double sidebarWidth = 240;

  /// Height of the persistent bottom navigation bar on small viewports.
  static const double mobileBottomNavHeight = 80;

  /// Navigation icons.
  static const double iconSmall = 16;

  /// Content-area icons.
  static const double iconMedium = 18;

  /// Stat-card icons.
  static const double iconLarge = 20;

  /// Diameter of a category icon chip in an expense row.
  static const double categoryIcon = 40;

  /// Empty-state and placeholder icons.
  static const double iconDisplay = 32;

  /// Minimum height of an interactive button.
  static const double buttonHeight = 40;

  /// Height of a single day row in the calendar grid. The width is derived
  /// from the available space, never fixed, so the seven columns never
  /// overflow a narrow phone.
  static const double calendarCell = 48;

  /// Diameter of the highlighted (selected / today) day circle.
  static const double calendarDayCircle = 36;

  /// Diameter of a single event dot under a day number.
  static const double calendarDot = 5;

  /// Thickness of a progress bar.
  static const double progressBarHeight = 6;

  /// Diameter of the hero progress ring.
  static const double progressRing = 68;

  /// Stroke width of the hero progress ring.
  static const double progressRingStroke = 7;

  /// Maximum height of a bar in the mini bar chart.
  static const double barChartHeight = 64;

  /// Width of an editable money field in the expense ledger.
  static const double moneyFieldWidth = 112;

  /// Maximum width of a single-column content area, so it does not stretch
  /// uncomfortably wide on desktop viewports.
  static const double contentMaxWidth = 720;
}
