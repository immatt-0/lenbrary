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
    'ANULATA': 'Anulată',
  };

  // Base URL of your Django backend - update this for your testing environment
  // For emulators:
  // static const String baseUrl = 'http://10.0.2.2:8000';      // Android emulator
  // static const String baseUrl =  'http://localhost:8000'; // Windows/Web/iOS simulator

  // For physical devices, use your computer's actual IP address:
  static const String baseUrl = 'http://192.168.68.111:8000'; // Replace with your actual IP

  // Endpoints
  static const String registerEndpoint = '/book-library/register';
  static const String loginEndpoint = '/api/token/';
  static const String refreshTokenEndpoint = '/api/token/refresh/';

  // Exam Model Endpoints
  static const String examModelsEndpoint = '/book-library/exam-models/';
  static const String createExamModelEndpoint = '/book-library/exam-models/create/';
  static String deleteExamModelEndpoint(int id) => '/book-library/exam-models/$id/delete/';

  // Teacher Code Endpoints
  static const String teacherCodesEndpoint = '/book-library/invitation-codes';
  static const String generateTeacherCodeEndpoint = '/book-library/invitation-codes/create';
  static String deleteTeacherCodeEndpoint(int id) => '/book-library/invitation-codes/$id/delete';

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
  // - Custom username (iif manually set during registraton)
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
  static Future<String> uploadThumbnail(dynamic imageFile) async {
    final token = await getAccessToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    try {
      debugPrint('Starting thumbnail upload...');
      debugPrint('Platform: ${kIsWeb ? 'Web' : 'Mobile'}');
      debugPrint('File type: ${imageFile.runtimeType}');
      
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/book-library/thumbnails'),
      );
      
      request.headers.addAll({
        'Authorization': 'Bearer $token',
      });
      
      if (kIsWeb) {
        // For web, imageFile should be a Uint8List
        if (imageFile is Uint8List) {
          debugPrint('Web upload: Adding file with ${imageFile.length} bytes');
          request.files.add(http.MultipartFile.fromBytes(
            'thumbnail',
            imageFile,
            filename: 'thumbnail.jpg',
          ));
        } else {
          throw Exception('Invalid file format for web upload. Expected Uint8List, got ${imageFile.runtimeType}');
        }
      } else {
        // For mobile platforms, imageFile should be a file path string
        if (imageFile is String) {
          debugPrint('Mobile upload: Adding file from path: $imageFile');
          request.files.add(await http.MultipartFile.fromPath(
            'thumbnail',
            imageFile,
          ));
        } else {
          throw Exception('Invalid file format for mobile upload. Expected String, got ${imageFile.runtimeType}');
        }
      }
      
      debugPrint('Sending upload request...');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      debugPrint('Upload response status: ${response.statusCode}');
      debugPrint('Upload response body: ${response.body}');
      
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['thumbnail_url'];
      } else {
        throw Exception('Failed to upload thumbnail: ${response.body}');
      }
    } catch (e) {
      debugPrint('Upload error: $e');
      throw Exception('Error uploading thumbnail: $e');
    }
  }

  // Upload PDF file for books/manuals
  static Future<String> uploadPdf(dynamic pdfFile) async {
    final token = await getAccessToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    try {
      debugPrint('Starting PDF upload...');
      debugPrint('Platform: ${kIsWeb ? 'Web' : 'Mobile'}');
      debugPrint('File type: ${pdfFile.runtimeType}');
      
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/book-library/upload-pdf'),
      );
      
      request.headers.addAll({
        'Authorization': 'Bearer $token',
      });
      
      if (kIsWeb) {
        // For web, pdfFile should be a Uint8List
        if (pdfFile is Uint8List) {
          debugPrint('Web upload: Adding PDF file with ${pdfFile.length} bytes');
          request.files.add(http.MultipartFile.fromBytes(
            'pdf',
            pdfFile,
            filename: 'document.pdf',
          ));
        } else {
          throw Exception('Invalid file format for web upload. Expected Uint8List, got ${pdfFile.runtimeType}');
        }
      } else {
        // For mobile platforms, pdfFile should be a file path string
        if (pdfFile is String) {
          debugPrint('Mobile upload: Adding PDF file from path: $pdfFile');
          request.files.add(await http.MultipartFile.fromPath(
            'pdf',
            pdfFile,
          ));
        } else {
          throw Exception('Invalid file format for mobile upload. Expected String, got ${pdfFile.runtimeType}');
        }
      }
      
      debugPrint('Sending PDF upload request...');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      debugPrint('PDF upload response status: ${response.statusCode}');
      debugPrint('PDF upload response body: ${response.body}');
      
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['pdf_url'];
      } else {
        throw Exception('Failed to upload PDF: ${response.body}');
      }
    } catch (e) {
      debugPrint('PDF upload error: $e');
      throw Exception('Error uploading PDF: $e');
    }
  }

  // Helper to extract relative media path from a full URL or URL-encoded string
  static String extractRelativeMediaPath(String url) {
    try {
      final decoded = Uri.decodeFull(url);
      final uri = Uri.parse(decoded);
      final path = uri.path;
      final idx = path.indexOf('/media/');
      if (idx != -1) {
        return path.substring(idx + 7); // 7 = length of '/media/'
      }
      return path;
    } catch (e) {
      // Fallback: try to find /media/ in the raw string
      final idx = url.indexOf('/media/');
      if (idx != -1) {
        return url.substring(idx + 7);
      }
      return url;
    }
  }

  // Add new book to library
  static Future<Map<String, dynamic>> addBook({
    required String name,
    required String author,
    required int inventory,
    required int stock,
    String? description,
    String? category,
    String? type,
    int? publicationYear,
    String? thumbnailUrl,
    String? bookClass,
    String? pdfUrl,
  }) async {
    final token = await getAccessToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    // Ensure only relative paths are sent for media fields
    final String? safeThumbnailUrl =
        thumbnailUrl != null ? extractRelativeMediaPath(thumbnailUrl) : null;
    final String? safePdfUrl =
        pdfUrl != null ? extractRelativeMediaPath(pdfUrl) : null;

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
        'type': type,
        'publication_year': publicationYear,
        'thumbnail_url': safeThumbnailUrl,
        'book_class': bookClass,
        'pdf_file': safePdfUrl,
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception(response.body);
    }
  }

  // Get all books
  static Future<List<dynamic>> getBooks({String? search, String? category}) async {
    try {
      print('API Service: Getting books...');
      print('API Service: Token: ${await getAccessToken()}');
      
      final token = await getAccessToken();
      if (token == null) {
        print('API Service: No token found');
        throw Exception('Token not found');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/book-library/books'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('API Service: Response status: ${response.statusCode}');
      print('API Service: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('API Service: Decoded data: $data');
        
        if (data is List) {
          print('API Service: Returning ${data.length} books');
          return data;
        } else if (data is Map && data.containsKey('results')) {
          print('API Service: Returning ${data['results'].length} books from results');
          return data['results'];
        } else {
          print('API Service: Unexpected data format: $data');
          return [];
        }
      } else {
        print('API Service: Error response: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load books: ${response.statusCode}');
      }
    } catch (e) {
      print('API Service: Exception in getBooks: $e');
      throw Exception('Failed to load books: $e');
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
  static Future<Map<String, dynamic>> requestBook({
    required int bookId,
    int loanDurationDays = 14,
    String? message,
  }) async {
    final Map<String, dynamic> body = {
      'book_id': bookId,
      'loan_duration_days': loanDurationDays,
    };
    if (message != null && message.trim().isNotEmpty) {
      body['message'] = message.trim();
    }
    final response = await _makeRequest(
      'POST',
      '/book-library/request-book',
      body: body,
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
      final List<dynamic> models = jsonDecode(response.body);
      
      // Sort the models for better organization
      models.sort((a, b) {
        // First sort by type: EN comes before BAC
        int typeComparison = (a['type'] ?? '').compareTo(b['type'] ?? '');
        if (typeComparison != 0) return typeComparison;
        
        // Then sort by category: Matematica comes before Romana
        int categoryComparison = (a['category'] ?? '').compareTo(b['category'] ?? '');
        if (categoryComparison != 0) return categoryComparison;
        
        // Finally sort by name alphabetically
        return (a['name'] ?? '').toLowerCase().compareTo((b['name'] ?? '').toLowerCase());
      });
      
      return models;
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

  // Update book details (for librarians)
  static Future<Map<String, dynamic>> updateBook({
    required int bookId,
    String? name,
    String? author,
    String? category,
    String? type,
    String? description,
    int? publicationYear,
    String? thumbnailUrl,
    int? stock,
    int? inventory,
    String? bookClass,
    String? pdfUrl,
  }) async {
    final token = await getAccessToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (author != null) data['author'] = author;
    if (category != null) data['category'] = category;
    if (type != null) data['type'] = type;
    if (description != null) data['description'] = description;
    if (publicationYear != null) data['publication_year'] = publicationYear;
    if (thumbnailUrl != null) data['thumbnail_url'] = thumbnailUrl;
    if (stock != null) data['stock'] = stock;
    if (inventory != null) data['inventory'] = inventory;
    if (bookClass != null) data['book_class'] = bookClass;
    if (pdfUrl != null) data['pdf_file'] = pdfUrl;

    final response = await http.put(
      Uri.parse('$baseUrl/book-library/book/$bookId'),
      headers: {
        'Content-Type': 'application/json; charset=utf-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );

    print('Sent data: ' + jsonEncode(data));
    print('Response body: ' + utf8.decode(response.bodyBytes));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update book: ${response.body}');
    }
  }

  // Cancel a book request (student)
  static Future<void> cancelRequest({
    required int requestId,
    String? message,
  }) async {
    final token = await getAccessToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }
    final url = '$baseUrl/book-library/cancel-request/$requestId/';
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        if (message != null && message.isNotEmpty) 'message': message,
      }),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      try {
        final errorData = jsonDecode(response.body);
        if (errorData is Map && errorData.containsKey('error')) {
          throw errorData['error'];
        }
      } catch (_) {}
      throw Exception('Failed to cancel request: ${response.body}');
    }
  }

  // Teacher Code Management Methods
  
  // Get all teacher codes (for librarians)
  static Future<List<dynamic>> getTeacherCodes() async {
    final token = await getAccessToken();
    if (token == null) {
      throw Exception('No access token available');
    }

    final response = await http.get(
      Uri.parse('$baseUrl$teacherCodesEndpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load teacher codes: ${response.body}');
    }
  }

  // Generate a new teacher code
  static Future<Map<String, dynamic>> generateTeacherCode() async {
    final token = await getAccessToken();
    if (token == null) {
      throw Exception('No access token available');
    }

    final response = await http.post(
      Uri.parse('$baseUrl$generateTeacherCodeEndpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to generate teacher code: ${response.body}');
    }
  }

  // Delete a teacher code
  static Future<void> deleteTeacherCode(int codeId) async {
    final token = await getAccessToken();
    if (token == null) {
      throw Exception('No access token available');
    }

    final response = await http.delete(
      Uri.parse('$baseUrl${deleteTeacherCodeEndpoint(codeId)}'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete teacher code: ${response.body}');
    }
  }

  // Add this to ApiService:
  static Future<void> logout() async {
    await clearTokens();
  }
}
