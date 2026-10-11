import 'package:flutter/widgets.dart';

/// Marker wrapped around substituted values so they can be styled after the
/// fact. U+E000 is the first Private Use Area code point — it carries no
/// meaning, renders nothing, and will never occur in translated copy.
const String _marker = '\u{E000}';

/// Wraps [value] so [emphasisedText] renders it in the emphasis style.
///
/// Pass the result straight into a generated message:
///
/// ```dart
/// emphasisedText(
///   l.nextPrayerIn(emphasise(prayerName), emphasise(countdown)),
///   baseStyle: dim,
///   emphasisStyle: gold,
/// )
/// ```
String emphasise(Object value) => '$_marker$value$_marker';

/// Renders a localised sentence with some of its substituted values
/// emphasised.
///
/// The problem this solves: `gen-l10n` hands back a finished `String`, so by
/// the time the message reaches the widget its placeholder positions are gone,
/// and with them any way to style only the values.
///
/// The alternative — concatenating separately styled `Text` widgets, which is
/// what this app did before — bakes English word order into the layout.
/// "Next: Maghrib in 2h 15m" happens to survive German, but Japanese places
/// its equivalent of "in" *after* the duration, and Dart-side concatenation
/// cannot express that. Keeping the whole sentence in one ARB string lets the
/// translator put the placeholders wherever the language needs them.
///
/// Marking each value before substitution and splitting on the marker
/// afterwards recovers the positions, wherever the translator moved them.
///
/// If a translation drops a placeholder the markers go unbalanced; the text
/// still renders, just with different runs emphasised. That is a cosmetic
/// slip rather than a crash, which is the right failure for copy supplied
/// outside the compiler's reach.
Text emphasisedText(
  String message, {
  required TextStyle baseStyle,
  required TextStyle emphasisStyle,
  TextAlign? textAlign,
  int? maxLines,
  TextOverflow? overflow,
}) {
  final parts = message.split(_marker);

  return Text.rich(
    TextSpan(
      children: <TextSpan>[
        for (var i = 0; i < parts.length; i++)
          if (parts[i].isNotEmpty)
            TextSpan(
              text: parts[i],
              // Segments between a pair of markers land on odd indices.
              style: i.isOdd ? emphasisStyle : baseStyle,
            ),
      ],
    ),
    textAlign: textAlign,
    maxLines: maxLines,
    overflow: overflow,
  );
}
