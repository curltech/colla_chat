import 'package:country_pickers/country.dart';
import 'package:country_pickers/country_picker_cupertino.dart';
import 'package:country_pickers/country_picker_dropdown.dart';
import 'package:country_pickers/utils/utils.dart';
import 'package:flutter/cupertino.dart';

var countryPicker = CountryPickerDropdown(
  initialValue: 'CN',
  itemBuilder: _buildDropdownItem,
  itemFilter: (c) => [
    'CN',
    'US',
    'TW',
    'JP',
    'KR',
  ].contains(c.isoCode),
  priorityList: [
    CountryPickerUtils.getCountryByIsoCode('CN'),
    CountryPickerUtils.getCountryByIsoCode('US'),
  ],
  sortComparator: (Country a, Country b) => a.isoCode.compareTo(b.isoCode),
  onValuePicked: (Country country) {},
);

Widget _buildDropdownItem(Country country) {
  return Container(
    child: Row(
      children: <Widget>[
        CountryPickerUtils.getDefaultFlagImage(country),
        SizedBox(
          width: 8.0,
        ),
        Text("+${country.phoneCode} ${country.isoCode}"),
      ],
    ),
  );
}

/// CountryPickerDialog example
// void _openCountryPickerDialog(BuildContext context) => showDialog(
//   context: context,
//   builder: (context) => Theme(
//       data: Theme.of(context).copyWith(primaryColor: Colors.pink),
//       child: CountryPickerDialog(
//           titlePadding: EdgeInsets.all(8.0),
//           //searchCursorColor: Colors.pinkAccent,
//           searchInputDecoration: InputDecoration(hintText: 'Search...'),
//           isSearchable: true,
//           title: Text('Select your phone code'),
//           onValuePicked: (Country country) {},
//           itemFilter: (c) => ['AR', 'DE', 'GB', 'CN'].contains(c.isoCode),
//           priorityList: [
//             CountryPickerUtils.getCountryByIsoCode('TR'),
//             CountryPickerUtils.getCountryByIsoCode('US'),
//           ],
//           itemBuilder: _buildDialogItem)),
// );

Widget _buildDialogItem(Country country) => Row(
      children: <Widget>[
        CountryPickerUtils.getDefaultFlagImage(country),
        SizedBox(width: 8.0),
        Text("+${country.phoneCode}"),
        SizedBox(width: 8.0),
        Flexible(child: Text(country.name))
      ],
    );

/// CountryPickerCupertino example
void _openCupertinoCountryPicker(BuildContext context) =>
    showCupertinoModalPopup<void>(
        context: context,
        builder: (BuildContext context) {
          return CountryPickerCupertino(
            pickerSheetHeight: 300.0,
            onValuePicked: (Country country) {},
            itemFilter: (c) => ['AR', 'DE', 'GB', 'CN'].contains(c.isoCode),
            priorityList: [
              CountryPickerUtils.getCountryByIsoCode('TR'),
              CountryPickerUtils.getCountryByIsoCode('US'),
            ],
          );
        });
