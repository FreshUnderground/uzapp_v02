import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';

import '../../core/res/uza_colors.dart';

/// Default RDC (+243). Wider than Flutter's 48px prefix slot so the dial code stays visible.
const kUzaPhonePrefixConstraints = BoxConstraints(
  minWidth: 118,
  maxWidth: 132,
  minHeight: 48,
  maxHeight: 56,
);

InputDecoration uzaIntlPhoneDecoration(
  BuildContext context, {
  required String labelText,
  String? hintText,
  EdgeInsetsGeometry? contentPadding,
}) {
  return InputDecoration(
    labelText: labelText,
    hintText: hintText,
    labelStyle: const TextStyle(fontSize: 16),
    hintStyle: TextStyle(fontSize: 18, color: Colors.grey[400]),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: UzaColors.divider),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: Colors.grey[300]!),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: UzaColors.primary, width: 2),
    ),
    filled: true,
    fillColor: UzaColors.surfaceOf(context),
    contentPadding: contentPadding ??
        const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
    prefixIconConstraints: kUzaPhonePrefixConstraints,
  );
}

/// Phone field with visible country flag and +243 aligned with the number input.
class UzaIntlPhoneField extends StatelessWidget {
  final TextEditingController? controller;
  final String labelText;
  final String? hintText;
  final ValueChanged<PhoneNumber>? onChanged;
  final FormFieldValidator<PhoneNumber>? validator;
  final String invalidNumberMessage;
  final String initialCountryCode;

  const UzaIntlPhoneField({
    super.key,
    this.controller,
    required this.labelText,
    this.hintText,
    this.onChanged,
    this.validator,
    this.invalidNumberMessage = 'Numéro invalide',
    this.initialCountryCode = 'CD',
  });

  @override
  Widget build(BuildContext context) {
    return IntlPhoneField(
      decoration: uzaIntlPhoneDecoration(
        context,
        labelText: labelText,
        hintText: hintText,
      ),
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
      ),
      dropdownTextStyle: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: UzaColors.onSurface(context),
        height: 1.2,
      ),
      flagsButtonPadding: const EdgeInsets.symmetric(horizontal: 6),
      showDropdownIcon: true,
      initialCountryCode: initialCountryCode,
      disableLengthCheck: false,
      invalidNumberMessage: invalidNumberMessage,
      controller: controller,
      onChanged: onChanged,
      validator: validator,
    );
  }
}

/// Prefix for login: icon + +243, vertically aligned with the digits field.
Widget uzaLoginPhonePrefix(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.only(left: 12, right: 4),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Icon(Icons.phone_outlined, color: UzaColors.primary, size: 22),
        const SizedBox(width: 8),
        Text(
          '+243',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: UzaColors.onSurface(context),
            height: 1.0,
          ),
        ),
        Container(
          width: 1,
          height: 22,
          margin: const EdgeInsets.only(left: 10),
          color: UzaColors.isDark(context)
              ? Colors.white.withValues(alpha: 0.16)
              : Colors.grey.shade300,
        ),
      ],
    ),
  );
}
