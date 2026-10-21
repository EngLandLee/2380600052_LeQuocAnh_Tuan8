import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../services/category_service.dart';
import '../services/product_service.dart';

class CrudManagementScreen extends StatefulWidget {
  const CrudManagementScreen({super.key});

  @override
  State<CrudManagementScreen> createState() => _CrudManagementScreenState();
}

class _CrudManagementScreenState extends State<CrudManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ProductService _productService = ProductService();
  final CategoryService _categoryService = CategoryService();

  List<Product> _products = [];
  List<Category> _categories = [];
  bool _isLoading = true;

  // Search & Filter
  String _searchQuery = '';
  int? _selectedCategoryId;

  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

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
    final prods = await _productService.getAll();
    final cats = await _categoryService.getAll();
    if (mounted) {
      setState(() {
        _products = prods;
        _categories = cats;
        _isLoading = false;
      });
    }
  }

  List<Product> get _filteredProducts {
    return _products.where((p) {
      final matchesSearch = _searchQuery.isEmpty ||
          p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (p.description != null &&
              p.description!.toLowerCase().contains(_searchQuery.toLowerCase()));
      final matchesCat = _selectedCategoryId == null || p.categoryId == _selectedCategoryId;
      return matchesSearch && matchesCat;
    }).toList();
  }

  // --- CRUD SẢN PHẨM ---
  Future<void> _openProductDialog({Product? product}) async {
    final nameCtrl = TextEditingController(text: product?.name ?? '');
    final priceCtrl = TextEditingController(text: product?.price.toString() ?? '');
    final descCtrl = TextEditingController(text: product?.description ?? '');
    int? selectedCat = product?.categoryId ?? (_categories.isNotEmpty ? _categories.first.id : null);

    final isEdit = product != null;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFF1E293B),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(
                        isEdit ? Icons.edit_note_rounded : Icons.add_box_rounded,
                        color: const Color(0xFF818CF8),
                        size: 28,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        isEdit ? 'Chỉnh Sửa Sản Phẩm' : 'Thêm Sản Phẩm Mới',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: nameCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      labelText: 'Tên sản phẩm *',
                      labelStyle: const TextStyle(color: Color(0xFF818CF8)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: priceCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      labelText: 'Giá tiền (VNĐ) *',
                      labelStyle: const TextStyle(color: Color(0xFF818CF8)),
                      suffixText: 'VNĐ',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<int?>(
                    dropdownColor: const Color(0xFF1E293B),
                    initialValue: selectedCat,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      labelText: 'Danh mục',
                      labelStyle: const TextStyle(color: Color(0xFF818CF8)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Chưa phân loại', style: TextStyle(color: Colors.white54)),
                      ),
                      ..._categories.map((c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.name, style: const TextStyle(color: Colors.white)),
                          )),
                    ],
                    onChanged: (val) => setSheetState(() => selectedCat = val),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: descCtrl,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      labelText: 'Mô tả chi tiết',
                      labelStyle: const TextStyle(color: Color(0xFF818CF8)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () async {
                        final name = nameCtrl.text.trim();
                        final price = double.tryParse(priceCtrl.text) ?? 0;
                        final desc = descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim();

                        if (name.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Vui lòng nhập tên sản phẩm'),
                              backgroundColor: Color(0xFFEF4444),
                            ),
                          );
                          return;
                        }

                        bool success = false;
                        if (isEdit) {
                          success = await _productService.update(
                            product.id,
                            name,
                            price,
                            desc,
                            selectedCat,
                          );
                        } else {
                          success = await _productService.create(
                            name,
                            price,
                            desc,
                            selectedCat,
                          );
                        }

                        if (!mounted) return;
                        if (ctx.mounted) Navigator.pop(ctx);

                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(isEdit
                                  ? 'Đã cập nhật sản phẩm thành công!'
                                  : 'Đã thêm sản phẩm mới thành công!'),
                              backgroundColor: const Color(0xFF10B981),
                            ),
                          );
                          _loadData();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Thao tác không thành công. Vui lòng thử lại.'),
                              backgroundColor: Color(0xFFEF4444),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(
                        isEdit ? 'Lưu Thay Đổi' : 'Tạo Sản Phẩm',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteProduct(Product product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Xác nhận xóa', style: TextStyle(color: Colors.white)),
        content: Text(
          'Bạn có chắc chắn muốn xóa sản phẩm "${product.name}" không?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _productService.delete(product.id);
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã xóa "${product.name}" thành công'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
        _loadData();
      }
    }
  }

  // --- CRUD DANH MỤC ---
  Future<void> _openCategoryDialog({Category? category}) async {
    final nameCtrl = TextEditingController(text: category?.name ?? '');
    final descCtrl = TextEditingController(text: category?.description ?? '');
    final isEdit = category != null;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Color(0xFF1E293B),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    isEdit ? Icons.edit_note_rounded : Icons.create_new_folder_rounded,
                    color: const Color(0xFF38BDF8),
                    size: 28,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isEdit ? 'Chỉnh Sửa Danh Mục' : 'Thêm Danh Mục Mới',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: nameCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  labelText: 'Tên danh mục *',
                  labelStyle: const TextStyle(color: Color(0xFF38BDF8)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: descCtrl,
                maxLines: 2,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  labelText: 'Mô tả danh mục',
                  labelStyle: const TextStyle(color: Color(0xFF38BDF8)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    final name = nameCtrl.text.trim();
                    final desc = descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim();
                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Vui lòng nhập tên danh mục'),
                          backgroundColor: Color(0xFFEF4444),
                        ),
                      );
                      return;
                    }

                    bool success = false;
                    if (isEdit) {
                      success = await _categoryService.update(category.id, name, desc);
                    } else {
                      success = await _categoryService.create(name, desc);
                    }

                    if (!mounted) return;
                    if (ctx.mounted) Navigator.pop(ctx);

                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isEdit
                              ? 'Đã cập nhật danh mục thành công!'
                              : 'Đã thêm danh mục mới thành công!'),
                          backgroundColor: const Color(0xFF10B981),
                        ),
                      );
                      _loadData();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    isEdit ? 'Lưu Thay Đổi' : 'Tạo Danh Mục',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteCategory(Category category) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Xác nhận xóa', style: TextStyle(color: Colors.white)),
        content: Text(
          'Bạn có chắc muốn xóa danh mục "${category.name}"?\n(Các sản phẩm thuộc danh mục này sẽ chuyển sang trạng thái Chưa phân loại).',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _categoryService.delete(category.id);
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã xóa danh mục "${category.name}"'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
        _loadData();
      }
    }
  }

  // --- SEED SAMPLE DATA ---
  Future<void> _seedSampleData() async {
    setState(() => _isLoading = true);
    final ok = await _productService.seedSampleData();
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Khởi tạo 6 sản phẩm và 3 danh mục mẫu thành công!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    }
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text(
          'Quản Lý Kho Hàng & Danh Mục',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_fix_high_rounded, color: Color(0xFFF59E0B)),
            tooltip: 'Khởi tạo dữ liệu mẫu (Seed Data)',
            onPressed: _seedSampleData,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Tải lại',
            onPressed: _loadData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF6366F1),
          indicatorWeight: 3,
          labelColor: const Color(0xFF818CF8),
          unselectedLabelColor: Colors.white54,
          tabs: [
            Tab(
              icon: const Icon(Icons.inventory_2_rounded),
              text: 'Sản Phẩm (${_products.length})',
            ),
            Tab(
              icon: const Icon(Icons.category_rounded),
              text: 'Danh Mục (${_categories.length})',
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_tabController.index == 0) {
            _openProductDialog();
          } else {
            _openCategoryDialog();
          }
        },
        backgroundColor: const Color(0xFF6366F1),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          _tabController.index == 0 ? 'Thêm Sản Phẩm' : 'Thêm Danh Mục',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildProductsTab(),
                _buildCategoriesTab(),
              ],
            ),
    );
  }

  Widget _buildProductsTab() {
    final filtered = _filteredProducts;
    final totalValue = _products.fold<double>(0, (sum, p) => sum + p.price);

    return RefreshIndicator(
      onRefresh: _loadData,
      color: const Color(0xFF6366F1),
      child: Column(
        children: [
          // Search & Summary Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            color: const Color(0xFF1E293B),
            child: Column(
              children: [
                // Search Box
                TextField(
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm sản phẩm theo tên, mô tả...',
                    hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                    prefixIcon: const Icon(Icons.search, color: Color(0xFF818CF8)),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.white54, size: 18),
                            onPressed: () => setState(() => _searchQuery = ''),
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
                const SizedBox(height: 12),

                // Quick stats
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Tổng số lượng', style: TextStyle(color: Colors.white38, fontSize: 10)),
                            Text(
                              '${_products.length} sản phẩm',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Tổng giá trị', style: TextStyle(color: Colors.white38, fontSize: 10)),
                            Text(
                              _currencyFormat.format(totalValue),
                              style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Horizontal Category filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        selected: _selectedCategoryId == null,
                        label: const Text('Tất cả'),
                        labelStyle: TextStyle(
                          color: _selectedCategoryId == null ? Colors.white : Colors.white70,
                          fontSize: 12,
                        ),
                        backgroundColor: const Color(0xFF0F172A),
                        selectedColor: const Color(0xFF6366F1),
                        checkmarkColor: Colors.white,
                        onSelected: (_) => setState(() => _selectedCategoryId = null),
                      ),
                      const SizedBox(width: 8),
                      ..._categories.map((c) {
                        final isSel = _selectedCategoryId == c.id;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            selected: isSel,
                            label: Text(c.name),
                            labelStyle: TextStyle(
                              color: isSel ? Colors.white : Colors.white70,
                              fontSize: 12,
                            ),
                            backgroundColor: const Color(0xFF0F172A),
                            selectedColor: const Color(0xFF6366F1),
                            checkmarkColor: Colors.white,
                            onSelected: (_) => setState(() {
                              _selectedCategoryId = isSel ? null : c.id;
                            }),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Product List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.inventory_2_outlined, size: 56, color: Colors.white24),
                        const SizedBox(height: 12),
                        Text(
                          _products.isEmpty
                              ? 'Chưa có sản phẩm nào trong kho'
                              : 'Không tìm thấy sản phẩm phù hợp',
                          style: const TextStyle(color: Colors.white54, fontSize: 15),
                        ),
                        const SizedBox(height: 16),
                        if (_products.isEmpty)
                          ElevatedButton.icon(
                            onPressed: _seedSampleData,
                            icon: const Icon(Icons.auto_fix_high),
                            label: const Text('Nạp Dữ Liệu Mẫu (6 Sản Phẩm)'),
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1)),
                          ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, idx) {
                      final p = filtered[idx];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF6366F1).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.devices_rounded,
                                      color: Color(0xFF818CF8),
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          p.name,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _currencyFormat.format(p.price),
                                          style: const TextStyle(
                                            color: Color(0xFF10B981),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Category badge
                                  if (p.category != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        p.category!.name,
                                        style: const TextStyle(
                                          color: Color(0xFF38BDF8),
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              if (p.description != null && p.description!.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Text(
                                  p.description!,
                                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                                ),
                              ],
                              const Divider(color: Colors.white12, height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton.icon(
                                    onPressed: () => _openProductDialog(product: p),
                                    icon: const Icon(Icons.edit_rounded, size: 16, color: Color(0xFF818CF8)),
                                    label: const Text('Chỉnh sửa', style: TextStyle(color: Color(0xFF818CF8))),
                                  ),
                                  const SizedBox(width: 8),
                                  TextButton.icon(
                                    onPressed: () => _confirmDeleteProduct(p),
                                    icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFEF4444)),
                                    label: const Text('Xóa', style: TextStyle(color: Color(0xFFEF4444))),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: const Color(0xFF0284C7),
      child: _categories.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.folder_open_rounded, size: 56, color: Colors.white24),
                  const SizedBox(height: 12),
                  const Text('Chưa có danh mục nào', style: TextStyle(color: Colors.white54, fontSize: 15)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _openCategoryDialog(),
                    icon: const Icon(Icons.add),
                    label: const Text('Tạo Danh Mục Đầu Tiên'),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0284C7)),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              itemCount: _categories.length,
              itemBuilder: (ctx, idx) {
                final cat = _categories[idx];
                final count = _products.where((p) => p.categoryId == cat.id).length;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.category_rounded, color: Color(0xFF38BDF8), size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cat.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            if (cat.description != null && cat.description!.isNotEmpty)
                              Text(
                                cat.description!,
                                style: const TextStyle(color: Colors.white54, fontSize: 12),
                              ),
                            const SizedBox(height: 4),
                            Text(
                              '$count sản phẩm liên kết',
                              style: const TextStyle(
                                color: Color(0xFF818CF8),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_rounded, color: Color(0xFF818CF8)),
                        tooltip: 'Sửa danh mục',
                        onPressed: () => _openCategoryDialog(category: cat),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
                        tooltip: 'Xóa danh mục',
                        onPressed: () => _confirmDeleteCategory(cat),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
