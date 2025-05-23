import 'package:flutter/material.dart';

import 'country.dart';
import 'country_list_theme_data.dart';
import 'country_localizations.dart';
import 'country_service.dart';
import 'res/country_codes.dart';
import 'utils.dart';

typedef CustomFlagBuilder = Widget Function(Country country);

class CountryListView extends StatefulWidget {
  /// Called when a country is select.
  ///
  /// The country picker passes the new value to the callback.
  final ValueChanged<Country> onSelect;

  /// An optional [showPhoneCode] argument can be used to show phone code.
  final bool showPhoneCode;

  /// An optional [exclude] argument can be used to exclude(remove) one ore more
  /// country from the countries list. It takes a list of country code(iso2).
  /// Note: Can't provide both [exclude] and [countryFilter]
  final List<String>? exclude;

  /// An optional [countryFilter] argument can be used to filter the
  /// list of countries. It takes a list of country code(iso2).
  /// Note: Can't provide both [countryFilter] and [exclude]
  final List<String>? countryFilter;

  /// An optional [favorite] argument can be used to show countries
  /// at the top of the list. It takes a list of country code(iso2).
  final List<String>? favorite;

  /// An optional argument for customizing the
  /// country list bottom sheet.
  final CountryListThemeData? countryListTheme;

  /// An optional argument for initially expanding virtual keyboard
  final bool searchAutofocus;

  /// An optional argument for showing "World Wide" option at the beginning of the list
  final bool showWorldWide;

  /// An optional argument for hiding the search bar
  final bool showSearch;

  /// Custom builder function for flag widget
  final CustomFlagBuilder? customFlagBuilder;

  /// An optional argument for country comparator
  final int Function(Country a, Country b)? countryComparator;

  const CountryListView({
    Key? key,
    required this.onSelect,
    this.exclude,
    this.favorite,
    this.countryFilter,
    this.showPhoneCode = false,
    this.countryListTheme,
    this.searchAutofocus = false,
    this.showWorldWide = false,
    this.showSearch = true,
    this.customFlagBuilder,
    this.countryComparator,
  })  : assert(
          exclude == null || countryFilter == null,
          'Cannot provide both exclude and countryFilter',
        ),
        super(key: key);

  @override
  State<CountryListView> createState() => _CountryListViewState();
}

class _CountryListViewState extends State<CountryListView> {
  final CountryService _countryService = CountryService();

  late List<Country> _countryList;
  late List<Country> _filteredList;
  List<Country>? _favoriteList;
  late TextEditingController _searchController;
  late bool _searchAutofocus;
  bool _isSearching = false;
  bool _dependenciesInitialized = false; // Flag to run didChangeDependencies logic once

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchAutofocus = widget.searchAutofocus;

    // Initial load of countries (without localized names yet)
    _countryList = countryCodes.map((countryData) => Country.from(json: countryData)).toList();
    _filteredList = []; // Initialize to avoid late errors before didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_dependenciesInitialized) {
      // Initialize localized names for all countries in the main list
      for (final country in _countryList) {
        country.initLocalizedName(context);
      }

      // Initialize localized name for the static 'World Wide' instance if shown
      if (widget.showWorldWide) {
        Country.initWorldWideLocalizedName(context);
      }

      // Sort the main list if a comparator is provided
      // This is done after nameLocalized is initialized
      if (widget.countryComparator != null) {
        _countryList.sort(widget.countryComparator);
      }

      if (!widget.showPhoneCode) {
        final ids = _countryList.map((e) => e.countryCode).toSet();
        _countryList.retainWhere((country) => ids.remove(country.countryCode));
      }

      if (widget.exclude != null) {
        _countryList.removeWhere(
          (element) => widget.exclude!.contains(element.countryCode),
        );
      }

      if (widget.countryFilter != null) {
        _countryList.removeWhere(
          (element) => !widget.countryFilter!.contains(element.countryCode),
        );
      }

      // Initialize favorites list and their localized names
      if (widget.favorite != null && widget.favorite!.isNotEmpty) {
        // Assuming _countryService.findCountriesByCode fetches fresh instances
        // or instances that might not have initLocalizedName called.
        final List<Country> tempFavoriteList = _countryService.findCountriesByCode(widget.favorite!);
        for (final favCountry in tempFavoriteList) {
          favCountry.initLocalizedName(context); // Ensure localized name is set
        }
        _favoriteList = tempFavoriteList;
      }

