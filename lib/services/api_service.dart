//Only responsible for making HTTP requests and delivery.


import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';

class ApiService {


  //"Create a function called post.
  // It receives a URL and a Dart Map. Convert the URL into a Uri. Convert the Map into JSON.
  // Send a POST request. Wait for the server's response. Return that response."

   Future<http.Response> post( String url,Map<String, dynamic> body,)async{
     final response = await http.post( Uri.parse(url),
       headers: {
         "Content-Type": "application/json",
       },
       body: jsonEncode(body),
     );
     return response;
   }
   // Future<http.Response> is return type of post(). In Future comes http.Response
  // url and body is parameter of the post
  // Map<String, dynamic> is a datatype that says the body contains mapping in string: dynamic data type format
  // async allows a function to use await
  // response is a variable that stores the response of the http.post function . http.post() is the funtion in http library/package
  // Right now http.post is taking 3 parameter -> url, headers and body
  // response has -> statusCode, headers and body


   //=====================
   // MULTIPART POST
  //=====================
  Future<http.StreamedResponse> multipartPost(
      String url,
      Map<String, String> fields,
      File? image,
      ) async {
    final request = http.MultipartRequest(
      "POST",
      Uri.parse(url),
    );

    request.fields.addAll(fields);

    if (image != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          "profile_photo", // Must match your Django serializer field
          image.path,
        ),
      );
    }
    return await request.send();
  }
}
