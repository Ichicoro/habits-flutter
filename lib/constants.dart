import 'package:flutter/foundation.dart';
import "package:universal_html/html.dart" as web;

final String baseApiUrl = kIsWeb
    ? web.window.location.href
    : String.fromEnvironment(
        'api_base_url',
        defaultValue: 'http://zeldas-macbook-pro.local:3000',
      );
const String appName = "Echoes";

const bool enableLiquidGlassBar = true;

const String currencyName = "Echo";
const String currencyNamePlural = "Echoes";
const String currencySymbol = "E";
const int currencyDecimals = 2;
