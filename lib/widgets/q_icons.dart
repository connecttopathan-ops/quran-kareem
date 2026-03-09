import 'package:flutter/material.dart';

class QIcon {
  static Widget home({double size = 24, Color? color}) =>
      _icon(Icons.home_outlined, size, color);
  static Widget book({double size = 24, Color? color}) =>
      _icon(Icons.menu_book_outlined, size, color);
  static Widget search({double size = 24, Color? color}) =>
      _icon(Icons.search, size, color);
  static Widget settings({double size = 24, Color? color}) =>
      _icon(Icons.settings_outlined, size, color);
  static Widget play({double size = 24, Color? color}) =>
      _icon(Icons.play_arrow, size, color);
  static Widget pause({double size = 24, Color? color}) =>
      _icon(Icons.pause, size, color);
  static Widget stop({double size = 24, Color? color}) =>
      _icon(Icons.stop, size, color);
  static Widget nextVerse({double size = 24, Color? color}) =>
      _icon(Icons.skip_next, size, color);
  static Widget previousVerse({double size = 24, Color? color}) =>
      _icon(Icons.skip_previous, size, color);
  static Widget close({double size = 24, Color? color}) =>
      _icon(Icons.close, size, color);
  static Widget locationPin({double size = 24, Color? color}) =>
      _icon(Icons.location_on_outlined, size, color);
  static Widget check({double size = 24, Color? color}) =>
      _icon(Icons.check, size, color);
  static Widget mic({double size = 24, Color? color}) =>
      _icon(Icons.mic_outlined, size, color);
  static Widget share({double size = 24, Color? color}) =>
      _icon(Icons.share_outlined, size, color);
  static Widget bookmark({double size = 24, Color? color}) =>
      _icon(Icons.bookmark_outline, size, color);
  static Widget copy({double size = 24, Color? color}) =>
      _icon(Icons.copy_outlined, size, color);
  static Widget arrowBack({double size = 24, Color? color}) =>
      _icon(Icons.arrow_back_ios, size, color);
  static Widget arrowForward({double size = 24, Color? color}) =>
      _icon(Icons.arrow_forward_ios, size, color);
  static Widget expand({double size = 24, Color? color}) =>
      _icon(Icons.expand_more, size, color);
  static Widget collapse({double size = 24, Color? color}) =>
      _icon(Icons.expand_less, size, color);
  static Widget font({double size = 24, Color? color}) =>
      _icon(Icons.text_fields, size, color);
  static Widget moon({double size = 24, Color? color}) =>
      _icon(Icons.nightlight_outlined, size, color);
  static Widget sun({double size = 24, Color? color}) =>
      _icon(Icons.wb_sunny_outlined, size, color);
  static Widget back({double size = 24, Color? color}) =>
      _icon(Icons.arrow_back_ios, size, color);
  static Widget tune({double size = 24, Color? color}) =>
      _icon(Icons.tune, size, color);
  static Widget more({double size = 24, Color? color}) =>
      _icon(Icons.more_horiz, size, color);
  static Widget listMode({double size = 24, Color? color}) =>
      _icon(Icons.view_list_outlined, size, color);
  static Widget pageMode({double size = 24, Color? color}) =>
      _icon(Icons.menu_book_outlined, size, color);
  static Widget focusMode({double size = 24, Color? color}) =>
      _icon(Icons.center_focus_strong_outlined, size, color);
  static Widget minus({double size = 24, Color? color}) =>
      _icon(Icons.remove, size, color);
  static Widget plus({double size = 24, Color? color}) =>
      _icon(Icons.add, size, color);

  static Widget _icon(IconData data, double size, Color? color) =>
      Icon(data, size: size, color: color);
}
