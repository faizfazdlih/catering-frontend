// admin/screens/menu_management_screen.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../../models/menu.dart';
import '../../services/api_service.dart';
import '../../utils/format_helper.dart';

class MenuManagementScreen extends StatefulWidget {
  const MenuManagementScreen({Key? key}) : super(key: key);

  @override
  State<MenuManagementScreen> createState() => _MenuManagementScreenState();
}

class _MenuManagementScreenState extends State<MenuManagementScreen> {
  List<Menu> _menuList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMenu();
  }

  Future<void> _loadMenu() async {
    setState(() => _isLoading = true);
    
    try {
      final data = await ApiService.getMenu();
      setState(() {
        _menuList = data.map((json) => Menu.fromJson(json)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat menu: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _showAddMenuDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const MenuFormDialog(),
    );
    
    if (result == true) {
      _loadMenu();
    }
  }

  Future<void> _showEditMenuDialog(Menu menu) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => MenuFormDialog(menu: menu),
    );
    
    if (result == true) {
      _loadMenu();
    }
  }

  Future<void> _deleteMenu(Menu menu) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Menu'),
        content: Text('Apakah Anda yakin ingin menghapus "${menu.namaMenu}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final response = await ApiService.deleteMenu(menu.id);
      
      if (mounted) {
        if (response['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message']),
              backgroundColor: Colors.green,
            ),
          );
          _loadMenu();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['message'])),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Menu'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMenu,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _menuList.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.restaurant_menu, size: 80, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('Belum ada menu'),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _showAddMenuDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Tambah Menu'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadMenu,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _menuList.length,
                    itemBuilder: (context, index) {
                      final menu = _menuList[index];
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: menu.fotoUrl != null && menu.fotoUrl!.isNotEmpty
                                ? Image.network(
                                    ApiService.getImageUrl(menu.fotoUrl),
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: 60,
                                        height: 60,
                                        color: Colors.orange.shade100,
                                        child: Icon(
                                          Icons.restaurant,
                                          color: Colors.orange.shade300,
                                        ),
                                      );
                                    },
                                  )
                                : Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.restaurant,
                                      color: Colors.orange.shade300,
                                      size: 30,
                                    ),
                                  ),
                          ),
                          title: Text(
                            menu.namaMenu,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(menu.deskripsi ?? '-'),
                              const SizedBox(height: 4),
                              Text(
                                FormatHelper.formatCurrency(menu.harga),
                                style: const TextStyle(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade100,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      menu.kategori ?? '-',
                                      style: TextStyle(
                                        color: Colors.blue.shade700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: menu.status == 'tersedia'
                                          ? Colors.green.shade100
                                          : Colors.red.shade100,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      menu.status,
                                      style: TextStyle(
                                        color: menu.status == 'tersedia'
                                            ? Colors.green.shade700
                                            : Colors.red.shade700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: PopupMenuButton(
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit, size: 20),
                                    SizedBox(width: 8),
                                    Text('Edit'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, size: 20, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Hapus', style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                            onSelected: (value) {
                              if (value == 'edit') {
                                _showEditMenuDialog(menu);
                              } else if (value == 'delete') {
                                _deleteMenu(menu);
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddMenuDialog,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Menu'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}

// ============================================================================
// FORM DIALOG untuk Add/Edit Menu dengan Upload Image
// ============================================================================

class MenuFormDialog extends StatefulWidget {
  final Menu? menu;
  
  const MenuFormDialog({Key? key, this.menu}) : super(key: key);

  @override
  State<MenuFormDialog> createState() => _MenuFormDialogState();
}

class _MenuFormDialogState extends State<MenuFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _deskripsiController = TextEditingController();
  final _hargaController = TextEditingController();
  String _selectedKategori = 'box';
  String _selectedStatus = 'tersedia';
  bool _isLoading = false;
  
  XFile? _imageFile;
  Uint8List? _imageBytes;
  bool _removeExistingImage = false; // Flag untuk hapus gambar existing
  final ImagePicker _picker = ImagePicker();

  final List<String> _kategoriList = ['box', 'tumpeng', 'snack'];
  final List<String> _statusList = ['tersedia', 'habis'];

  @override
  void initState() {
    super.initState();
    if (widget.menu != null) {
      _namaController.text = widget.menu!.namaMenu;
      _deskripsiController.text = widget.menu!.deskripsi ?? '';
      _hargaController.text = widget.menu!.harga.toString();
      _selectedKategori = widget.menu!.kategori ?? 'box';
      _selectedStatus = widget.menu!.status;
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _imageFile = pickedFile;
          _imageBytes = bytes;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error memilih gambar: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _showImageSourceDialog() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pilih Sumber Gambar'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeri'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Kamera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final harga = double.parse(_hargaController.text);
      
      Map<String, dynamic> response;
      
      if (widget.menu == null) {
        // ADD Menu
        response = await ApiService.addMenuWithImage(
          namaMenu: _namaController.text,
          deskripsi: _deskripsiController.text,
          harga: harga,
          kategori: _selectedKategori,
          imageFile: _imageFile,
        );
      } else {
        // UPDATE Menu
        // Tentukan existing image URL berdasarkan flag _removeExistingImage
        String? existingUrl = _removeExistingImage ? null : widget.menu!.fotoUrl;
        
        response = await ApiService.updateMenuWithImage(
          id: widget.menu!.id,
          namaMenu: _namaController.text,
          deskripsi: _deskripsiController.text,
          harga: harga,
          kategori: _selectedKategori,
          status: _selectedStatus,
          imageFile: _imageFile,
          existingImageUrl: existingUrl, // null jika ingin hapus
        );
      }

      if (!mounted) return;

      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message']),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message']),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.menu == null ? 'Tambah Menu' : 'Edit Menu',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                
                // ============ IMAGE PICKER ============
                GestureDetector(
                  onTap: _showImageSourceDialog,
                  child: Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[400]!),
                    ),
                    child: _imageBytes != null
                        ? Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.memory(
                                  _imageBytes!,
                                  width: double.infinity,
                                  height: 180,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade100,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  child: const Text(
                                    'Gambar Baru',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : !_removeExistingImage && widget.menu?.fotoUrl != null && widget.menu!.fotoUrl!.isNotEmpty
                            ? Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      ApiService.getImageUrl(widget.menu!.fotoUrl),
                                      width: double.infinity,
                                      height: 180,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: const [
                                            Icon(Icons.add_photo_alternate, size: 60, color: Colors.grey),
                                            SizedBox(height: 8),
                                            Text('Tap untuk upload foto'),
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade100,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      child: const Text(
                                        'Gambar Saat Ini',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _removeExistingImage ? Icons.image_not_supported : Icons.add_photo_alternate,
                                    size: 60,
                                    color: _removeExistingImage ? Colors.red.shade300 : Colors.grey,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _removeExistingImage 
                                        ? 'Gambar akan dihapus'
                                        : 'Tap untuk upload foto',
                                    style: TextStyle(
                                      color: _removeExistingImage ? Colors.red : Colors.grey[600],
                                    ),
                                  ),
                                  if (!_removeExistingImage) ...[
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Maks 5MB (jpg, png, gif, webp)',
                                      style: TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                  ],
                                ],
                              ),
                  ),
                ),
                
                if (_imageFile != null || (!_removeExistingImage && widget.menu?.fotoUrl != null && widget.menu!.fotoUrl!.isNotEmpty)) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Tombol Hapus
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            if (_imageFile != null) {
                              // Hapus gambar baru yang baru dipilih
                              _imageFile = null;
                              _imageBytes = null;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Gambar baru dibatalkan'),
                                  duration: Duration(seconds: 1),
                                ),
                              );
                            } else {
                              // Tandai untuk hapus gambar existing
                              _removeExistingImage = true;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Gambar akan dihapus saat menyimpan'),
                                  duration: Duration(seconds: 2),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                            }
                          });
                        },
                        icon: const Icon(Icons.delete, size: 16),
                        label: Text(_imageFile != null ? 'Batal Upload' : 'Hapus Gambar'),
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                      ),
                      
                      // Tombol Ganti (hanya untuk existing image)
                      if (_imageFile == null && widget.menu?.fotoUrl != null) ...[
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: _showImageSourceDialog,
                          icon: const Icon(Icons.edit, size: 16),
                          label: const Text('Ganti'),
                          style: TextButton.styleFrom(foregroundColor: Colors.blue),
                        ),
                      ],
                    ],
                  ),
                ],
                
                // Tombol Restore jika gambar ditandai untuk dihapus
                if (_removeExistingImage && _imageFile == null) ...[
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _removeExistingImage = false;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Gambar dibatalkan untuk dihapus'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                      icon: const Icon(Icons.restore, size: 16),
                      label: const Text('Kembalikan Gambar'),
                      style: TextButton.styleFrom(foregroundColor: Colors.green),
                    ),
                  ),
                ],
                
                const SizedBox(height: 16),
                
                // ============ NAMA MENU ============
                TextFormField(
                  controller: _namaController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Menu',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.restaurant),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Nama menu tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                
                // ============ DESKRIPSI ============
                TextFormField(
                  controller: _deskripsiController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Deskripsi tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                
                // ============ HARGA ============
                TextFormField(
                  controller: _hargaController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Harga',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.attach_money),
                    prefixText: 'Rp ',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Harga tidak boleh kosong';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Harga harus berupa angka';
                    }
                    if (double.parse(value) <= 0) {
                      return 'Harga harus lebih dari 0';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                
                // ============ KATEGORI ============
                DropdownButtonFormField<String>(
                  value: _selectedKategori,
                  decoration: const InputDecoration(
                    labelText: 'Kategori',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: _kategoriList.map((kategori) {
                    return DropdownMenuItem(
                      value: kategori,
                      child: Text(kategori.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedKategori = value!);
                  },
                ),
                
                // ============ STATUS (hanya saat edit) ============
                if (widget.menu != null) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedStatus,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.info),
                    ),
                    items: _statusList.map((status) {
                      return DropdownMenuItem(
                        value: status,
                        child: Text(status.toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedStatus = value!);
                    },
                  ),
                ],
                
                const SizedBox(height: 24),
                
                // ============ BUTTONS ============
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      child: const Text('Batal'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(widget.menu == null ? 'Tambah' : 'Update'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _namaController.dispose();
    _deskripsiController.dispose();
    _hargaController.dispose();
    super.dispose();
  }
}