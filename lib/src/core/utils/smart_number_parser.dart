import 'dart:math' as math;

/// Parses user-entered numeric expressions for fast engineering input.
///
/// Supported examples:
/// - 2.2k
/// - 470u
/// - 1/3
/// - 3*pi
/// - (12-2.5)*4
class SmartNumberParser {
  const SmartNumberParser._();

  static double? parse(String raw) {
    var source = raw.trim();
    if (source.isEmpty) {
      return null;
    }

    source = source
        .replaceAll(' ', '')
        .replaceAll(',', '.')
        .replaceAll('x', '*')
        .replaceAll('X', '*')
        .replaceAll('×', '*')
        .replaceAll('÷', '/');

    // Common shorthand: 2pi => 2*pi, 2(3+4) => 2*(3+4)
    source = source
        .replaceAllMapped(RegExp(r'(\d)(pi)', caseSensitive: false), (m) => '${m.group(1)}*${m.group(2)}')
        .replaceAllMapped(RegExp(r'(\d)\('), (m) => '${m.group(1)}*(')
        .replaceAllMapped(RegExp(r'\)(\d)'), (m) => ')*${m.group(1)}');

    try {
      final parser = _ExpressionParser(source);
      final value = parser.parse();
      if (value.isNaN || value.isInfinite) {
        return null;
      }
      return value;
    } catch (_) {
      return null;
    }
  }
}

class _ExpressionParser {
  _ExpressionParser(this._source);

  final String _source;
  int _index = 0;

  double parse() {
    final value = _parseExpression();
    if (!_isAtEnd) {
      throw const FormatException('Unexpected trailing token');
    }
    return value;
  }

  bool get _isAtEnd => _index >= _source.length;

  double _parseExpression() {
    var value = _parseTerm();
    while (!_isAtEnd) {
      if (_match('+')) {
        value += _parseTerm();
      } else if (_match('-')) {
        value -= _parseTerm();
      } else {
        break;
      }
    }
    return value;
  }

  double _parseTerm() {
    var value = _parsePower();
    while (!_isAtEnd) {
      if (_match('*')) {
        value *= _parsePower();
      } else if (_match('/')) {
        value /= _parsePower();
      } else {
        break;
      }
    }
    return value;
  }

  double _parsePower() {
    var left = _parseUnary();
    if (_match('^')) {
      final right = _parsePower();
      left = math.pow(left, right).toDouble();
    }
    return left;
  }

  double _parseUnary() {
    if (_match('+')) {
      return _parseUnary();
    }
    if (_match('-')) {
      return -_parseUnary();
    }
    return _parsePrimary();
  }

  double _parsePrimary() {
    if (_match('(')) {
      final value = _parseExpression();
      if (!_match(')')) {
        throw const FormatException('Missing closing parenthesis');
      }
      return value;
    }

    final constant = _parseConstant();
    if (constant != null) {
      return constant;
    }

    final number = _parseNumber();
    if (number != null) {
      return number;
    }

    throw const FormatException('Expected number or expression');
  }

  double? _parseConstant() {
    final remaining = _source.substring(_index).toLowerCase();
    if (remaining.startsWith('pi')) {
      _index += 2;
      return math.pi;
    }
    if (remaining.startsWith('e')) {
      _index += 1;
      return math.e;
    }
    return null;
  }

  double? _parseNumber() {
    final start = _index;
    var sawDigit = false;

    while (_index < _source.length && _isDigit(_source.codeUnitAt(_index))) {
      sawDigit = true;
      _index++;
    }

    if (_index < _source.length && _source[_index] == '.') {
      _index++;
      while (_index < _source.length && _isDigit(_source.codeUnitAt(_index))) {
        sawDigit = true;
        _index++;
      }
    }

    if (!sawDigit) {
      _index = start;
      return null;
    }

    if (_index < _source.length && (_source[_index] == 'e' || _source[_index] == 'E')) {
      final expStart = _index;
      _index++;
      if (_index < _source.length && (_source[_index] == '+' || _source[_index] == '-')) {
        _index++;
      }

      var expDigits = false;
      while (_index < _source.length && _isDigit(_source.codeUnitAt(_index))) {
        expDigits = true;
        _index++;
      }

      if (!expDigits) {
        _index = expStart;
      }
    }

    final rawNumber = _source.substring(start, _index);
    final parsed = double.tryParse(rawNumber);
    if (parsed == null) {
      throw const FormatException('Invalid number format');
    }

    final multiplier = _parseEngineeringSuffix();
    return parsed * multiplier;
  }

  double _parseEngineeringSuffix() {
    if (_isAtEnd) {
      return 1;
    }

    final remaining = _source.substring(_index);
    final lower = remaining.toLowerCase();

    if (lower.startsWith('meg')) {
      _index += 3;
      return 1e6;
    }

    final char = _source[_index];
    switch (char) {
      case 'G':
      case 'g':
        _index++;
        return 1e9;
      case 'M':
        _index++;
        return 1e6;
      case 'k':
      case 'K':
        _index++;
        return 1e3;
      case 'm':
        _index++;
        return 1e-3;
      case 'u':
      case 'U':
      case 'µ':
        _index++;
        return 1e-6;
      case 'n':
      case 'N':
        _index++;
        return 1e-9;
      case 'p':
      case 'P':
        _index++;
        return 1e-12;
      default:
        return 1;
    }
  }

  bool _match(String token) {
    if (_isAtEnd) {
      return false;
    }
    if (_source[_index] != token) {
      return false;
    }
    _index++;
    return true;
  }

  bool _isDigit(int codeUnit) => codeUnit >= 48 && codeUnit <= 57;
}
