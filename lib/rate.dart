import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:productive_work/const.dart';

Future<double> getExchangeRate() async {
  const apiUrl = 'https://v6.exchangerate-api.com/v6/0482df8a41ff2efe0dfd56e3/latest/USD';

  final response = await http.get(Uri.parse(apiUrl));

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    final conversionRate = data['conversion_rates']['VND'];
    return conversionRate;
  } else {
    return defaultExchangeRate;
  }
}
