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

/// Converts `*asterisk pairs*` in already-translated copy into emphasis
/// markers, for static phrases where part of the line carries an accent.
///
/// [emphasise] handles the case where the emphasised part is a *substituted
/// value*. This handles the other case: copy where the emphasis belongs to
/// particular words, so the ARB value itself has to carry it.
///
/// Asterisks rather than the raw marker because a translator has to be able
/// to see it. U+E000 is invisible in every editor, so a translator would
/// have no way to tell which words are accented, and would strip or misplace
/// it without ever knowing. Asterisk pairs read as emphasis to anyone who has
/// met Markdown, and they survive a copy-paste between translation tools.
///
/// An unpaired asterisk is left as a literal character rather than swallowed,
/// so a stray one shows up as itself instead of silently restyling the rest
/// of the line.
String emphasiseMarkup(String translated) {
  final parts = translated.split('*');
  if (parts.length.isEven) return translated; // unbalanced — leave it alone
  final buffer = StringBuffer();
  for (var i = 0; i < parts.length; i++) {
    buffer.write(i.isOdd ? '$_marker${parts[i]}$_marker' : parts[i]);
  }
  return buffer.toString();
}

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
