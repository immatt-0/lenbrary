import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiService {
  // Status translations for Romanian values
  static const Map<String, String> statusTranslations = {
    'IN_ASTEPTARE': 'În așteptare',
    'APROBAT': 'Aprobat',
    'GATA_RIDICARE': 'Gata de ridicare',
    'IMPRUMUTAT': 'Împrumutat',
    'RETURNAT': 'Returnat',
    'INTARZIAT': 'Întârziat',
    'RESPINS': 'Respins',
  };

  // Base URL of your Django backend - update this for your testing environment
  // For emulators:
  // static const String baseUrl = 'http://10.0.2.2:8000';      // Android emulator
  static const String baseUrl =
      'http://localhost:8000'; // Windows/Web/iOS simulator

  // For physical devices, use your computer's actual IP address:
  // static const String baseUrl = 'http://192.168.1.100:8000'; // Replace with your actual IP

  // Endpoints
  static const String registerEndpoint = '/book-library/register';
  static const String loginEndpoint = '/api/token/';
  static const String refreshTokenEndpoint = '/api/token/refresh/';

  // Exam Model Endpoints
  static const String examModelsEndpoint = '/book-library/exam-models/';
  static const String createExamModelEndpoint = '/book-library/exam-models/create/';
  static String deleteExamModelEndpoint(int id) => '/book-library/exam-models/$id/delete/';

  // Register a new user
  static Future<Map<String, dynamic>> register({
    required String password,
    required String email,
    required String firstName,
    required String lastName,
    String? schoolType,
    String? department,
    String? studentClass,
    bool isTeacher = false,
    String? invitationCode,
    String?
        username, // Optional now - will be generated from email if not provided
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl$registerEndpoint'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        if (username != null) 'username': username, // Only include if provided
        'password': password,
        'email': email,
        'first_name': firstName,
        'last_name': lastName,
        if (schoolType != null) 'school_type': schoolType,
        if (department != null) 'department': department,
        if (studentClass != null) 'student_class': studentClass,
        'is_teacher': isTeacher,
        if (isTeacher && invitationCode != null) 'invitation_code': invitationCode,
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      // Extract just the error message from the response body
      try {
        final errorData = jsonDecode(response.body);
        if (errorData is Map<String, dynamic>) {
          // Extract invitation_code error if it exists
          if (errorData.containsKey('invitation_code')) {
            final invitationError = errorData['invitation_code'];
            if (invitationError is List && invitationError.isNotEmpty) {
              throw invitationError.first.toString();
            } else if (invitationError is String) {
              throw invitationError;
            }
          }
          // Extract other field errors
          for (final entry in errorData.entries) {
            if (entry.value is List && (entry.value as List).isNotEmpty) {
              throw (entry.value as List).first.toString();
            } else if (entry.value is String) {
              throw entry.value;
            }
          }
        }
        // Fallback to the raw response if we can't parse it properly
        throw response.body;
      } catch (e) {
        // If parsing fails, throw the original response
        throw response.body;
      }
    }
  }

  // Login user and get token
  // You can login with any of:
  // - Full email: firstname.lastname@nlenau.ro
  // - Username part: firstname.lastname
  // - Custom username (if manually set during registration)
  static Future<Map<String, dynamic>> login({
    required String usernameOrEmail,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl$loginEndpoint'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': usernameOrEmail,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // Save tokens to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', data['access']);
      await prefs.setString('refresh_token', data['refresh']);

      return data;
    } else {
      // Decode error as UTF-8 for proper diacritics
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(decoded['detail'] ?? 'Failed to login');
    }
  }

  // Get the access token from SharedPreferences
  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  // Get the refresh token from SharedPreferences
  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('refresh_token');
  }

  // Clear tokens (for logout)
  static Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
  }

  // Refresh the access token using the refresh token
  static Future<bool> refreshToken() async {
    final refreshToken = await getRefreshToken();

    if (refreshToken == null) {
      return false;
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl$refreshTokenEndpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'refresh': refreshToken,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', data['access']);
        return true;
      }
    } catch (e) {
      print('Error refreshing token: $e');
    }

    return false;
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null;
  }

  // Get current user information
  static Future<Map<String, dynamic>> getUserInfo() async {
    final token = await getAccessToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    try {
      print('Fetching user info with token: $token');
      final response = await http.get(
        Uri.parse('$baseUrl/book-library/user-info'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('User info response: ${response.statusCode} - ${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('User info data: $data');
        return data;
      } else {
        throw Exception('Failed to get user info: ${response.body}');
      }
    } catch (e) {
      print('Exception in getUserInfo: $e');
      throw Exception('Error fetching user info: $e');
    }
  }

  // Upload book thumbnail
  static Future<String> uploadThumbnail() async {
    final token = await getAccessToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    // For simplicity in this example, we'll simulate a successful upload
    // In a real app, you'd use a package like image_picker to get an image file
    // and then upload it with FormData

    /* 
    Example of real implementation:
    
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/book-library/thumbnails'),
    );
    
    request.headers.addAll({
      'Authorization': 'Bearer $token',
    });
    
    request.files.add(await http.MultipartFile.fromPath(
      'thumbnail',
      imagePath,
    ));
    
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    
    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return data['thumbnail_url'];
    } else {
      throw Exception('Failed to upload thumbnail');
    }
    */

    // Simulated response for now
    return 'https://via.placeholder.com/150x200?text=Book+Cover';
  }

  // Add new book to library
  static Future<Map<String, dynamic>> addBook({
    required String name,
    required String author,
    required int inventory,
    required int stock,
    String? description,
    String? category,
    int? publicationYear,
    String? thumbnailUrl,
  }) async {
    final token = await getAccessToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/book-library/book'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'name': name,
        'author': author,
        'inventory': inventory,
        'stock': stock,
        'description': description,
        'category': category,
        'publication_year': publicationYear,
        'thumbnail_url': thumbnailUrl,
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception(response.body);
    }
  }

  // Get all books
  static Future<List<dynamic>> getBooks({String? search}) async {
    final queryParams = <String, String>{};
    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }

    final token = await getAccessToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final uri = Uri.parse('$baseUrl/book-library/books').replace(
      queryParameters: queryParams,
    );

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get books');
    }
  }

  // Get user's book requests
  static Future<List<dynamic>> getMyRequests() async {
    final token = await getAccessToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/book-library/my-books'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get book requests');
    }
  }

  // Helper method for making authenticated requests
  static Future<dynamic> _makeRequest(String method, String endpoint,
      {Map<String, dynamic>? body, Map<String, String>? queryParams}) async {
    final token = await getAccessToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final headers = {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json; charset=UTF-8',
    };

    final uri = Uri.parse('$baseUrl$endpoint');
    if (queryParams != null) {
      final queryUri = uri.replace(queryParameters: queryParams);
      http.Response response = await http.get(queryUri, headers: headers);
      return response.body;
    }

    http.Response response;

    try {
      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(uri, headers: headers);
          break;
        case 'POST':
          response = await http.post(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'PUT':
          response = await http.put(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'DELETE':
          response = await http.delete(uri, headers: headers);
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }

      // Ensure proper UTF-8 decoding
      final decodedBody = utf8.decode(response.bodyBytes);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (decodedBody.isEmpty) return null;
        return jsonDecode(decodedBody);
      } else {
        throw Exception('API Error: ${response.statusCode} - $decodedBody');
      }
    } catch (e) {
      debugPrint('API Request Error: $e');
      rethrow;
    }
  }

  // Update the original requestBook method to create a notification
  static Future<Map<String, dynamic>> requestBook(
      {required int bookId, int loanDurationDays = 14}) async {
    final response = await _makeRequest(
      'POST',
      '/book-library/request-book',
      body: {
        'book_id': bookId,
        'loan_duration_days': loanDurationDays,
      },
    );
    return response;
  }

  // Update the original returnBook method to create a notification
  static Future<Map<String, dynamic>> returnBook(
      {required int borrowingId}) async {
    final response = await _makeRequest(
      'POST',
      '/book-library/return-book/$borrowingId',
    );
    return response;
  }

  // Update the original getNotifications method
  static Future<List<dynamic>> getNotifications() async {
    final response = await _makeRequest(
      'GET',
      '/book-library/notifications',
    );
    return response;
  }

  // Update the original markNotificationRead method
  static Future<bool> markNotificationRead(int notificationId) async {
    await _makeRequest(
      'POST',
      '/book-library/mark-notification-read/$notificationId',
    );
    return true;
  }

  // Mark all notifications as read
  static Future<bool> markAllNotificationsRead() async {
    await _makeRequest(
      'POST',
      '/book-library/mark-all-notifications-read',
    );
    return true;
  }

  // Get all pending book requests (for librarians)
  static Future<List<dynamic>> getPendingRequests() async {
    final token = await getAccessToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/book-library/pending-requests'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get pending requests: ${response.body}');
    }
  }

  // Get all active loans (for librarians)
  static Future<List<dynamic>> getActiveLoans() async {
    final token = await getAccessToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/book-library/active-loans'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get active loans: ${response.body}');
    }
  }

  // Get loan history (for librarians)
  static Future<List<dynamic>> getLoanHistory() async {
    final token = await getAccessToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/book-library/loan-history'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get loan history');
    }
  }

  // Approve a book request (librarian)
  static Future<Map<String, dynamic>> approveRequest({
    required int borrowingId,
    String? librarianMessage,
  }) async {
    final token = await getAccessToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final requestBody = <String, dynamic>{};
    if (librarianMessage != null) {
      requestBody['librarian_message'] = librarianMessage;
    }

    final response = await http.post(
      Uri.parse('$baseUrl/book-library/approve-request/$borrowingId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(requestBody),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to approve request: ${response.body}');
    }
  }

  // Reject a book request (librarian)
  static Future<Map<String, dynamic>> rejectRequest({
    required int borrowingId,
    String? librarianMessage,
  }) async {
    final token = await getAccessToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final requestBody = <String, dynamic>{};
    if (librarianMessage != null) {
      requestBody['librarian_message'] = librarianMessage;
    }

    final response = await http.post(
      Uri.parse('$baseUrl/book-library/reject-request/$borrowingId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(requestBody),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to reject request: ${response.body}');
    }
  }

  // Mark a book as picked up (for librarians)
  static Future<Map<String, dynamic>> markPickup(int borrowingId) async {
    final token = await getAccessToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/book-library/mark-pickup/$borrowingId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to mark pickup: ${response.body}');
    }
  }

  // Librarian return book (for librarians)
  static Future<Map<String, dynamic>> librarianReturnBook(
      int borrowingId) async {
    final token = await getAccessToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/book-library/librarian-return/$borrowingId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to return book: ${response.body}');
    }
  }

  // Update book stock (for librarians)
  static Future<Map<String, dynamic>> updateBookStock(
      {required int bookId, int? stock, int? inventory}) async {
    final token = await getAccessToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final data = <String, dynamic>{};
    if (stock != null) data['stock'] = stock;
    if (inventory != null) data['inventory'] = inventory;

    final response = await http.post(
      Uri.parse('$baseUrl/book-library/update-book-stock/$bookId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update book stock: ${response.body}');
    }
  }

  // Get all book requests (for librarians)
  static Future<List<dynamic>> getAllBookRequests() async {
    final token = await getAccessToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/book-library/all-book-requests'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get book requests: ${response.body}');
      }
    } catch (e) {
      print('Exception in getAllBookRequests: $e');
      throw Exception('Error fetching book requests: $e');
    }
  }

  // Request loan extension
  static Future<Map<String, dynamic>> requestLoanExtension({
    required int borrowingId,
    required int requestedDays,
    String? message,
  }) async {
    final token = await getAccessToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/book-library/request-extension/$borrowingId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'requested_days': requestedDays,
        'message': message ?? '',
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to request extension: ${response.body}');
    }
  }

  // Approve loan extension request (librarian)
  static Future<Map<String, dynamic>> approveExtension({
    required int borrowingId,
    required int requestedDays,
    String? librarianMessage,
  }) async {
    final token = await getAccessToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final requestBody = <String, dynamic>{
      'requested_days': requestedDays,
    };

    if (librarianMessage != null) {
      requestBody['librarian_message'] = librarianMessage;
    }

    final response = await http.post(
      Uri.parse('$baseUrl/book-library/approve-extension/$borrowingId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(requestBody),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to approve extension: ${response.body}');
    }
  }

  // Decline loan extension request (librarian)
  static Future<Map<String, dynamic>> declineExtension({
    required int borrowingId,
    String? librarianMessage,
  }) async {
    final token = await getAccessToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final requestBody = <String, dynamic>{};
    if (librarianMessage != null) {
      requestBody['librarian_message'] = librarianMessage;
    }

    final response = await http.post(
      Uri.parse('$baseUrl/book-library/decline-extension/$borrowingId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(requestBody),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to decline extension: ${response.body}');
    }
  }

  // Get unread notification count
  static Future<int> getUnreadNotificationCount() async {
    try {
      final notifications = await getNotifications();
      return notifications.where((n) => n['is_read'] == false).length;
    } catch (e) {
      print('Error getting unread notification count: $e');
      return 0;
    }
  }

  // Fetch all exam models
  static Future<List<dynamic>> fetchExamModels() async {
    final response = await http.get(Uri.parse('$baseUrl$examModelsEndpoint'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load exam models: \\${response.body}');
    }
  }

  // Add a new exam model (with PDF upload)
  static Future<Map<String, dynamic>> addExamModel({
    required String name,
    required String type,
    required String category,
    String? pdfFilePath,
    Uint8List? pdfFileBytes,
    String? pdfFileName,
  }) async {
    final token = await getAccessToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }
    
    // Debug information
    print('Adding exam model:');
    print('  Name: $name');
    print('  Type: $type');
    print('  Category: $category');
    print('  PDF File Name: $pdfFileName');
    print('  PDF File Path: $pdfFilePath');
    print('  PDF File Bytes: ${pdfFileBytes?.length ?? 0} bytes');
    print('  Is Web: $kIsWeb');
    
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl$createExamModelEndpoint'));
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['name'] = name;
    request.fields['type'] = type;
    request.fields['category'] = category;
    
    if (kIsWeb) {
      if (pdfFileBytes == null || pdfFileName == null) {
        throw Exception('PDF file bytes and name are required for web upload');
      }
      var multipartFile = http.MultipartFile.fromBytes('pdf_file', pdfFileBytes, filename: pdfFileName);
      request.files.add(multipartFile);
      print('  Web upload - File added with name: $pdfFileName, size: ${pdfFileBytes.length}');
    } else {
      if (pdfFilePath == null) {
        throw Exception('PDF file path is required for non-web upload');
      }
      var multipartFile = await http.MultipartFile.fromPath('pdf_file', pdfFilePath);
      request.files.add(multipartFile);
      print('  Mobile upload - File added with path: $pdfFilePath');
    }
    
    print('  Request fields: ${request.fields}');
    print('  Request files count: ${request.files.length}');
    
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    
    print('  Response status: ${response.statusCode}');
    print('  Response body: ${response.body}');
    
    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to add exam model: \\${response.body}');
    }
  }

  // Delete an exam model
  static Future<void> deleteExamModel(int id) async {
    final token = await getAccessToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }
    final response = await http.delete(
      Uri.parse('$baseUrl${deleteExamModelEndpoint(id)}'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete exam model: \\${response.body}');
    }
  }

  // Send verification email
  static Future<void> sendVerificationEmail() async {
    final token = await getAccessToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }
    final response = await http.post(
      Uri.parse('$baseUrl/book-library/send-verification-email'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode != 200) {
      throw Exception(jsonDecode(response.body)['detail'] ?? 'Failed to send verification email');
    }
  }

  // Delete book (librarian)
  static Future<Map<String, dynamic>> deleteBook({
    required int bookId,
  }) async {
    final token = await getAccessToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final response = await http.delete(
      Uri.parse('$baseUrl/book-library/delete-book/$bookId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to delete book: ${response.body}');
    }
  }
}
