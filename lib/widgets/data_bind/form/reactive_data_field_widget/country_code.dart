import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:reactive_forms/reactive_forms.dart';

class ReactiveCountryCodePicker extends ReactiveFormField<String, String> {
  ReactiveCountryCodePicker({
    super.key,
    super.formControlName,
    super.formControl,
    super.validationMessages,
    super.valueAccessor,
    super.showErrors,
    void Function(FormControl<String>)? onChanged,
    void Function(CountryCode?)? onInit,
    List<String> favorite = const [],
    TextStyle? textStyle,
    EdgeInsetsGeometry padding = const EdgeInsets.all(8.0),
    EdgeInsetsGeometry? margin,
    bool showCountryOnly = false,
    InputDecoration searchDecoration = const InputDecoration(),
    TextStyle? searchStyle,
    TextStyle? dialogTextStyle,
    Widget Function(BuildContext)? emptySearchBuilder,
    bool showOnlyCountryWhenClosed = false,
    bool alignLeft = false,
    bool showFlag = true,
    bool? showFlagDialog,
    bool hideMainText = false,
    bool? showFlagMain,
    Decoration? flagDecoration,
    dynamic Function(CountryCode?)? builder,
    double flagWidth = 32.0,
    bool enabled = true,
    TextOverflow textOverflow = TextOverflow.ellipsis,
    Color? barrierColor,
    Color? backgroundColor,
    BoxDecoration? boxDecoration,
    int Function(CountryCode, CountryCode)? comparator,
    List<String>? countryFilter,
    bool hideSearch = false,
    bool hideCloseIcon = false,
    bool showDropDownButton = false,
    Size? dialogSize,
    Color? dialogBackgroundColor,
    Icon closeIcon = const Icon(Icons.close),
    List<Map<String, String>> countryList = codes,
    PickerStyle pickerStyle = PickerStyle.dialog,
    EdgeInsetsGeometry dialogItemPadding =
        const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
    EdgeInsetsGeometry searchPadding =
        const EdgeInsets.symmetric(horizontal: 24),
    MainAxisAlignment headerAlignment = MainAxisAlignment.spaceBetween,
    String? headerText = "Select Country",
    TextStyle headerTextStyle =
        const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    bool hideHeaderText = false,
    EdgeInsets topBarPadding =
        const EdgeInsets.symmetric(vertical: 5.0, horizontal: 20),
  }) : super(
          builder: (field) {
            String? value = field.value;
            return CountryCodePicker(
              onChanged: (code) {
                field.didChange(code.code);
                onChanged?.call(field.control);
              },
              onInit: onInit,
              initialSelection: value,
              favorite: favorite,
              textStyle: textStyle,
              padding: padding,
              margin: margin,
              showCountryOnly: showCountryOnly,
              searchDecoration: searchDecoration,
              searchStyle: searchStyle,
              dialogTextStyle: dialogTextStyle,
              emptySearchBuilder: emptySearchBuilder,
              showOnlyCountryWhenClosed: showOnlyCountryWhenClosed,
              alignLeft: alignLeft,
              showFlag: showFlag,
              showFlagDialog: showFlagDialog,
              hideMainText: hideMainText,
              showFlagMain: showFlagMain,
              flagDecoration: flagDecoration,
              builder: builder,
              flagWidth: flagWidth,
              enabled: enabled,
              textOverflow: textOverflow,
              barrierColor: barrierColor,
              backgroundColor: backgroundColor,
              boxDecoration: boxDecoration,
              comparator: comparator,
              countryFilter: countryFilter,
              hideSearch: hideSearch,
              hideCloseIcon: hideCloseIcon,
              showDropDownButton: showDropDownButton,
              dialogSize: dialogSize,
              dialogBackgroundColor: dialogBackgroundColor,
              closeIcon: closeIcon,
              countryList: countryList,
              pickerStyle: pickerStyle,
              dialogItemPadding: dialogItemPadding,
              searchPadding: searchPadding,
              headerAlignment: headerAlignment,
              headerText: headerText,
              headerTextStyle: headerTextStyle,
              hideHeaderText: hideHeaderText,
              topBarPadding: topBarPadding,
            );
          },
        );
}
