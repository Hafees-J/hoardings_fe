import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'models/board.dart';
import 'services/api_service.dart';

class BoardFormPage extends StatefulWidget {
  final Board? board;

  const BoardFormPage({super.key, this.board});

  @override
  State<BoardFormPage> createState() => _BoardFormPageState();
}

class _BoardFormPageState extends State<BoardFormPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _locationController;
  late TextEditingController _amountController;
  late TextEditingController _latitudeController;
  late TextEditingController _longitudeController;
  late TextEditingController _renewalAtController;
  late TextEditingController _nextRenewalAtController;
  late TextEditingController _renewalByController;
  late TextEditingController _createdByController;

  File? _selectedImage;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _locationController = TextEditingController(text: widget.board?.location ?? "");
    _amountController = TextEditingController(text: widget.board?.amount.toString() ?? "");
    _latitudeController = TextEditingController(text: widget.board?.latitude.toString() ?? "");
    _longitudeController = TextEditingController(text: widget.board?.longitude.toString() ?? "");
    _renewalAtController = TextEditingController(text: widget.board?.renewalAt.toString() ?? "");
    _nextRenewalAtController = TextEditingController(text: widget.board?.nextRenewalAt.toString() ?? "");
    _renewalByController = TextEditingController(text: widget.board?.renewalBy.toString() ?? "");
    _createdByController = TextEditingController(text: widget.board?.createdBy.toString() ?? "");
  }

  @override
  void dispose() {
    _locationController.dispose();
    _amountController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _renewalAtController.dispose();
    _nextRenewalAtController.dispose();
    _renewalByController.dispose();
    _createdByController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
      });
    }
  }

  Future<void> _saveBoard() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final board = Board(
        id: widget.board?.id ?? 0,
        location: _locationController.text,
        latitude: double.tryParse(_latitudeController.text) ?? 0.0,
        longitude: double.tryParse(_longitudeController.text) ?? 0.0,
        image: widget.board?.image ?? "",
        amount: double.tryParse(_amountController.text) ?? 0.0,
        renewalAt: _renewalAtController.text,
        nextRenewalAt: _nextRenewalAtController.text,
        renewalBy: _renewalByController.text,
        createdBy: _createdByController.text,
      );

      if (widget.board == null) {
        // ✅ Create new
        await ApiService.createBoard(board, imageFile: _selectedImage);
      } else {
        // ✅ Update
        await ApiService.updateBoard(board, imageFile: _selectedImage);
      }

      if (!mounted) return;
      Navigator.pop(context, true); // return success
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.board != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? "Edit Board" : "Add Board"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: "Location"),
                validator: (value) => value!.isEmpty ? "Enter location" : null,
              ),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: "Amount"),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? "Enter amount" : null,
              ),
              TextFormField(
                controller: _latitudeController,
                decoration: const InputDecoration(labelText: "Latitude"),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _longitudeController,
                decoration: const InputDecoration(labelText: "Longitude"),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _renewalAtController,
                decoration: const InputDecoration(labelText: "renewal_at"),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _nextRenewalAtController,
                decoration: const InputDecoration(labelText: "next_renewal_at"),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _renewalByController,
                decoration: const InputDecoration(labelText: "renewal_by"),
              ),
              TextFormField(
                controller: _createdByController,
                decoration: const InputDecoration(labelText: "created_by"),
              ),
              const SizedBox(height: 20),

              // ✅ Image picker
              Row(
                children: [
                  _selectedImage != null
                      ? Image.file(_selectedImage!, width: 100, height: 100, fit: BoxFit.cover)
                      : (widget.board?.image.isNotEmpty == true
                          ? Image.network(widget.board!.image, width: 100, height: 100, fit: BoxFit.cover)
                          : Container(width: 100, height: 100, color: Colors.grey[300], child: const Icon(Icons.image))),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _pickImage,
                    child: const Text("Choose Image"),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _saveBoard,
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(isEdit ? "Update" : "Create"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

