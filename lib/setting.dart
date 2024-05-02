import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:productive_work/const.dart';
import 'package:productive_work/main.dart';
import 'package:productive_work/rate.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  double rate = ratePerHour;
  double hour = miliSecondWorkded / 1000 / 60 / 60;
  double amount = amountWorked;
  double exRate = exchangeRate;
  TextEditingController rateController = TextEditingController();
  TextEditingController hourController = TextEditingController();
  TextEditingController amountController = TextEditingController();
  TextEditingController exchangeRateController = TextEditingController();

  @override
  void initState() {
    rateController.text = rate.toString();
    hourController.text = hour.toStringAsFixed(2);
    amountController.text = amount.round().toString();
    exchangeRateController.text = exRate.toString();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Settings',
          style: TextStyle(fontSize: 15),
        ),
        leadingWidth: 40,
        leading: IconButton(
          visualDensity: VisualDensity.compact,
          icon: const Icon(CupertinoIcons.back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: const Text(
                'Save',
                style: TextStyle(fontSize: 15),
              ),
              onPressed: () {
                prefs.setDouble('rate', rate);
                prefs.setInt('miliSecondWorkded', (hour * 60 * 60 * 1000).toInt());
                prefs.setDouble('amount', amount);
                prefs.setDouble('exchangeRate', exRate);
                ratePerHour = rate;
                miliSecondWorkded = (hour * 60 * 60 * 1000).toInt();
                amountWorked = amount;
                exchangeRate = exRate;
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildItem(
                'Rate per hr',
                '\$',
                inputType: TextInputType.number,
                onChanged: (p0) {
                  setState(() {
                    rate = double.tryParse(p0) ?? rate;
                  });
                },
                controller: rateController,
                sub: '\$/hour',
              ),
              const SizedBox(height: 20),
              _buildItem(
                'Hour worked',
                'hr',
                inputType: TextInputType.number,
                onChanged: (p0) {
                  setState(() {
                    hour = double.tryParse(p0) ?? hour;
                  });
                },
                controller: hourController,
              ),
              const SizedBox(height: 20),
              _buildItem(
                'Amount earned',
                ' ₫',
                inputType: TextInputType.number,
                onChanged: (p0) {
                  setState(() {
                    amount = double.tryParse(p0) ?? amount;
                  });
                },
                controller: amountController,
                sub: 'VNĐ',
              ),
              const SizedBox(height: 20),
              _buildItem(
                'Exchange rate',
                ' ₫/\$',
                inputType: TextInputType.number,
                onChanged: (p0) {
                  setState(() {
                    exRate = double.tryParse(p0) ?? exRate;
                  });
                },
                controller: exchangeRateController,
                sub: '\$ to VNĐ',
              ),
              const SizedBox(height: 20),
              ButtonBar(
                alignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      final confirm = await showCupertinoDialog(
                          context: context,
                          builder: (context) {
                            return CupertinoAlertDialog(
                              title: const Text('Reset to Default'),
                              content: const Text('Are you sure you want to reset?'),
                              actions: [
                                CupertinoDialogAction(
                                  child: const Text('Cancel'),
                                  onPressed: () {
                                    Navigator.pop(context, false);
                                  },
                                ),
                                CupertinoDialogAction(
                                  child: const Text('Reset'),
                                  onPressed: () {
                                    Navigator.pop(context, true);
                                  },
                                ),
                              ],
                            );
                          });
                      if (confirm != true) return;
                      prefs.clear();
                      setState(() {
                        rateController.text = rate.toString();
                        hourController.text = hour.toStringAsFixed(2);
                        amountController.text = amount.toString();
                        prefs.setDouble('rate', rate);
                        prefs.setInt('miliSecondWorkded', (hour * 60 * 60 * 1000).toInt());
                        prefs.setDouble('amount', amount);
                        exchangeRate = defaultExchangeRate;
                        amountWorked = 0;
                        miliSecondWorkded = 0;
                        ratePerHour = defaultRate;
                        stop = true;
                      });
                      Navigator.pop(context, true);

                      getExchangeRate().then((value) {
                        prefs.setDouble('exchangeRate', value);
                        exchangeRate = value;
                        exchangeRateController.text = value.toString();
                      });
                    },
                    child: const Text('Reset to Default'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItem(String title, String suffix,
      {TextInputType? inputType,
      required Function(String) onChanged,
      required TextEditingController controller,
      String? sub}) {
    return Row(
      children: [
        Expanded(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title),
            if (sub != null) Text(sub, style: const TextStyle(fontSize: 11, color: Colors.white30))
          ],
        )),
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: inputType,
            onChanged: onChanged,
            textAlign: TextAlign.right,
            decoration: InputDecoration(
              hintStyle: const TextStyle(fontSize: 14),
              isDense: true,
              border: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.white10.withOpacity(0.01)),
              ),
              focusColor: Colors.white24,
              contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              suffixText: ' $suffix',
              suffixStyle: const TextStyle(color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
