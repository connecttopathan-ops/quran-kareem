/**
 * Get Quran — Feedback Google Apps Script
 *
 * HOW TO DEPLOY:
 *  1. Open your Google Sheet (create a new blank one if needed).
 *  2. Extensions → Apps Script.
 *  3. Delete any existing code, paste this entire file.
 *  4. Click Deploy → New deployment.
 *     - Type: Web app
 *     - Execute as: Me
 *     - Who has access: Anyone
 *  5. Click Deploy → copy the Web app URL.
 *  6. Paste that URL into lib/services/review_service.dart:
 *       static const String _sheetUrl = 'https://script.google.com/macros/s/…/exec';
 *  7. Re-deploy after any code changes (Deploy → Manage deployments → edit).
 *
 * SHEET STRUCTURE (auto-created on first submission):
 *   A: Timestamp  B: Date (ISO)  C: Platform  D: City  E: Language  F: Streak  G: Feedback
 */

var SHEET_NAME = 'Feedback'; // Change if you want a different tab name.

// ── Entry point ────────────────────────────────────────────────────────────────

function doPost(e) {
  try {
    var data = JSON.parse(e.postData.contents);
    _appendRow(data);
    return _json({ status: 'ok' });
  } catch (err) {
    return _json({ status: 'error', message: err.toString() });
  }
}

// Also handle GET so you can test the URL in a browser.
function doGet(e) {
  return _json({ status: 'ok', message: 'Get Quran feedback endpoint is live.' });
}

// ── Internal ───────────────────────────────────────────────────────────────────

function _appendRow(data) {
  var ss    = SpreadsheetApp.getActiveSpreadsheet();
  var sheet = ss.getSheetByName(SHEET_NAME);

  if (!sheet) {
    sheet = ss.insertSheet(SHEET_NAME);
  }

  // Write header row if the sheet is empty.
  if (sheet.getLastRow() === 0) {
    sheet.appendRow(['Timestamp', 'Date (app)', 'Platform', 'City', 'Language', 'Streak', 'Feedback']);
    sheet.getRange(1, 1, 1, 7).setFontWeight('bold');
    sheet.setFrozenRows(1);
  }

  sheet.appendRow([
    new Date(),                                      // A: server timestamp
    data.date     || '',                             // B: date from device (ISO string)
    data.platform || 'unknown',                      // C: android / ios
    data.city     || '',                             // D: prayer location city
    data.language || '',                             // E: translation language code
    data.streak   != null ? data.streak : '',        // F: day streak
    data.feedback || '',                             // G: free-text feedback
  ]);
}

function _json(obj) {
  return ContentService
    .createTextOutput(JSON.stringify(obj))
    .setMimeType(ContentService.MimeType.JSON);
}
