import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:productive_work/const.dart';
import 'package:productive_work/rate.dart';
import 'package:productive_work/setting.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:animated_digit/animated_digit.dart';

double exchangeRate = defaultExchangeRate;
var formatter = NumberFormat.currency(locale: "vi_VN", symbol: "₫");
late SharedPreferences prefs;
int lastTimeMilisecond = DateTime.now().millisecondsSinceEpoch;
bool stop = true;
double ratePerHour = defaultRate;
int miliSecondWorkded = 0;
double amountWorked = 0;

void main() {
  runApp(const ProductiveWork());
}

class ProductiveWork extends StatelessWidget {
  const ProductiveWork({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, primaryColor: Colors.white, brightness: Brightness.dark),
      home: const App(),
    );
  }
}

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  Timer? timer;
  int lastTimeInteract = DateTime.now().millisecondsSinceEpoch;

  @override
  void initState() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive, overlays: []);
    SharedPreferences.getInstance().then((value) {
      prefs = value;
      init();
    });
    super.initState();
    Future.delayed(const Duration(seconds: 1), () {
      WakelockPlus.enable();
      SharedPreferences.getInstance().then((value) {
        prefs = value;
        set();
      });
      getExRate();
      timer?.cancel();
      timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
        set();
      });
      Timer.periodic(const Duration(hours: 1), (timer) {
        getExRate();
      });
    });
  }

  int get amount => amountWorked.round();
  String get counter => formatter.format(amount);
  bool get showActions => DateTime.now().millisecondsSinceEpoch - lastTimeInteract < 3000;

  void init() {
    var timeWorkedSecond = prefs.getInt('timeWorkedSecond') ?? 0;
    miliSecondWorkded = timeWorkedSecond * 1000;
    var savedRate = prefs.getDouble('exchangeRate') ?? defaultExchangeRate;
    exchangeRate = savedRate;
    var ratePerHourSaved = prefs.getDouble('ratePerHour') ?? defaultRate;
    ratePerHour = ratePerHourSaved;
    var amountWorkedSaved = prefs.getDouble('amountWorked') ?? 0;
    amountWorked = amountWorkedSaved;
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      setState(() {});
    });
  }

  void getExRate() {
    getExchangeRate().then((value) {
      prefs.setDouble('exchangeRate', value);
      exchangeRate = value;
    });
  }

  void set() {
    if (!stop) {
      setState(() {
        final nowMiliSecond = DateTime.now().millisecondsSinceEpoch;
        final diff = nowMiliSecond - lastTimeMilisecond;
        var generatedMoney = ratePerHour * diff / 3600000 * exchangeRate;
        miliSecondWorkded += diff;
        amountWorked += generatedMoney;
        prefs.setInt('timeWorkedSecond', (miliSecondWorkded / 1000).round());
        prefs.setDouble('amountWorked', amountWorked);
        lastTimeMilisecond = nowMiliSecond;
      });
    }
  }

  int get durationOfSession {
    final DateTime now = DateTime.now();
    // get current seconds counter of 10 mins
    int secondsSinceLastTenMinutes = (now.minute % 10) * 60 + now.second;
    return secondsSinceLastTenMinutes;
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          lastTimeInteract = DateTime.now().millisecondsSinceEpoch;
        },
        child: SafeArea(
          child: Stack(
            children: [
              if (showActions)
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: IconButton(
                      icon: const Icon(
                        Icons.settings,
                        color: Colors.white38,
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const Settings(),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              Center(
                child: Padding(
                  padding: EdgeInsets.only(bottom: MediaQuery.of(context).size.height * .05),
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.85,
                    child: GestureDetector(
                      onDoubleTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const Settings(),
                          ),
                        );
                      },
                      child: CircularPercentIndicator(
                        curve: Curves.ease,
                        circularStrokeCap: CircularStrokeCap.round,
                        radius: MediaQuery.of(context).size.width * 0.425,
                        lineWidth: 14.0,
                        percent: durationOfSession / 600,
                        center: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 50),
                            AnimatedDigitWidget(
                              separateSymbol: ',',
                              separateLength: 3,
                              enableSeparator: true,
                              value: amount,
                              suffix: ' ₫',
                              textStyle: const TextStyle(
                                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 30.0),
                            ),
                            const SizedBox(height: 30),
                            Builder(builder: (context) {
                              final hour = (miliSecondWorkded / 3600000).floor();
                              final min = ((miliSecondWorkded - hour * 3600000) ~/ 60000).floor();
                              return Text(
                                  true
                                      ? '${hour}h ${min.toString().padLeft(2, '0')}m'
                                      : '',
                                  style: const TextStyle(color: Colors.white30, fontSize: 15));
                            })
                          ],
                        ),
                        progressColor: Colors.white,
                        backgroundColor: Colors.white24,
                      ),
                    ),
                  ),
                ),
              ),
              if (showActions)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: MediaQuery.of(context).size.height * .10),
                    child: IconButton(
                      color: Colors.white38,
                      icon: Icon(
                        stop ? Icons.play_arrow_rounded : Icons.pause_rounded,
                        size: 80,
                      ),
                      onPressed: () {
                        setState(() {
                          stop = !stop;
                        });
                      },
                    ),
                  ),
                )
            ],
          ),
        ),
      ),
    );
  }
}
