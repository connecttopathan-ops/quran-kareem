#!/bin/bash
# Run this on your Mac from the quran-kareem project root.
# Requires ffmpeg: install with `brew install ffmpeg`
# Creates 28-second .caf clips for iOS notification sounds.

set -e

OUT="ios/Runner"

echo "Creating iOS notification sound clips..."

# Makkah adhan — first 28 seconds
ffmpeg -y -i assets/audio/adhan_makkah.mp3 \
  -t 28 -ar 44100 -ac 1 \
  -f caf "$OUT/adhan_makkah_notification.caf"

# Madinah adhan — first 28 seconds
ffmpeg -y -i assets/audio/adhan_madinah.mp3 \
  -t 28 -ar 44100 -ac 1 \
  -f caf "$OUT/adhan_madinah_notification.caf"

# Makkah Fajr adhan — first 28 seconds
ffmpeg -y -i assets/audio/adhan_makkah_fajr.mp3 \
  -t 28 -ar 44100 -ac 1 \
  -f caf "$OUT/adhan_makkah_fajr_notification.caf"

echo ""
echo "Done! Files created:"
ls -lh "$OUT"/*.caf
echo ""
echo "Next steps:"
echo "  1. In Xcode: Add the 3 .caf files to the Runner target"
echo "     (drag from ios/Runner/ into Xcode, tick 'Runner' target membership)"
echo "  2. Run: git add ios/Runner/*.caf && git commit -m 'Add iOS notification sound clips'"
