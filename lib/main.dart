import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:do_an_quan_ly_cau_long/UI/bookingform.dart';
import 'package:do_an_quan_ly_cau_long/DAO/bookingservice.dart';
import 'package:do_an_quan_ly_cau_long/UI/loginform.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:do_an_quan_ly_cau_long/UI/mainscreen.dart';
import 'DAO/ipconfigsetting.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await Ipconfigsetting.init();
  await initializeDateFormatting('vi', null);
  runApp(BadmintonApp());
}

class BadmintonApp extends StatelessWidget {
  const BadmintonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cầu Lông Pro',
      home: MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