      // Build the initial _filteredList
      _rebuildFilteredList();

      _dependenciesInitialized = true;
    }
  }

  void _rebuildFilteredList() {
    _filteredList.clear();
    if (widget.showWorldWide) {
      _filteredList.add(Country.worldWide);
    }
    _filteredList.addAll(_countryList);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _checkSearchText(String searchText) {
    if (searchText.isNotEmpty) {
      setState(() {
        _isSearching = true;
      });
    } else {
      setState(() {
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final String searchLabel = CountryLocalizations.of(context)?.countryName(countryCode: 'search') ?? 'Search';

    return Column(
      children: <Widget>[
        const SizedBox(height: 12),
        if (widget.showSearch)
          TextField(
            autofocus: _searchAutofocus,
            controller: _searchController,
            style: widget.countryListTheme?.searchTextStyle ?? _defaultTextStyle,
            decoration: widget.countryListTheme?.inputDecoration ??
                InputDecoration(
                  labelText: searchLabel,
                  hintText: searchLabel,
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: const Color(0xFF8C98A8).withValues(alpha: 0.2),
                    ),
                  ),
                ),
            onChanged: (value) {
              _filterSearchResults(value);
              _checkSearchText(value);
            },
          ),
        Expanded(
          child: ListView(
            children: [
              if (_favoriteList != null && _favoriteList!.isNotEmpty && !_isSearching) ...[
                ..._favoriteList!.map<Widget>((country) => _listRow(country)),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.0),
                  child: Divider(thickness: 1),
                ),
              ],
              ..._filteredList.map<Widget>((country) => _listRow(country)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _listRow(Country country) {
    final TextStyle _textStyle = widget.countryListTheme?.textStyle ?? _defaultTextStyle;

    final bool isRtl = Directionality.of(context) == TextDirection.rtl;

    return Material(
      // Add Material Widget with transparent color
      // so the ripple effect of InkWell will show on tap
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          widget.onSelect(country);
          Navigator.pop(context);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5.0),
          child: Row(
            children: <Widget>[
              Row(
                children: [
                  const SizedBox(width: 20),
                  if (widget.customFlagBuilder == null) _flagWidget(country) else widget.customFlagBuilder!(country),
                  if (widget.showPhoneCode && !country.iswWorldWide) ...[
                    const SizedBox(width: 15),
                    SizedBox(
                      width: 45,
                      child: Text(
                        '${isRtl ? '' : '+'}${country.phoneCode}${isRtl ? '+' : ''}',
                        style: _textStyle,
                      ),
                    ),
                    const SizedBox(width: 5),
                  ] else
                    const SizedBox(width: 15),
                ],
              ),
              Expanded(
                child: Text(
                  country.nameLocalized, // Use the pre-initialized localized name
                  style: _textStyle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _flagWidget(Country country) {
    final bool isRtl = Directionality.of(context) == TextDirection.rtl;
    return SizedBox(
      // the conditional 50 prevents irregularities caused by the flags in RTL mode
      width: isRtl ? 50 : null,
      child: _emojiText(country),
    );
  }

  Widget _emojiText(Country country) => Text(
        country.iswWorldWide ? '\uD83C\uDF0D' : Utils.countryCodeToEmoji(country.countryCode),
        style: TextStyle(
          fontSize: widget.countryListTheme?.flagSize ?? 25,
          fontFamilyFallback: widget.countryListTheme?.emojiFontFamilyFallback,
        ),
      );

  void _filterSearchResults(String query) {
    List<Country> _searchResult = <Country>[];
    final CountryLocalizations? localizations = CountryLocalizations.of(context);

    if (query.isEmpty) {
      _searchResult.addAll(_countryList);
    } else {
      _searchResult = _countryList.where((c) => c.startsWith(query, localizations)).toList();
    }

    setState(() => _filteredList = _searchResult);
  }

  TextStyle get _defaultTextStyle => const TextStyle(fontSize: 16);
}
