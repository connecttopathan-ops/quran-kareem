import 'package:flutter/material.dart';

enum BookCategory { hadith, seerah }

class IslamicBook {
  final String id;
  final String title;
  final String titleArabic;
  final String author;
  final BookCategory category;
  final int totalItems;
  final int? totalBooks;
  final String collectionKey; // sunnah.com key or 'local:<name>'
  final Color spineColor;
  final String spineChar;
  final double fileSizeMb;

  const IslamicBook({
    required this.id,
    required this.title,
    required this.titleArabic,
    required this.author,
    required this.category,
    required this.totalItems,
    this.totalBooks,
    required this.collectionKey,
    required this.spineColor,
    required this.spineChar,
    required this.fileSizeMb,
  });

  bool get isLocal => collectionKey.startsWith('local:');

  String get metaLine {
    if (category == BookCategory.hadith) {
      return '${_fmt(totalItems)} hadiths · $totalBooks books';
    }
    return '$totalItems chapters';
  }

  String _fmt(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }
}

const kIslamicBooks = <IslamicBook>[
  IslamicBook(
    id: 'bukhari',
    title: 'Sahih Al-Bukhari',
    titleArabic: 'صَحِيْحُ البُخَارِي',
    author: 'Imam Bukhari',
    category: BookCategory.hadith,
    totalItems: 7563,
    totalBooks: 97,
    collectionKey: 'sahih-bukhari',
    spineColor: Color(0xFF1a3a2a),
    spineChar: 'ب',
    fileSizeMb: 8.2,
  ),
  IslamicBook(
    id: 'muslim',
    title: 'Sahih Muslim',
    titleArabic: 'صَحِيْحُ مُسلِم',
    author: 'Imam Muslim',
    category: BookCategory.hadith,
    totalItems: 3033,
    totalBooks: 56,
    collectionKey: 'sahih-muslim',
    spineColor: Color(0xFF2a1a0a),
    spineChar: 'م',
    fileSizeMb: 5.4,
  ),
  IslamicBook(
    id: 'sealed-nectar',
    title: 'The Sealed Nectar',
    titleArabic: 'الرَّحِيقُ الْمَخْتُوم',
    author: 'Safi-ur-Rahman al-Mubarakpuri',
    category: BookCategory.seerah,
    totalItems: 48,
    totalBooks: null,
    collectionKey: 'local:sealed_nectar',
    spineColor: Color(0xFF1a2a3a),
    spineChar: 'ر',
    fileSizeMb: 1.8,
  ),
];
