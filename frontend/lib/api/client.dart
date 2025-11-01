import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  static String baseUrl = "https://freshcart.cloudpub.ru";
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

  static Future<Map<String, dynamic>> register(
    String username, String email, String password, String firstName, String lastName) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: _headers,
      body: json.encode({
        'username': username,
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

  static Future<List<dynamic>> getCategories() async {
    final response = await http.get(
      Uri.parse('$baseUrl/products/categories'),
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
  static Future<List<dynamic>> getFavorites() async {
    final response = await http.get(
      Uri.parse('$baseUrl/favorites/'),
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

  static dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return json.decode(response.body);
    } else {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }
  }
}