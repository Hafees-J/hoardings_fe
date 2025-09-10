import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/board.dart';
import 'dart:typed_data';


class ApiService {
  static const String baseUrl = "http://103.99.144.99:8080/api";

  // 🔹 Save tokens locally
  static Future<void> saveTokens(String access, String refresh) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("access", access);
    await prefs.setString("refresh", refresh);
  }

  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("access");
  }

  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("refresh");
  }

  // 🔹 Validate token expiry
  static Future<bool> isTokenValid(String token) async {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return false;

      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );

      final exp = payload['exp'] as int?;
      if (exp == null) return false;

      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      return now < exp;
    } catch (e) {
      print("Token validation error: $e");
      return false;
    }
  }

  // 🔹 Login user
  static Future<bool> login(String username, String password) async {
    final response = await http.post(
      Uri.parse("$baseUrl/login/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"username": username, "password": password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await saveTokens(data['access'], data['refresh']);
      return true;
    }

    print("Login failed: ${response.statusCode} ${response.body}");
    return false;
  }

  // 🔹 Refresh access token
  static Future<bool> refreshAccessToken() async {
    final refresh = await getRefreshToken();
    if (refresh == null) return false;

    final response = await http.post(
      Uri.parse("$baseUrl/token/refresh/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"refresh": refresh}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("access", data['access']);
      return true;
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove("access");
      await prefs.remove("refresh");
      print("Refresh token expired, user must login again.");
      return false;
    }
  }

  // 🔹 Fetch boards
  static Future<List<Board>> fetchBoards() async {
    String? access = await getAccessToken();
    if (access == null) throw Exception("No access token found");

    var response = await http.get(
      Uri.parse("$baseUrl/Boards/"),
      headers: {"Authorization": "Bearer $access"},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Board.fromJson(json)).toList();
    } else if (response.statusCode == 401) {
      bool refreshed = await refreshAccessToken();
      if (refreshed) return fetchBoards();
      throw Exception("Unauthorized. Please login again.");
    } else {
      throw Exception("Failed to load boards. Code: ${response.statusCode}");
    }
  }

  // 🔹 Clear tokens (logout local)
  static Future<void> logoutLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("access");
    await prefs.remove("refresh");
  }

  // 🔹 Create board (with optional image)
  static Future<void> createBoard(Board board, {File? imageFile}) async {
    final token = await getAccessToken();
    var uri = Uri.parse("$baseUrl/Boards/");

    var request = http.MultipartRequest("POST", uri);
    request.headers["Authorization"] = "Bearer $token";

    request.fields["location"] = board.location;
    request.fields["amount"] = board.amount.toString();
    request.fields["latitude"] = board.latitude.toString();
    request.fields["longitude"] = board.longitude.toString();
    request.fields["renewal_at"] = board.renewalAt.toString();
    request.fields["next_renewal_at"] = board.nextRenewalAt.toString();
    request.fields["renewalby"] = board.renewalBy.toString();
    request.fields["createdby"] = board.createdBy.toString();

    if (imageFile != null) {
      request.files.add(await http.MultipartFile.fromPath("image", imageFile.path));
    }

    var response = await request.send();
    if (response.statusCode != 201) {
      final respStr = await response.stream.bytesToString();
      throw Exception("Failed to create board: $respStr");
    }
  }

  // 🔹 Update board (with optional image)
  // 🔹 Update board (with optional image)
static Future<void> updateBoard(Board board, {File? imageFile}) async {
  final token = await getAccessToken();
  if (board.id == null) {
    throw Exception("Board id is required for update");
  }

  var uri = Uri.parse("$baseUrl/Boards/${board.id}/");
  var request = http.MultipartRequest("PUT", uri);
  request.headers["Authorization"] = "Bearer $token";

  request.fields["location"] = board.location;
  request.fields["amount"] = board.amount.toString();
  request.fields["latitude"] = board.latitude.toString();
  request.fields["longitude"] = board.longitude.toString();
  request.fields["renewal_at"] = board.renewalAt.toString();
  request.fields["next_renewal_at"] = board.nextRenewalAt.toString();
  request.fields["renewalby"] = board.renewalBy.toString();
  request.fields["createdby"] = board.createdBy.toString();

  if (imageFile != null) {
    request.files.add(await http.MultipartFile.fromPath("image", imageFile.path));
  }

  var response = await request.send();
  if (response.statusCode != 200) {
    final respStr = await response.stream.bytesToString();
    throw Exception("Failed to update board: $respStr");
  }
}


  // 🔹 Delete board
  static Future<void> deleteBoard(int id) async {
    final token = await getAccessToken();
    final response = await http.delete(
      Uri.parse("$baseUrl/Boards/$id/"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode != 204) {
      throw Exception("Failed to delete board: ${response.body}");
    }
  }
  static Future<void> createBoardWeb(Board board, Uint8List imageBytes, String fileName) async {
  final token = await getAccessToken();
  var uri = Uri.parse("$baseUrl/Boards/");

  var request = http.MultipartRequest("POST", uri);
  request.headers["Authorization"] = "Bearer $token";

  request.fields["location"] = board.location;
  request.fields["amount"] = board.amount.toString();
  request.fields["latitude"] = board.latitude.toString();
  request.fields["longitude"] = board.longitude.toString();
  request.fields["renewal_at"] = board.renewalAt.toString();
  request.fields["next_renewal_at"] = board.nextRenewalAt.toString();
  request.fields["renewalby"] = board.renewalBy.toString();
  request.fields["createdby"] = board.createdBy.toString();

  // ✅ Add image as bytes for web
  request.files.add(http.MultipartFile.fromBytes("image", imageBytes, filename: fileName));

  var response = await request.send();
  if (response.statusCode != 201) {
    final respStr = await response.stream.bytesToString();
    throw Exception("Failed to create board: $respStr");
  }
}

static Future<void> updateBoardWeb(Board board, Uint8List? imageBytes, String? fileName) async {
  final token = await getAccessToken();
  var uri = Uri.parse("$baseUrl/Boards/${board.id}/");

  var request = http.MultipartRequest("PUT", uri);
  request.headers["Authorization"] = "Bearer $token";

  request.fields["location"] = board.location;
  request.fields["amount"] = board.amount.toString();
  request.fields["latitude"] = board.latitude.toString();
  request.fields["longitude"] = board.longitude.toString();
  request.fields["renewal_at"] = board.renewalAt ?? "";
  request.fields["next_renewal_at"] = board.nextRenewalAt ?? "";
  request.fields["renewalby"] = board.renewalBy ?? "";
  request.fields["createdby"] = board.createdBy ?? "";

  if (imageBytes != null && fileName != null) {
    request.files.add(http.MultipartFile.fromBytes("image", imageBytes, filename: fileName));
  }

  var response = await request.send();
  if (response.statusCode != 200) {
    final respStr = await response.stream.bytesToString();
    throw Exception("Failed to update board: $respStr");
  }
}

}


