import 'dart:async';
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';

import 'src/access_token.dart';
import 'src/login_result.dart';
export 'src/login_result.dart';
export 'src/access_token.dart';

class FacebookAuth {
  static const MethodChannel _channel =
      const MethodChannel('flutter_facebook_auth');

  /// [permissions] permissions like ["email","public_profile"]
  Future<LoginResult> login(
      {List<String> permissions = const ['email', 'public_profile']}) async {
    final result =
        await _channel.invokeMethod("login", {"permissions": permissions});

    return LoginResult.fromJson(
        Map<String, dynamic>.from(result)); // accessToken
  }

  /// [fields] string of fileds like birthday,email,hometown
  Future<dynamic> getUserData({String fields = "name,email,picture"}) async {
    final result =
        await _channel.invokeMethod("getUserData", {"fields": fields});
    return Platform.isAndroid
        ? jsonDecode(result)
        : Map<String, dynamic>.from(result); //null  or dynamic data
  }

  /// Sign Out
  Future<dynamic> logOut() async {
    await _channel.invokeMethod("logOut");
  }

  /// if the user is logged return one accessToken
  Future<AccessToken> isLogged() async {
    final result = await _channel.invokeMethod("isLogged");
    return AccessToken.fromJson(Map<String, dynamic>.from(result));
  }

  /// check what permisions was granted or declined while login process
  Future<dynamic> permissionsStatus(String token) async {
    final url = "https://graph.facebook.com/me/permissions?access_token=$token";

    final res = await http.get(url);
    final parsed = jsonDecode(res.body);

    var granted = [];
    var declined = [];

    if (res.statusCode == 200) {
      for (final item in parsed['data'] as List) {
        final permission = item['permission'];
        final status = item['status'];
        if (status == 'granted') {
          granted.add(permission);
        } else {
          declined.add(permission);
        }
      }
      return {"granted": granted, "declined": declined};
    }
    throw new PlatformException(
        code: "500", message: parsed['error']['message']);
  }
}
