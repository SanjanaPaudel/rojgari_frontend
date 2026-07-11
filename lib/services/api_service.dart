//Only responsible for making HTTP requests and delivery.


import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';

import 'package:rojgari_frontend_one/services/storage_service.dart';
import '../core/constants/api_urls.dart';

class ApiService {
  static const String sessionExpired = "Session Expired. Please login again.";

  Future<String?> _getValidAccessToken() async {
    String? token = await StorageService.getAccessToken();

    if (token == null) {
      return null;
    }

    return token;
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _getValidAccessToken();

    return {
      "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    };
  }

  Future<void> _logoutUser() async {
    await StorageService.clearTokens();
    throw Exception(ApiService.sessionExpired);
  }


  //"Create a function called post.
  // It receives a URL and a Dart Map. Convert the URL into a Uri. Convert the Map into JSON.
  // Send a POST request. Wait for the server's response. Return that response."

  Future<http.Response> post(
      String url,
      Map<String, dynamic> body,
      ) async {

    String? token = await StorageService.getAccessToken();

    http.Response response = await http.post(
      Uri.parse(url),
      headers: await _getHeaders(),
      body: jsonEncode(body),
    );

    if (response.statusCode == 401) {

      final refreshed = await _refreshAccessToken();
      if (!refreshed) {
        await _logoutUser();
      }

      response = await http.post(
        Uri.parse(url),
        headers: await _getHeaders(),
        body: jsonEncode(body),
      );
    }
    return response;
  }
   // Future<http.Response> is return type of post(). In Future comes http.Response
  // url and body is parameter of the post
  // Map<String, dynamic> is a datatype that says the body contains mapping in string: dynamic data type format
  // async allows a function to use await
  // response is a variable that stores the response of the http.post function . http.post() is the funtion in http library/package
  // Right now http.post is taking 3 parameter -> url, headers and body
  // response has -> statusCode, headers and body


  Future<http.Response> get(String url) async {
    String? token = await StorageService.getAccessToken();
    http.Response response = await http.get(
      Uri.parse(url),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 401) {
      final refreshed = await _refreshAccessToken();
      if (!refreshed) {
        await _logoutUser();
      }

      response = await http.get(
        Uri.parse(url),
        headers: await _getHeaders(),
      );
    }
    return response;
  }


   //=====================
   // MULTIPART POST
  //=====================
  Future<http.StreamedResponse> multipartPost(
      String url,
      Map<String, String> fields,
      File? image,
      ) async {

    http.MultipartRequest request = http.MultipartRequest(
      "POST",
      Uri.parse(url),
    );

    final token = await _getValidAccessToken();

    if (token != null) {
      request.headers["Authorization"] = "Bearer $token";
    }

    request.fields.addAll(fields);

    if (image != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          "profile_photo",
          image.path,
        ),
      );
    }

    http.StreamedResponse response = await request.send();

    if (response.statusCode == 401) {

      final refreshed = await _refreshAccessToken();

      if (!refreshed) {
        await _logoutUser();
      }

      // MultipartRequest cannot be reused.
      request = http.MultipartRequest(
        "POST",
        Uri.parse(url),
      );

      final newToken = await _getValidAccessToken();

      if (newToken != null) {
        request.headers["Authorization"] = "Bearer $newToken";
      }

      request.fields.addAll(fields);

      if (image != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            "profile_photo",
            image.path,
          ),
        );
      }

      response = await request.send();
    }

    return response;
  }

   Future<bool> _refreshAccessToken() async {
     final refreshToken = await StorageService.getRefreshToken();

     if (refreshToken == null) {
       return false;
     }

     final response = await http.post(
       Uri.parse(ApiUrls.refresh),
       headers: {
         "Content-Type": "application/json",
       },
       body: jsonEncode({
         "refresh": refreshToken,
       }),
     );

     if (response.statusCode == 200) {
       final data = jsonDecode(response.body);

       await StorageService.saveAccessToken(
         data["access"],
       );

       return true;
     }

     await StorageService.clearTokens();
     return false;
   }
}
