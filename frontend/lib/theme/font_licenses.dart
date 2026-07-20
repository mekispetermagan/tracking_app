import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

void registerFontLicenses() {
  LicenseRegistry.addLicense(() async* {
    final nunitoLicense = await rootBundle.loadString(
      'assets/fonts/nunito/OFL.txt',
    );
    yield LicenseEntryWithLineBreaks(['Nunito'], nunitoLicense);

    final montserratLicense = await rootBundle.loadString(
      'assets/fonts/montserrat/OFL.txt',
    );
    yield LicenseEntryWithLineBreaks(['Montserrat'], montserratLicense);
  });
}
