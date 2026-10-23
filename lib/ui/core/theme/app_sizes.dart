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

  /// Diameter of the small state dot in a badge.
  static const double badgeDot = 6;

  /// Stroke width of an inline button spinner.
  static const double spinnerStroke = 2;

  /// Height of a loading-skeleton heading line.
  static const double skeletonHeadingHeight = 20;

  /// Width of a loading-skeleton heading line.
  static const double skeletonHeadingWidth = 180;

  /// Width of a short loading-skeleton line.
  static const double skeletonShortWidth = 220;

  /// Width of a focused input border.
  static const double inputFocusBorderWidth = 2;

  /// Width of a focused invalid input border.
  static const double inputFocusErrorBorderWidth = 1.5;

  /// Empty-state and placeholder icons.
  static const double iconDisplay = 32;

  /// Diameter of the tinted circle behind an empty-state icon.
  static const double emptyStateCircle = 64;

  /// Diameter of a year-strip month dot.
  static const double yearStripDot = 10;

  /// Diameter of the current month's ring in a year strip.
  static const double yearStripRing = 16;

  /// Stroke width of the current month's ring in a year strip.
  static const double yearStripRingWidth = 1.5;

  /// Diameter of a donut chart.
  static const double donutChart = 160;

  /// Stroke width of a donut chart ring.
  static const double donutStroke = 20;

  /// Diameter of a donut legend swatch.
  static const double donutLegendDot = 10;

  /// Angular gap between donut slices, in radians.
  static const double donutSliceGap = 0.04;

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

  /// Thickness of the mini progress bar inside a month tile.
  static const double monthTileProgressHeight = 4;

  /// Diameter of the hero progress ring.
  static const double progressRing = 68;

  /// Stroke width of the hero progress ring.
  static const double progressRingStroke = 7;

  /// Diameter of a compact progress ring inside a list row.
  static const double progressRingSmall = 44;

  /// Stroke width of a compact progress ring.
  static const double progressRingSmallStroke = 5;

  /// Maximum height of a bar in the mini bar chart.
  static const double barChartHeight = 64;

  /// Height reserved for the value label above the bar chart.
  static const double barChartTooltipHeight = 18;

  /// Thickness of the planned-value marker on a bar chart.
  static const double barChartPlannedLine = 2;

  /// Width of an editable money field in the expense ledger.
  static const double moneyFieldWidth = 112;

  /// Maximum width of a single-column content area, so it does not stretch
  /// uncomfortably wide on desktop viewports.
  static const double contentMaxWidth = 720;
}
