import 'package:flutter/material.dart';
import 'models/board.dart';
import 'services/api_service.dart';
import 'login_page.dart';
import 'BoardFormPage.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<Board>> futureBoards;

  @override
  void initState() {
    super.initState();
    _reloadBoards();
  }

  void _reloadBoards() {
    setState(() {
      futureBoards = ApiService.fetchBoards();
    });
  }

  Future<void> _logoutAndRedirect() async {
    await ApiService.logoutLocal();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  void _addBoard() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BoardFormPage()),
    );
    if (result == true) _reloadBoards();
  }

  void _editBoard(Board board) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BoardFormPage(board: board)),
    );
    if (result == true) _reloadBoards();
  }

  Future<void> _deleteBoard(int? id) async {
    if (id == null) return; // ✅ prevent null crash

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Board"),
        content: const Text("Are you sure you want to delete this board?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ApiService.deleteBoard(id);
      _reloadBoards();
    }
  }

  // ✅ Board Card UI (fixed for overflow + id handling)
  Widget _buildBoardCard(Board board) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 6,
      shadowColor: Colors.black26,
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min, // ✅ only wrap content
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FullImagePage(imageUrl: board.image),
              ),
            ),
            child: Hero(
              tag: board.image,
              child: board.image.isNotEmpty
                  ? Image.network(board.image,
                      height: 120, width: double.infinity, fit: BoxFit.cover)
                  : Container(
                      height: 120,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image_not_supported,
                          size: 50, color: Colors.grey),
                    ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(board.location,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Chip(
                  label: Text("₹${board.amount}"),
                  backgroundColor: Colors.green[50],
                  labelStyle: const TextStyle(
                      color: Colors.green, fontWeight: FontWeight.bold),
                ),
                const Divider(height: 18),
                if (board.createdBy != null)
                  _infoRow(Icons.person, "Created by", board.createdBy!),
                if (board.renewalBy != null)
                  _infoRow(Icons.manage_accounts, "Renewal by", board.renewalBy!),
                if (board.renewalAt != null)
                  _infoRow(Icons.calendar_today, "Renewal at", board.renewalAt!),
                if (board.nextRenewalAt != null)
                  _infoRow(Icons.event_available, "Next Renewal",
                      board.nextRenewalAt!),
                _infoRow(Icons.map, "Lat/Long",
                    "${board.latitude}, ${board.longitude}"),
              ],
            ),
          ),

          // Buttons (now just after content, no gap)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: () => _editBoard(board),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  if (board.id != null) {
                    _deleteBoard(board.id); // ✅ safe delete
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 6),
          Text("$label: ",
              style: const TextStyle(
                  fontWeight: FontWeight.w600, color: Colors.black54)),
          Expanded(
            child: Text(value,
                style: const TextStyle(color: Colors.black87),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("📊 Hoardings Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Logout",
            onPressed: _logoutAndRedirect,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addBoard,
        icon: const Icon(Icons.add),
        label: const Text("Add Board"),
      ),
      body: FutureBuilder<List<Board>>(
        future: futureBoards,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            final errorMsg = snapshot.error.toString();
            if (errorMsg.contains("Unauthorized")) {
              Future.microtask(() => _logoutAndRedirect());
              return const Center(
                  child: Text("Session expired. Redirecting to login..."));
            }
            return Center(child: Text("Error: $errorMsg"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No boards available"));
          } else {
            final boards = snapshot.data!;
            return GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 320, // max width for each card
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.72, // adjust height balance
              ),
              itemCount: boards.length,
              itemBuilder: (context, index) =>
                  _buildBoardCard(boards[index]),
            );
          }
        },
      ),
    );
  }
}

/// ✅ Fullscreen Image Page with Hero animation
class FullImagePage extends StatelessWidget {
  final String imageUrl;
  const FullImagePage({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Center(
          child: Hero(
            tag: imageUrl,
            child: InteractiveViewer(
              child: Image.network(imageUrl),
            ),
          ),
        ),
      ),
    );
  }
}

