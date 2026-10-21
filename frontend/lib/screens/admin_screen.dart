import 'package:flutter/material.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../services/category_service.dart';
import '../services/product_service.dart';
import '../utils/auth_helper.dart';
import 'login_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _categoryService = CategoryService();
  final _productService = ProductService();

  List<Category> _categories = [];
  List<Product> _products = [];
  bool _isLoading = true;
  String _username = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final username = await AuthHelper.getUsername();
    final categories = await _categoryService.getAll();
    final products = await _productService.getAll();
    if (!mounted) return;
    setState(() {
      _username = username;
      _categories = categories;
      _products = products;
      _isLoading = false;
    });
  }

  Future<void> _handleLogout() async {
    await AuthHelper.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _showCategoryDialog({Category? category}) {
    final nameController = TextEditingController(text: category?.name ?? '');
    final descController = TextEditingController(text: category?.description ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(category == null ? 'Thêm Danh Mục' : 'Sửa Danh Mục'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Tên danh mục *', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: 'Mô tả', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) return;
              Navigator.pop(context);

              if (category == null) {
                await _categoryService.create(nameController.text.trim(), descController.text.trim());
              } else {
                await _categoryService.update(category.id, nameController.text.trim(), descController.text.trim());
              }
              _loadData();
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteCategory(Category category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa danh mục'),
        content: Text(
          'Bạn có chắc muốn xóa danh mục "${category.name}"?\n\n'
          'Lưu ý: Các sản phẩm thuộc danh mục này sẽ không bị xóa mà chuyển sang trạng thái "Chưa phân loại".',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              final success = await _categoryService.delete(category.id);
              messenger.showSnackBar(
                SnackBar(
                  content: Text(success ? 'Đã xóa danh mục thành công' : 'Xóa danh mục thất bại'),
                  backgroundColor: success ? Colors.green : Colors.red,
                ),
              );
              _loadData();
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Panel ($_username)'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới',
            onPressed: _loadData,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
            onPressed: _handleLogout,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          indicatorColor: Colors.amber,
          tabs: const [
            Tab(icon: Icon(Icons.category), text: 'Quản Lý Danh Mục'),
            Tab(icon: Icon(Icons.inventory), text: 'Danh Sách Sản Phẩm'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Danh mục
                Scaffold(
                  floatingActionButton: FloatingActionButton.extended(
                    onPressed: () => _showCategoryDialog(),
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    icon: const Icon(Icons.add),
                    label: const Text('Thêm Danh Mục'),
                  ),
                  body: _categories.isEmpty
                      ? const Center(child: Text('Chưa có danh mục nào. Hãy nhấn nút thêm!'))
                      : ListView.builder(
                          padding: const EdgeInsets.only(left: 12, right: 12, top: 12, bottom: 80),
                          itemCount: _categories.length,
                          itemBuilder: (context, index) {
                            final cat = _categories[index];
                            return Card(
                              elevation: 2,
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.indigo[100],
                                  child: const Icon(Icons.folder, color: Colors.indigo),
                                ),
                                title: Text(cat.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text(cat.description ?? 'Không có mô tả'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blue),
                                      tooltip: 'Sửa danh mục',
                                      onPressed: () => _showCategoryDialog(category: cat),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      tooltip: 'Xóa danh mục',
                                      onPressed: () => _confirmDeleteCategory(cat),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
                // Tab 2: Sản phẩm
                _products.isEmpty
                    ? const Center(child: Text('Chưa có sản phẩm nào'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _products.length,
                        itemBuilder: (context, index) {
                          final p = _products[index];
                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.teal[100],
                                child: const Icon(Icons.shopping_cart, color: Colors.teal),
                              ),
                              title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('Danh mục: ${p.category?.name ?? "Chưa phân loại"}'),
                              trailing: Text(
                                '${p.price.toStringAsFixed(0)} đ',
                                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                              ),
                            ),
                          );
                        },
                      ),
              ],
            ),
    );
  }
}
