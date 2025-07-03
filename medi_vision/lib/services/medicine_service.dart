// lib/services/medicine_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class MedicineService {
  static const String _defaultBaseUrl = 'http://10.1.31.11:8000';
  static String _baseUrl = _defaultBaseUrl;
  static const Duration _timeoutDuration = Duration(seconds: 15);

  // Configure the base URL (optional)
  static void configure({String? baseUrl}) {
    if (baseUrl != null) {
      _baseUrl = baseUrl;
      if (kDebugMode) {
        print('MipconfigedicineService configured with URL: $_baseUrl');
      }
    }
  }

  Future<Map<String, dynamic>> searchMedicine(String medicineName) async {
    if (medicineName.isEmpty) {
      throw ArgumentError('Medicine name cannot be empty');
    }

    final stopwatch = Stopwatch()..start();
    try {
      if (kDebugMode) {
        print('🔍 Searching for medicine: $medicineName');
        print('🌐 API Endpoint: $_baseUrl/medicine-info');
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/medicine-info'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'medicine_name': medicineName,
          'get_all': false,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      ).timeout(_timeoutDuration);

      if (kDebugMode) {
        print('⏱️ Response time: ${stopwatch.elapsedMilliseconds}ms');
        print('🔄 Status Code: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (kDebugMode) {
          print('✅ Received data: $data');
        }
        return data;
      } else {
        throw _handleErrorResponse(response);
      }
    } on http.ClientException catch (e) {
      throw _handleNetworkError(e);
    } on TimeoutException catch (e) {
      throw _handleTimeoutError(e);
    } catch (e) {
      throw _handleGenericError(e);
    } finally {
      stopwatch.stop();
    }
  }

  Exception _handleErrorResponse(http.Response response) {
    final statusCode = response.statusCode;
    String message;

    try {
      final errorBody = jsonDecode(response.body);
      message = errorBody['message'] ?? 'Unknown error occurred';
    } catch (_) {
      message = 'Failed to decode error response';
    }

    if (kDebugMode) {
      print('❌ Error $statusCode: $message');
    }

    switch (statusCode) {
      case 400:
        return BadRequestException(message);
      case 401:
        return UnauthorizedException(message);
      case 404:
        return NotFoundException(message);
      case 500:
        return ServerException(message);
      default:
        return ApiException('API request failed with status $statusCode: $message');
    }
  }

  Exception _handleNetworkError(http.ClientException e) {
    if (kDebugMode) {
      print('🌐 Network error: ${e.message}');
    }
    return NetworkException('Could not connect to the server. Please check your internet connection.');
  }

  Exception _handleTimeoutError(TimeoutException e) {
    if (kDebugMode) {
      print('⏱️ Request timeout');
    }
    return TimeoutException('Request timed out after ${_timeoutDuration.inSeconds} seconds');
  }

  Exception _handleGenericError(dynamic e) {
    if (kDebugMode) {
      print('❗ Unexpected error: $e');
    }
    return ApiException('An unexpected error occurred: ${e.toString()}');
  }
}

// Custom exceptions
class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}

class NetworkException extends ApiException {
  NetworkException(super.message);
}

class BadRequestException extends ApiException {
  BadRequestException(super.message);
}

class UnauthorizedException extends ApiException {
  UnauthorizedException(super.message);
}

class NotFoundException extends ApiException {
  NotFoundException(super.message);
}

class ServerException extends ApiException {
  ServerException(super.message);
}