import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

final String baseApiUrl = kIsWeb
    ? web.window.location.href
    : String.fromEnvironment(
        'api_base_url',
        defaultValue: 'http://zeldas-macbook-pro.local:3000',
      );
const String appName = "Echoes";

const bool enableLiquidGlassBar = false;

const String currencyName = "Echo";
const String currencyNamePlural = "Echoes";
const String currencySymbol = "E";
const int currencyDecimals = 2;
