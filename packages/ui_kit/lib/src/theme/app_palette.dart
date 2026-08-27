import 'package:flutter/material.dart';

/// Raw, brightness-agnostic color ramps — the single source of truth for every
/// pixel of color in the design system.
///
/// **Do not consume [AppPalette] directly in widgets.** It has no notion of
/// light vs dark. Instead read semantic tokens via `context.colors` (see
/// [AppColors]), which map these primitives onto meaning (background, primary,
/// border, …) per [Brightness]. Reaching for a raw ramp inside a widget is the
/// bug this layer exists to prevent.
abstract final class AppPalette {
  // Absolutes
  static const Color white = Color(0xffFFFFFF);
  static const Color black = Color(0xff000000);
  static const Color transparent = Color(0x00000000);

  // Porcelain neutrals. These deliberately lean warm so the UI feels calm and
  // tactile instead of clinical when paired with the soft colour surfaces.
  static const Color neutral0 = white;
  static const Color neutral50 = Color(0xffFAF9FC);
  static const Color neutral100 = Color(0xffF4F2F8);
  static const Color neutral200 = Color(0xffE9E6EE);
  static const Color neutral300 = Color(0xffD9D5E0);
  static const Color neutral400 = Color(0xffAAA6B1);
  static const Color neutral500 = Color(0xff77737F);
  static const Color neutral600 = Color(0xff5A5660);
  static const Color neutral700 = Color(0xff403D45);
  static const Color neutral800 = Color(0xff29272D);
  static const Color neutral900 = Color(0xff17161B);
  static const Color neutral950 = Color(0xff0D0C10);

  // Soft wellness surfaces. They are used as low-emphasis fills, never as the
  // sole carrier of meaning, so their treatment remains accessible in either
  // colour scheme.
  static const Color lavender100 = Color(0xffE5E9FF);
  static const Color mint100 = Color(0xffD9EFEC);
  static const Color peach100 = Color(0xffF7E6DD);

  // Success
  static const Color success100 = Color(0xffDEF7EC);
  static const Color success500 = Color(0xff17B26A);
  static const Color success600 = Color(0xff079455);
  static const Color success700 = Color(0xff046C4E);

  // Error / destructive
  static const Color error100 = Color(0xffFEEDEA);
  static const Color error200 = Color(0xffFAC8BC);
  static const Color error300 = Color(0xffF5886F);
  static const Color error400 = Color(0xffF37153);
  static const Color error500 = Color(0xffF04D28);
  static const Color error700 = Color(0xffC81E1E);

  // Warning
  static const Color warning100 = Color(0xffFFE5B0);
  static const Color warning200 = Color(0xffFFE5B0);
  static const Color warning300 = Color(0xffFFC754);
  static const Color warning400 = Color(0xffFFBC33);
  static const Color warning500 = Color(0xffFFAB00);
  static const Color warning600 = Color(0xffD97706);

  // Info
  static const Color info100 = Color(0xffE8F4FF);
  static const Color info200 = Color(0xffB9DDFE);
  static const Color info300 = Color(0xff68B5FC);
  static const Color info400 = Color(0xff4AA6FC);
  static const Color info500 = Color(0xff1D90FB);
}
