import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/api_constants.dart';

class WhatsappButton extends StatelessWidget {
  final String message;

  const WhatsappButton({super.key, required this.message});

  Future<void> _openWhatsApp() async {
    final encoded = Uri.encodeComponent(message);
    final url = Uri.parse(
      'https://wa.me/${ApiConstants.whatsappNumber}?text=$encoded',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: _openWhatsApp,
      backgroundColor: const Color(0xFF25D366), // WhatsApp green
      icon: const Icon(Icons.chat, color: Colors.white),
      label: const Text(
        'Enquire on WhatsApp',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      ),
    );
  }
}
