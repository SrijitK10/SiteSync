import 'package:flutter_test/flutter_test.dart';

import 'package:app/l10n/app_localizations.dart';

void main() {
  test('localizations expose supported locales', () {
    expect(AppLocalizations.supportedLocales, isNotEmpty);
  });
}
