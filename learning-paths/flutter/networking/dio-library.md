# Intro

[Dio](https://pub.dev/packages/dio) is a powerful HTTP client for Dart. It has support:
- interceptors
- global configuration
- FormData
- request cancellation
- file downloading
- timeout

# Instructions

## Setup 

1. Add the Dio package to your `pubspec.yaml` file:

```yaml
dependencies:
  dio: ^4.0.0
```

2. Use JSON serialization and generate the factory methods automatically:
- [json_serializable](https://pub.dev/packages/json_serializable)
- [json_annotation](https://pub.dev/packages/json_annotation)
- [build_runner](https://pub.dev/packages/build_runner)

3. Add them to your `pubspec.yaml` file:

```yaml
dependencies:
  json_annotation: ^4.0.1

dev_dependencies:
  json_serializable: ^4.1.3
  build_runner: ^2.0.4
```

4. Defining a model class → a simple class for storing single user data with json-mapping capability:

```dart
// user.dart
import 'package:json_annotation/json_annotation.dart';

import 'data.dart';

part 'user.g.dart';

@JsonSerializable()
class User {
  User({
    required this.data,
  });

  Data data;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);
}

// data.dart
import 'package:json_annotation/json_annotation.dart';

part 'data.g.dart';

@JsonSerializable()
class Data {
  Data({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.avatar,
  });

  int id;
  String email;
  @JsonKey(name: 'first_name')
  String firstName;
  @JsonKey(name: 'last_name')
  String lastName;
  String avatar;

  factory Data.fromJson(Map<String, dynamic> json) => _$DataFromJson(json);
  Map<String, dynamic> toJson() => _$DataToJson(this);
}
```

5. Initialize Dio and request examples

Get request - Get user:
```dart
// dio_client.dart
import 'package:dio/dio.dart';

class DioClient {
  final Dio _dio = Dio();

  final _baseUrl = 'https://reqres.in/api';

  // Get request - Get User
  Future<User?> getUser({required String id}) async {
  User? user;
  try {
    Response userData = await _dio.get(_baseUrl + '/users/$id');
    print('User Info: ${userData.data}');
    user = User.fromJson(userData.data);
  } on DioError catch (e) {
    // The request was made and the server responded with a status code
    // that falls out of the range of 2xx and is also not 304.
    if (e.response != null) {
      print('Dio error!');
      print('STATUS: ${e.response?.statusCode}');
      print('DATA: ${e.response?.data}');
      print('HEADERS: ${e.response?.headers}');
    } else {
      // Error due to setting up or sending the request
      print('Error sending request!');
      print(e.message);
    }
  }
  return user;
}
}
```

Then show user on the Home page:

```dart
class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final DioClient _client = DioClient();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Info'),
      ),
      body: Center(
        child: FutureBuilder<User?>(
          future: _client.getUser(id: '1'),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              User? userInfo = snapshot.data;
              if (userInfo != null) {
                Data userData = userInfo.data;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.network(userData.avatar),
                    SizedBox(height: 8.0),
                    Text(
                      '${userInfo.data.firstName} ${userInfo.data.lastName}',
                      style: TextStyle(fontSize: 16.0),
                    ),
                    Text(
                      userData.email,
                      style: TextStyle(fontSize: 16.0),
                    ),
                  ],
                );
              }
            }
            return CircularProgressIndicator();
          },
        ),
      ),
    );
  }
}
```

## Defining your base

Instead of passing the endpoint with `baseUrl` every time, you can just define it inside `BaseOptions` and pass it once:

```dart
final Dio _dio = Dio(
  BaseOptions(
    baseUrl: 'https://reqres.in/api',
    connectTimeout: 5000,
    receiveTimeout: 3000,
  ),
);
```

## Uploading files

upload files to a server using `FormData` and Dio. 

```dart
tring imagePath;

FormData formData = FormData.fromMap({
  "image": await MultipartFile.fromFile(
    imagePath,
    filename: "upload.jpeg",
  ),
});

Response response = await _dio.post(
  '/search',
  data: formData,
  onSendProgress: (int sent, int total) {
    print('$sent $total');
  },
);
```

## Interceptors

You can intercept Dio requests, responses, and errors before they are handled by using `then` or `catchError`. For example of a simple interceptor for logging different types of requests:

```dart
import 'package:dio/dio.dart';

class Logging extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    print('REQUEST[${options.method}] => PATH: ${options.path}');
    return super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    print(
      'RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}',
    );
    return super.onResponse(response, handler);
  }

  @override
  void onError(DioError err, ErrorInterceptorHandler handler) {
    print(
      'ERROR[${err.response?.statusCode}] => PATH: ${err.requestOptions.path}',
    );
    return super.onError(err, handler);
  }
}

final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://reqres.in/api',
      connectTimeout: 5000,
      receiveTimeout: 3000,
    ),
  )..interceptors.add(Logging());
```

## Resources

Advanced customizations: https://pub.dev/packages/dio
