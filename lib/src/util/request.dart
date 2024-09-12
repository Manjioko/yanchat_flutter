import 'package:dio/dio.dart';
import 'package:yanchat01/src/util/share.dart';

class Request {
  // 创建单例对象
  static final Request _instance = Request._internal();

  // 工厂构造函数返回单例
  factory Request() => _instance;

  // 直接访问单例的实例
  static Request get instance => _instance;

  // Dio 实例
  late Dio dio;

  // 私有的命名构造函数，配置 Dio
  Request._internal() {
    dio = Dio(BaseOptions(
      // baseUrl: 'https://api.example.com',  // 设置基础 URL
      connectTimeout: const Duration(seconds: 5),  // 连接超时
      receiveTimeout: const Duration(seconds: 3),  // 接收超时
      // headers: {
      //   'Content-Type': 'application/json',  // 设置默认请求头
      //   'Authorization': 'Bearer your_token_here', // 例如设置全局的 Authorization 头
      // },
    ));

    // 你可以添加更多的配置，例如拦截器等
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        // 在请求发送前做一些事情，例如添加更多的 headers
        Share.instance.getString('refreshToken').then((refreshToken) {
          if (refreshToken != null) {
            options.headers['Authorization'] = 'Bearer $refreshToken';
            return handler.next(options);
          } else {
            return handler.next(options);
          }
        });
      },
      onResponse: (response, handler) {
        // 对响应做一些预处理
        return handler.next(response);
      },
      onError: (DioException e, handler) {
        // 处理错误
        return handler.next(e);
      },
    ));
  }
}