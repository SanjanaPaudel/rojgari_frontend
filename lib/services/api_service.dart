//Only responsible for making HTTP requests and delivery.

// import 'package:dio/dio.dart';
//
// class ApiService {
//   static final Dio dio = Dio(
//     BaseOptions(
//       connectTimeout: const Duration(seconds: 15),
//       receiveTimeout: const Duration(seconds: 15),
//       headers: {
//         "Content-Type": "application/json",
//       },
//     ),
//   );
// }

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class ApiService {
  Future<Map<String, dynamic>> multipartPost({
    required String url,
    required Map<String, String> fields,
    File? image,
    String imageField = "profile_photo",
  }) async {
    try {
      final request = http.MultipartRequest(
        "POST",
        Uri.parse(url),
      );

      request.fields.addAll(fields);

      if (image != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            imageField,
            image.path,
          ),
        );
      }

      final streamedResponse = await request.send();

      final response = await http.Response.fromStream(streamedResponse);

      return {
        "statusCode": response.statusCode,
        "body": jsonDecode(response.body),
      };
    } catch (e) {
      return {
        "statusCode": 500,
        "body": {
          "message": e.toString(),
        },
      };
    }
  }
}