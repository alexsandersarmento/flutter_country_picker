import 'package:country_picker/src/country_parser.dart';
import 'package:country_picker/src/utils.dart';
import 'package:flutter/material.dart';

import 'country_localizations.dart';

///The country Model that has all the country
///information needed from the [country_picker]
class Country {
  static Country worldWide = Country(
    phoneCode: '',
    countryCode: 'WW',
    e164Sc: -1,
    geographic: false,
    level: -1,
    name: 'World Wide',
    example: '',
    displayName: 'World Wide (WW)',
    displayNameNoCountryCode: 'World Wide',
    e164Key: '',
  );

  ///The country phone code
  final String phoneCode;

  ///The country code, ISO (alpha-2)
  final String countryCode;
  final int e164Sc;
  final bool geographic;
  final int level;

  ///The country name in English
  final String name;

  ///The country name localized. It will be initialized after the Country object is created.
  late String nameLocalized;

  ///An example of a telephone number without the phone code
  final String example;

  ///Country name (country code) [phone code]
  final String displayName;

  ///An example of a telephone number with the phone code and plus sign
  final String? fullExampleWithPlusSign;

  ///Country name (country code)

  final String displayNameNoCountryCode;
  final String e164Key;

  @Deprecated(
    'The modern term is displayNameNoCountryCode. '
    'This feature was deprecated after v1.0.6.',
  )
  String get displayNameNoE164Cc => displayNameNoCountryCode;

  /// Initializes the localized name for the country.
  /// Uses the translated name if available, otherwise falls back to the English name.
  void initLocalizedName(BuildContext context) {
    nameLocalized = CountryLocalizations.of(context)?.countryName(countryCode: countryCode)?.replaceAll(RegExp(r"\s+"), " ") ?? name;
  }

  /// Initializes the localized name for the 'World Wide' static instance.
  static void initWorldWideLocalizedName(BuildContext context) {
    worldWide.nameLocalized = CountryLocalizations.of(context)?.countryName(countryCode: worldWide.countryCode)?.replaceAll(RegExp(r"\s+"), " ") ?? worldWide.name;
  }

  Country({
    required this.phoneCode,
    required this.countryCode,
    required this.e164Sc,
    required this.geographic,
    required this.level,
    required this.name,
    required this.example,
    required this.displayName,
    required this.displayNameNoCountryCode,
    required this.e164Key,
    this.fullExampleWithPlusSign,
  });

  Country.from({required Map<String, dynamic> json})
      : phoneCode = json['e164_cc'] as String,
        countryCode = json['iso2_cc'] as String,
        e164Sc = json['e164_sc'] as int,
        geographic = json['geographic'] as bool,
        level = json['level'] as int,
        name = json['name'] as String,
        example = json['example'] as String,
        displayName = json['display_name'] as String,
        fullExampleWithPlusSign = json['full_example_with_plus_sign'] as String?,
        displayNameNoCountryCode = json['display_name_no_e164_cc'] as String,
        e164Key = json['e164_key'] as String;

  static Country parse(String country) {
    if (country == worldWide.countryCode) {
      return worldWide;
    } else {
      return CountryParser.parse(country);
    }
  }

  static Country? tryParse(String country) {
    if (country == worldWide.countryCode) {
      return worldWide;
    } else {
      return CountryParser.tryParse(country);
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['e164_cc'] = phoneCode;
    data['iso2_cc'] = countryCode;
    data['e164_sc'] = e164Sc;
    data['geographic'] = geographic;
    data['level'] = level;
    data['name'] = name;
    data['nameLocalized'] = nameLocalized;
    data['example'] = example;
    data['display_name'] = displayName;
    data['full_example_with_plus_sign'] = fullExampleWithPlusSign;
    data['display_name_no_e164_cc'] = displayNameNoCountryCode;
    data['e164_key'] = e164Key;
    return data;
  }

  /// Checks if the country's properties (name, code, phone code, localized name) start with the query.
  /// The [localizations] parameter is no longer used as [nameLocalized] is pre-initialized.
  bool startsWith(String query, CountryLocalizations? localizations /* not used anymore */) {
    String lowerCaseQuery = query.toLowerCase();
    if (lowerCaseQuery.startsWith("+")) {
      lowerCaseQuery = lowerCaseQuery.replaceAll("+", "").trim();
    }
    if (lowerCaseQuery.isEmpty) return true;

    return phoneCode.startsWith(lowerCaseQuery) || name.toLowerCase().startsWith(lowerCaseQuery) || countryCode.toLowerCase().startsWith(lowerCaseQuery) || nameLocalized.toLowerCase().startsWith(lowerCaseQuery);
  }

  bool get iswWorldWide => countryCode == Country.worldWide.countryCode;

  @override
  String toString() => 'Country(countryCode: $countryCode, name: $name, nameLocalized: $nameLocalized)';

  @override
  bool operator ==(Object other) {
    if (other is Country) {
      return other.countryCode == countryCode;
    }
    return super == other;
  }

  @override
  int get hashCode => countryCode.hashCode;

  String get flagEmoji => Utils.countryCodeToEmoji(countryCode);
}
