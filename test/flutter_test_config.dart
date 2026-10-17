import 'dart:async';

import 'package:google_fonts/google_fonts.dart';

/// Test bootstrap: never fetch fonts over the network inside tests.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  await testMain();
}
