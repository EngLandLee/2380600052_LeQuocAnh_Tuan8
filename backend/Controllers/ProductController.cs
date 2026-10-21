using backend.Data;
using backend.Models;
using backend.Models.DTOs;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace backend.Controllers;

[Route("api/[controller]")]
[ApiController]
[Authorize] // Phân quyền lấy danh sách sản phẩm theo bài tập về nhà
public class ProductController : ControllerBase
{
    private readonly ApplicationDbContext _context;

    public ProductController(ApplicationDbContext context)
    {
        _context = context;
    }

    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var products = await _context.Products.Include(p => p.Category).ToListAsync();
        return Ok(new { status = true, data = products });
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> GetById(int id)
    {
        var product = await _context.Products.Include(p => p.Category).FirstOrDefaultAsync(p => p.Id == id);
        if (product == null) return NotFound(new { status = false, message = "Không tìm thấy sản phẩm" });
        return Ok(new { status = true, data = product });
    }

    [HttpPost]
    [Authorize]
    public async Task<IActionResult> Create([FromBody] ProductDto dto)
    {
        if (!ModelState.IsValid) return BadRequest(ModelState);

        var product = new Product
        {
            Name = dto.Name,
            Price = dto.Price,
            Description = dto.Description,
            CategoryId = dto.CategoryId
        };

        _context.Products.Add(product);
        await _context.SaveChangesAsync();
        return Ok(new { status = true, message = "Thêm sản phẩm thành công", data = product });
    }

    [HttpPut("{id}")]
    [Authorize]
    public async Task<IActionResult> Update(int id, [FromBody] ProductDto dto)
    {
        if (!ModelState.IsValid) return BadRequest(ModelState);

        var product = await _context.Products.FindAsync(id);
        if (product == null) return NotFound(new { status = false, message = "Không tìm thấy sản phẩm" });

        product.Name = dto.Name;
        product.Price = dto.Price;
        product.Description = dto.Description;
        product.CategoryId = dto.CategoryId;

        await _context.SaveChangesAsync();
        return Ok(new { status = true, message = "Cập nhật sản phẩm thành công", data = product });
    }

    [HttpDelete("{id}")]
    [Authorize]
    public async Task<IActionResult> Delete(int id)
    {
        var product = await _context.Products.FindAsync(id);
        if (product == null) return NotFound(new { status = false, message = "Không tìm thấy sản phẩm" });

        _context.Products.Remove(product);
        await _context.SaveChangesAsync();
        return Ok(new { status = true, message = "Xóa sản phẩm thành công" });
    }

    [HttpPost("seed-sample-data")]
    [Authorize]
    public async Task<IActionResult> SeedSampleData()
    {
        if (await _context.Products.AnyAsync())
        {
            return Ok(new { status = true, message = "Dữ liệu sản phẩm đã tồn tại trong hệ thống." });
        }

        // Tạo danh mục mẫu nếu chưa có
        var catTech = await _context.Categories.FirstOrDefaultAsync(c => c.Name == "Thiết Bị Công Nghệ")
                      ?? new Category { Name = "Thiết Bị Công Nghệ", Description = "Laptop, Máy tính bảng, Điện thoại di động" };
        var catOffice = await _context.Categories.FirstOrDefaultAsync(c => c.Name == "Thiết Bị Văn Phòng")
                        ?? new Category { Name = "Thiết Bị Văn Phòng", Description = "Máy in, Máy scan, Bàn ghế công thái học" };
        var catAccessory = await _context.Categories.FirstOrDefaultAsync(c => c.Name == "Phụ Kiện & Mạng")
                           ?? new Category { Name = "Phụ Kiện & Mạng", Description = "Router Wi-Fi 6, Cáp LAN, Bàn phím cơ" };

        if (catTech.Id == 0) _context.Categories.Add(catTech);
        if (catOffice.Id == 0) _context.Categories.Add(catOffice);
        if (catAccessory.Id == 0) _context.Categories.Add(catAccessory);
        await _context.SaveChangesAsync();

        var sampleProducts = new List<Product>
        {
            new() { Name = "Laptop Dell XPS 15 OLED", Price = 42500000, Description = "Core i7 Gen 13, 32GB RAM, 1TB NVMe, Card đồ họa RTX 4060", CategoryId = catTech.Id },
            new() { Name = "Màn hình Dell UltraSharp 27 4K", Price = 13800000, Description = "Tấm nền IPS Black, Độ phân giải 4K UHD, Type-C 90W PD", CategoryId = catTech.Id },
            new() { Name = "Máy in laser đa năng HP LaserJet Pro", Price = 6200000, Description = "In 2 mặt tự động, kết nối Wi-Fi & Ethernet, tốc độ 30 trang/phút", CategoryId = catOffice.Id },
            new() { Name = "Bàn làm việc nâng hạ thông minh Epione", Price = 8500000, Description = "Mặt bàn gỗ sồi 1m6, 2 động cơ điện êm ái, ghi nhớ 4 vị trí", CategoryId = catOffice.Id },
            new() { Name = "Router Wi-Fi 6 Asus RT-AX86U Pro", Price = 4900000, Description = "Băng thông AX5700, cổng 2.5G WAN/LAN, vùng phủ sóng rộng", CategoryId = catAccessory.Id },
            new() { Name = "Bàn phím cơ Keychron K8 Pro", Price = 2450000, Description = "Switch Gateron G Pro Brown, hỗ trợ QMK/VIA, Bluetooth 5.1", CategoryId = catAccessory.Id },
        };

        _context.Products.AddRange(sampleProducts);
        await _context.SaveChangesAsync();

        return Ok(new { status = true, message = "Đã khởi tạo dữ liệu mẫu thành công với 6 sản phẩm và 3 danh mục!", count = sampleProducts.Count });
    }
}
