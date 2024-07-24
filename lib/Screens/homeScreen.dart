import 'package:flutter/material.dart';

import '../Utils/I18n.dart';
import 'ecgChart.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    var defaultLocale = Localizations.localeOf(context);
    I18n.setLocale(Locale(defaultLocale.languageCode));
    return Scaffold(
      backgroundColor: Colors.white,
      body:Stack(
        children: [
          Ecgchart(),
          Align(
            alignment: Alignment.bottomCenter,
              child: IconButton(
                onPressed: (){},
                 icon:Icon(Icons.keyboard_arrow_up_rounded,
                 size: 30,
                 )
              ),
          ),
        ],
      )

    );
  }
}
