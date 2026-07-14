bool isValidPhone(String phone) =>
    phone.length == 10 && phone.startsWith('0') && _digitsOnly(phone);

bool isValidPin(String pin) => pin.length == 6 && _digitsOnly(pin);

bool isValidPassword(String pass) => pass.length >= 6;

bool _digitsOnly(String value) => RegExp(r'^\d+$').hasMatch(value);
