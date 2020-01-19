// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math';

import 'package:flutter_clock_helper/model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'constants.dart';

class GradiClock extends StatefulWidget {
  const GradiClock(this.model);

  final ClockModel model;

  @override
  _GradiClockState createState() => _GradiClockState();
}

class _GradiClockState extends State<GradiClock> {
  DateTime _dateTime = DateTime.now();
  Timer _timer;

  @override
  void initState() {
    super.initState();
    widget.model.addListener(_updateModel);
    _updateTime();
    _updateModel();
  }

  @override
  void didUpdateWidget(GradiClock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.model != oldWidget.model) {
      oldWidget.model.removeListener(_updateModel);
      widget.model.addListener(_updateModel);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    widget.model.removeListener(_updateModel);
    widget.model.dispose();
    super.dispose();
  }

  void _updateModel() {
    setState(() {
      // Cause the clock to rebuild when the model changes.
    });
  }

  void _updateTime() {
    setState(() {
      _dateTime = DateTime.now();
      _timer = Timer(
        Duration(seconds: 1) - Duration(milliseconds: _dateTime.millisecond),
        _updateTime,
      );
    });
  }

  ///Method for returning percent of empty space for a given index of 5-minute array
  ///Example:
  ///
  ///App needs empty space for 10-15 minute for creating stripe for that minutes period.
  ///
  ///In that case index will be 3 (0-5 index 0, 5-10 index 1, 10-15 index 2).  ///
  ///If current minutes are equal or greater than 15, method will return 0 (no empty space)
  ///If current minutes are equal or less than 10, method will return 1 (all empty space)
  ///If current minutes are between 10 and 15, method return required percent (e.q. for 12 minute empty space will be 0.6)
  ///
  getEmptyTimePrecent(index) {
    return min(
      1.0,
      max(
        0.0,
        1 - (((_dateTime.minute * 60 + _dateTime.second) - index * 300) / 300),
      ),
    );
  }

  /// Create 12 stripes, one stripe for every 5 minutes.
  /// Stripes have gradient in background, each hour have diferrent gradient.
  /// Stripes shows as much gradient in background as time has passed in current hour.
  _buildStripes(colors) {
    final stripesWidth = MediaQuery.of(context).size.width / 3;
    final stripeWidth = stripesWidth / 12;
    final stripeColorWidth = stripeWidth * 0.70;
    final stripeMarginWidth = stripeWidth * 0.30;
    final stripesHeight = MediaQuery.of(context).size.height / 1.5;

    return Stack(children: <Widget>[
      Container(
        width: stripesWidth,
        height: stripesHeight,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: hoursGradiesnts[_dateTime.hour],
          ),
        ),
      ),
      Row(
        children: <Widget>[
          ...List<int>.generate(12, (i) => i + 1).map((int index) {
            return _buildStripe(stripeColorWidth, stripesHeight, index,
                stripeMarginWidth, colors);
          }).toList(),
        ],
      ),
    ]);
  }

  /// Stripe is formed as Row with two Container.
  /// First Container represent actual Stripe and second container is used as margin between Stripes
  ///
  /// First Container have child representing empty space of Stripe.
  /// If there is no empty space, Container will be empty with fixed width, thus showing background.
  Row _buildStripe(double stripeColorWidth, double stripesHeight, int index,
      double stripeMarginWidth, colors) {
    return Row(
      children: <Widget>[
        Container(
          width: stripeColorWidth,
          height: stripesHeight,
          alignment: Alignment.topCenter,
          //Child representing empty space of Stripe
          child: FractionallySizedBox(
            heightFactor: getEmptyTimePrecent(index - 1),
            child: Container(
              color: Colors.white,
            ),
          ),
        ),
        Container(
            width: stripeMarginWidth,
            height: stripesHeight,
            color: colors[ColorPallete.background]),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).brightness == Brightness.light
        ? lightTheme
        : darkTheme;
    final hour =
        DateFormat(widget.model.is24HourFormat ? 'HH' : 'hh').format(_dateTime);
    final ampmMarker = DateFormat('a').format(_dateTime);
    final fontSize = MediaQuery.of(context).size.width / 5;
    final elemMargin = MediaQuery.of(context).size.width / 40;
    final defaultStyle = TextStyle(
      color: colors[ColorPallete.text],
      fontFamily: 'BebasNeue',
      fontSize: fontSize,
      height: 1.35,
    );
    final boldStyle = defaultStyle.merge(TextStyle(
        fontWeight: FontWeight.bold, fontSize: fontSize / 1.5, height: 1));
    final lightStyle = defaultStyle.merge(TextStyle(
        fontWeight: FontWeight.w100, fontSize: fontSize / 1.5, height: 0.5));

    return Container(
      color: colors[ColorPallete.background],
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(hour, style: defaultStyle),
                if (!widget.model.is24HourFormat)
                  Text(ampmMarker, style: lightStyle),
              ],
            ),
            SizedBox(width: elemMargin),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(":", style: boldStyle),
              ],
            ),
            SizedBox(width: elemMargin),
            _buildStripes(colors)
          ],
        ),
      ),
    );
  }
}
