import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:phone_form_field/phone_form_field.dart';

var intlPhoneInput = IntlPhoneField(
  decoration: InputDecoration(
    labelText: 'Phone Number',
    border: OutlineInputBorder(
      borderSide: BorderSide(),
    ),
  ),
  onChanged: (phone) {
    print(phone.completeNumber);
  },
  onCountryChanged: (country) {
    print('Country changed to: ' + country.name);
  },
);
// String? phoneNumber;
// String? phoneIsoCode;
// var intlPhoneImput = InternationalPhoneInput(
//     onPhoneNumberChange: onPhoneNumberChange,
//     initialPhoneNumber: phoneNumber,
//     initialSelection: phoneIsoCode,
//     enabledCountries: ['+233', '+1'],
//     showCountryCodes: false);

void onPhoneNumberChange(
    String number, String internationalizedPhoneNumber, String isoCode) {}

onValidPhoneNumber(
    String number, String internationalizedPhoneNumber, String isoCode) {}

var phoneField = PhoneFormField(
  key: Key('phone-field'),
  controller: null, // controller & initialValue value
  initialValue: null, // can't be supplied simultaneously
  shouldFormat: true, // default
  defaultCountry: IsoCode.US, // default
  decoration: InputDecoration(
      labelText: 'Phone', // default to null
      border: OutlineInputBorder() // default to UnderlineInputBorder(),
// ...
      ),
  validator: PhoneValidator.validMobile(), // default PhoneValidator.valid()
  countrySelectorNavigator: CountrySelectorNavigator.bottomSheet(),
  showFlagInInput: true, // default
  flagSize: 16, // default
  autofillHints: [AutofillHints.telephoneNumber], // default to null
  enabled: true, // default
  autofocus: false, // default
  autovalidateMode: AutovalidateMode.onUserInteraction, // default
  // ignore: avoid_print
  onSaved: (p) => print('saved $p'),
  // ignore: avoid_print
  onChanged: (p) => print('changed $p'),
);

// required : PhoneValidator.required
// valid : PhoneValidator.valid (default value when no validator supplied)
// valid mobile number : PhoneValidator.validMobile
// valid fixed line number : PhoneValidator.validFixedLine
// valid type : PhoneValidator.validType
// valid country : PhoneValidator.validCountry
// none : PhoneValidator.none (this can be used to disable default valid validator)
