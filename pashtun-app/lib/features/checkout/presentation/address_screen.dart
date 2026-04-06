import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/models/order.dart';

class AddressScreen extends StatefulWidget {
  const AddressScreen({super.key});

  @override
  State<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen> {
  final _formKey = GlobalKey<FormState>();

  final _firstNameCtrl  = TextEditingController();
  final _lastNameCtrl   = TextEditingController();
  final _emailCtrl      = TextEditingController();
  final _phoneCtrl      = TextEditingController();
  final _address1Ctrl   = TextEditingController();
  final _address2Ctrl   = TextEditingController();
  final _cityCtrl       = TextEditingController();
  final _provinceCtrl   = TextEditingController();
  final _countryCtrl    = TextEditingController(text: 'India');
  final _zipCtrl        = TextEditingController();

  @override
  void dispose() {
    for (final c in [
      _firstNameCtrl, _lastNameCtrl, _emailCtrl, _phoneCtrl,
      _address1Ctrl, _address2Ctrl, _cityCtrl, _provinceCtrl,
      _countryCtrl, _zipCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final address = ShippingAddress(
        address1: _address1Ctrl.text.trim(),
        address2: _address2Ctrl.text.trim(),
        city: _cityCtrl.text.trim(),
        province: _provinceCtrl.text.trim(),
        country: _countryCtrl.text.trim(),
        zip: _zipCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
      );
      context.pop(address);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Shipping Address', style: AppTextStyles.headlineMedium),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _row(
              _field(_firstNameCtrl, 'First Name', required: true),
              _field(_lastNameCtrl, 'Last Name', required: true),
            ),
            const SizedBox(height: 12),
            _field(_emailCtrl, 'Email', keyboard: TextInputType.emailAddress,
                required: true),
            const SizedBox(height: 12),
            _field(_phoneCtrl, 'Phone', keyboard: TextInputType.phone,
                required: true),
            const SizedBox(height: 12),
            _field(_address1Ctrl, 'Address Line 1', required: true),
            const SizedBox(height: 12),
            _field(_address2Ctrl, 'Address Line 2 (optional)'),
            const SizedBox(height: 12),
            _row(
              _field(_cityCtrl, 'City', required: true),
              _field(_provinceCtrl, 'State / Province', required: true),
            ),
            const SizedBox(height: 12),
            _row(
              _field(_zipCtrl, 'PIN / ZIP', required: true,
                  keyboard: TextInputType.number),
              _field(_countryCtrl, 'Country', required: true),
            ),
            const SizedBox(height: 32),
            AppButton(label: 'Save Address', onPressed: _submit),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label, {
    bool required = false,
    TextInputType keyboard = TextInputType.text,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboard,
      decoration: InputDecoration(labelText: label),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
          : null,
    );
  }

  Widget _row(Widget a, Widget b) => Row(
    children: [
      Expanded(child: a),
      const SizedBox(width: 12),
      Expanded(child: b),
    ],
  );
}
