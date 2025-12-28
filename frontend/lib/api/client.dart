import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

class ApiClient {
  static String baseUrl = kIsWeb ? "${Uri.base.origin}/api" : "https://freshcart-api.cloudpub.ru";
  static String? _token;

  static void setToken(String token) {
    _token = token;
  }

  static void clearToken() {
    _token = null;
  }

  static Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
    };
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  // Profile methods
  static Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> profileData) async {
    final response = await http.put(
      Uri.parse('$baseUrl/auth/profile'),
      headers: _headers,
      body: json.encode(profileData),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/auth/change-password'),
      headers: _headers,
      body: json.encode({
        'current_password': currentPassword,
        'new_password': newPassword,
      }),
    );
    return _handleResponse(response);
  }

  // Notifications settings
  static Future<Map<String, dynamic>> getNotificationSettings() async {
    final response = await http.get(
      Uri.parse('$baseUrl/auth/settings/notifications'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> updateNotificationSettings(Map<String, dynamic> settings) async {
    final response = await http.put(
      Uri.parse('$baseUrl/auth/settings/notifications'),
      headers: _headers,
      body: json.encode(settings),
    );
    return _handleResponse(response);
  }

  // Auth
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: _headers,
      body: json.encode({
        'email': email,
        'password': password,
      }),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> registration(
    String email, String password, String firstName, String lastName) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/registration'),
      headers: _headers,
      body: json.encode({
        'email': email,
        'password': password,
        'first_name': firstName,
        'last_name': lastName,
      }),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getProfile() async {
    final response = await http.get(
      Uri.parse('$baseUrl/auth/me'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  // Products
  static Future<List<dynamic>> getProducts({int? categoryId, String? search}) async {
    final params = <String, String>{};
    if (categoryId != null) params['category_id'] = categoryId.toString();
    if (search != null && search.isNotEmpty) params['search'] = search;
    
    final response = await http.get(
      Uri.parse('$baseUrl/products/').replace(queryParameters: params),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  static Future<List<dynamic>> getProduct(int productId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/products/items/$productId'),
      headers: _headers,
    );
    
    return _handleResponse(response);
  }

  static Future<List<dynamic>> searchProducts({
    String? name,
    int? categoryId,
    int limit = 100,
    int offset = 0,
  }) async {
    final params = <String, String>{
      'limit': limit.toString(),
      'offset': offset.toString(),
    };
    
    if (name != null && name.isNotEmpty) {
      params['name'] = name;
    }
    
    if (categoryId != null) {
      params['category_id'] = categoryId.toString();
    }
    
    final uri = Uri.parse('$baseUrl/products/search').replace(queryParameters: params);
    
    print('🔍 Search URL: $uri'); 
    
    final response = await http.get(
      uri,
      headers: _headers,
    );
    
    print('📡 Search response status: ${response.statusCode}');
    
    return _handleResponse(response);
  }

  static Future<List<dynamic>> getCategories() async {
    final response = await http.get(
      Uri.parse('$baseUrl/products/categories'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> uploadCategoryImageBase64(int categoryId, String base64Image) async {
    final response = await http.post(
      Uri.parse('$baseUrl/images/categories/$categoryId/image'),
      headers: _headers,
      body: json.encode({
        'image_data': base64Image,
      }),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> uploadCategoryImageFile(
    int categoryId, 
    String filePath, 
    List<int> fileBytes
  ) async {
    // Создаем multipart запрос
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/images/categories/$categoryId/image-file'),
    );

    // Добавляем заголовки
    if (_token != null) {
      request.headers['Authorization'] = 'Bearer $_token';
    }

    // Добавляем файл
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: filePath.split('/').last,
      ),
    );

    // Отправляем запрос
    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> deleteCategoryImage(int categoryId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/images/categories/$categoryId/image'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  // Cart
  static Future<Map<String, dynamic>> getCart() async {
    final response = await http.get(
      Uri.parse('$baseUrl/cart/'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> calculateCartDiscounts(List<Map<String, dynamic>> items) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/promotions/active/for-cart'),
        headers: _headers,
        body: json.encode({
          'items': items,
        }),
      );
      return _handleResponse(response);
    } catch (e) {
      print('Error calculating discounts: $e');
      throw e;
    }
  }

  static Future<Map<String, dynamic>> addToCart(int productId, int quantity) async {
    final response = await http.post(
      Uri.parse('$baseUrl/cart/'),
      headers: _headers,
      body: json.encode({
        'product_id': productId,
        'quantity': quantity,
      }),
    );
    return _handleResponse(response);
  }

  static Future<void> removeFromCart(int productId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/cart/$productId'),
      headers: _headers,
    );
    _handleResponse(response);
  }

  static Future<Map<String, dynamic>> updateCartItem(int productId, int quantity) async {
    final response = await http.put(
      Uri.parse('$baseUrl/cart/$productId'),
      headers: _headers,
      body: json.encode({
        'quantity': quantity,
      }),
    );
    return _handleResponse(response);
  }


  // Orders
  static Future<Map<String, dynamic>> createOrder(
    String shippingAddress, String notes, List<Map<String, dynamic>> items) async {
    final response = await http.post(
      Uri.parse('$baseUrl/orders/'),
      headers: _headers,
      body: json.encode({
        'shipping_address': shippingAddress,
        'notes': notes,
        'items': items,
      }),
    );
    return _handleResponse(response);
  }

  static Future<List<dynamic>> getMyOrders() async {
    final response = await http.get(
      Uri.parse('$baseUrl/orders/'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  // Addresses
  static Future<List<dynamic>> getAddresses() async {
    final response = await http.get(
      Uri.parse('$baseUrl/addresses/'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> createAddress(Map<String, dynamic> addressData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/addresses/'),
      headers: _headers,
      body: json.encode(addressData),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> updateAddress(int addressId, Map<String, dynamic> addressData) async {
    final response = await http.put(
      Uri.parse('$baseUrl/addresses/$addressId'),
      headers: _headers,
      body: json.encode(addressData),
    );
    return _handleResponse(response);
  }

  static Future<void> deleteAddress(int addressId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/addresses/$addressId'),
      headers: _headers,
    );
    _handleResponse(response);
  }

  static Future<void> setDefaultAddress(int addressId) async {
    final response = await http.put(
      Uri.parse('$baseUrl/addresses/$addressId/set-default'),
      headers: _headers,
    );
    _handleResponse(response);
  }

  // Favorites
  static Future<List<dynamic>> getFavorites({String? search}) async {
    final Map<String, String> queryParams = {};
    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }
    
    final response = await http.get(
      Uri.parse('$baseUrl/favorites/').replace(queryParameters: queryParams),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> addToFavorites(int productId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/favorites/'),
      headers: _headers,
      body: json.encode({
        'product_id': productId,
      }),
    );
    return _handleResponse(response);
  }

  static Future<void> removeFromFavorites(int productId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/favorites/items/$productId'),
      headers: _headers,
    );
    _handleResponse(response);
  }

  static Future<Map<String, dynamic>> checkFavorite(int productId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/favorites/check/$productId'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  // Promotions
  static Future<List<dynamic>> getPromotions() async {
    final response = await http.get(
      Uri.parse('$baseUrl/promotions/'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  static Future<List<dynamic>> getActivePromotionsForCart() async {
    final response = await http.get(
      Uri.parse('$baseUrl/promotions/active/for-cart'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getPromotion(int promotionId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/promotions/$promotionId'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  // Analysis methods
  static Future<Map<String, dynamic>> analyzeFoodImageFile(List<int> imageBytes) async {
    final base64Image = base64Encode(imageBytes);
    return analyzeFoodImage(base64Image);
  }

  static Future<Map<String, dynamic>> analyzeFoodImage(String base64Image) async {
    final response = await http.post(
      Uri.parse('$baseUrl/ai/base64'),
      headers: _headers,
      body: json.encode({
        'image_data': base64Image,
      }),
    );
    return _handleResponse(response);
  }

  // History methods
  static Future<List<dynamic>> getMyAnalysisHistory({
    int skip = 0, 
    int limit = 20,
    double? minConfidence,
  }) async {
    final queryParams = {
      'skip': skip.toString(),
      'limit': limit.toString(),
    };
    
    // Добавляем необязательные параметры
    if (minConfidence != null) {
      queryParams['min_confidence'] = minConfidence.toString();
    }
    
    final uri = Uri.parse('$baseUrl/ai/my-history')
        .replace(queryParameters: queryParams);
    
    final response = await http.get(
      uri,
      headers: _headers,
    );
    
    return _handleResponse(response);
  }

  static Future<List<dynamic>> getAllAnalysisHistory({
    int skip = 0, 
    int limit = 20,
    int? userId,
    double? minConfidence,
  }) async {
    final queryParams = {
      'skip': skip.toString(),
      'limit': limit.toString(),
    };
    
    if (userId != null) {
      queryParams['user_id'] = userId.toString();
    }
    
    if (minConfidence != null) {
      queryParams['min_confidence'] = minConfidence.toString();
    }
    
    final uri = Uri.parse('$baseUrl/ai/all-history')
        .replace(queryParameters: queryParams);
    
    final response = await http.get(
      uri,
      headers: _headers,
    );
    
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getAnalysisStats() async {
    final response = await http.get(
      Uri.parse('$baseUrl/ai/history/stats'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  // В client.dart добавим админ-методы

  // Admin - Users
  static Future<bool> isUserAdmin() async {
    try {
      final profile = await getProfile();
      return profile['role']?['name'] == 'admin';
    } catch (e) {
      print('Error checking admin status: $e');
      return false;
    }
  }

  static Future<List<dynamic>> getAdminUsers({int skip = 0, int limit = 100}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/auth/admin/users?skip=$skip&limit=$limit'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> blockUser(int userId) async {
    final response = await http.put(
      Uri.parse('$baseUrl/auth/admin/users/$userId/block'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> unblockUser(int userId) async {
    final response = await http.put(
      Uri.parse('$baseUrl/auth/admin/users/$userId/unblock'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> setUserRole(int userId, String roleName) async {
    final response = await http.put(
      Uri.parse('$baseUrl/auth/admin/users/$userId/role'),
      headers: _headers,
      body: json.encode({'role_name': roleName}),
    );
    return _handleResponse(response);
  }

  // Admin - Products
  static Future<List<dynamic>> getAdminProducts({bool includeInactive = false, int skip = 0, int limit = 100}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/products/admin/products?include_inactive=$includeInactive&skip=$skip&limit=$limit'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> createAdminProduct(Map<String, dynamic> productData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/products/admin/products'),
      headers: _headers,
      body: json.encode(productData),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> updateAdminProduct(int productId, Map<String, dynamic> productData) async {
    final response = await http.put(
      Uri.parse('$baseUrl/products/admin/products/$productId'),
      headers: _headers,
      body: json.encode(productData),
    );
    return _handleResponse(response);
  }

  static Future<void> deleteAdminProduct(int productId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/products/admin/products/$productId'),
      headers: _headers,
    );
    _handleResponse(response);
  }

  static Future<Map<String, dynamic>> uploadProductImageBase64(
    int productId, 
    String base64Image
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/images/products/$productId/image'),
      headers: _headers,
      body: json.encode({'image_data': base64Image}),
    );
    return _handleResponse(response);
  }

  // Admin - Orders
  static Future<List<dynamic>> getAdminOrders({String? status, int skip = 0, int limit = 100}) async {
    final params = <String, String>{
      'skip': skip.toString(),
      'limit': limit.toString(),
    };
    if (status != null) {
      params['status'] = status;
    }
    
    final response = await http.get(
      Uri.parse('$baseUrl/orders/admin/orders').replace(queryParameters: params),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> updateOrderStatus(int orderId, String status) async {
    final response = await http.put(
      Uri.parse('$baseUrl/orders/admin/orders/$orderId/status'),
      headers: _headers,
      body: json.encode({'status': status}),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getOrdersStats() async {
    final response = await http.get(
      Uri.parse('$baseUrl/orders/admin/orders/stats'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  // Admin - Categories
  static Future<List<dynamic>> getAdminCategories({int skip = 0, int limit = 100}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/products/admin/categories?skip=$skip&limit=$limit'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> createAdminCategory(Map<String, dynamic> categoryData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/products/admin/categories'),
      headers: _headers,
      body: json.encode(categoryData),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> updateAdminCategory(int categoryId, Map<String, dynamic> categoryData) async {
    final response = await http.put(
      Uri.parse('$baseUrl/products/admin/categories/$categoryId'),
      headers: _headers,
      body: json.encode(categoryData),
    );
    return _handleResponse(response);
  }

  static Future<void> deleteAdminCategory(int categoryId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/products/admin/categories/$categoryId'),
      headers: _headers,
    );
    _handleResponse(response);
  }

  // Admin - Promotions
  static Future<List<dynamic>> getAdminPromotions({bool? isActive, int skip = 0, int limit = 100}) async {
    final params = <String, String>{
      'skip': skip.toString(),
      'limit': limit.toString(),
    };
    if (isActive != null) {
      params['is_active'] = isActive.toString();
    }
    
    final response = await http.get(
      Uri.parse('$baseUrl/promotions/admin/promotions').replace(queryParameters: params),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> createAdminPromotion(Map<String, dynamic> promotionData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/promotions/admin/promotions'),
      headers: _headers,
      body: json.encode(promotionData),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> updateAdminPromotion(int promotionId, Map<String, dynamic> promotionData) async {
    final response = await http.put(
      Uri.parse('$baseUrl/promotions/admin/promotions/$promotionId'),
      headers: _headers,
      body: json.encode(promotionData),
    );
    return _handleResponse(response);
  }

  static Future<void> deleteAdminPromotion(int promotionId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/promotions/admin/promotions/$promotionId'),
      headers: _headers,
    );
    _handleResponse(response);
  }

  // Admin - Tags
  static Future<List<dynamic>> getAdminTags({String? search, int skip = 0, int limit = 100}) async {
    final params = <String, String>{
      'skip': skip.toString(),
      'limit': limit.toString(),
    };
    if (search != null && search.isNotEmpty) {
      params['search'] = search;
    }
    
    final response = await http.get(
      Uri.parse('$baseUrl/products/admin/tags').replace(queryParameters: params),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> createAdminTag(Map<String, dynamic> tagData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/products/admin/tags'),
      headers: _headers,
      body: json.encode(tagData),
    );
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> updateAdminTag(int tagId, Map<String, dynamic> tagData) async {
    final response = await http.put(
      Uri.parse('$baseUrl/products/admin/tags/$tagId'),
      headers: _headers,
      body: json.encode(tagData),
    );
    return _handleResponse(response);
  }

  static Future<void> deleteAdminTag(int tagId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/products/admin/tags/$tagId'),
      headers: _headers,
    );
    _handleResponse(response);
  }

  static Future<List<dynamic>> getAdminTagProducts(int tagId, {int skip = 0, int limit = 100}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/products/admin/tags/$tagId/products?skip=$skip&limit=$limit'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  // Admin - Statistics
  static Future<Map<String, dynamic>> getAdminStats() async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/stats'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  static dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(response.body);
    } else {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }
  }
}