final _amount = RegExp(r'^\d+([.,]\d{1,2})?$');

const _maxCents = 2147483647;

int? parseAmountToCents(String input) {
  final v = input.trim();
  if (!_amount.hasMatch(v)) return null;
  final parts = v.replaceAll(',', '.').split('.');
  final whole = int.tryParse(parts[0]);
  if (whole == null) return null;
  final fraction = parts.length > 1 ? int.parse(parts[1].padRight(2, '0')) : 0;
  final cents = whole * 100 + fraction;
  return cents > _maxCents ? null : cents;
}

String formatCents(int cents) => '${cents ~/ 100}.${(cents % 100).toString().padLeft(2, '0')}';

const _symbols = {'USD': '\$', 'EUR': '€', 'GBP': '£', 'RON': 'lei ', 'JPY': '¥'};

String currencySymbol(String code) => _symbols[code] ?? '$code ';
