using backend.Data;
using backend.Models;
using backend.Models.DTOs;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace backend.Controllers;

[Route("api/[controller]")]
[ApiController]
public class CategoryController : ControllerBase
{
    private readonly ApplicationDbContext _context;

    public CategoryController(ApplicationDbContext context)
    {
        _context = context;
    }

    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var categories = await _context.Categories.ToListAsync();
        return Ok(new { status = true, data = categories });
    }

    [HttpGet("{id}")]
    public async Task<IActionResult> GetById(int id)
    {
        var category = await _context.Categories.FindAsync(id);
        if (category == null) return NotFound(new { status = false, message = "Không tìm thấy danh mục" });
        return Ok(new { status = true, data = category });
    }

    [HttpPost]
    [Authorize]
    public async Task<IActionResult> Create([FromBody] CategoryDto dto)
    {
        if (!ModelState.IsValid) return BadRequest(ModelState);

        var category = new Category
        {
            Name = dto.Name,
            Description = dto.Description
        };

        _context.Categories.Add(category);
        await _context.SaveChangesAsync();
        return Ok(new { status = true, message = "Tạo danh mục thành công", data = category });
    }

    [HttpPut("{id}")]
    [Authorize]
    public async Task<IActionResult> Update(int id, [FromBody] CategoryDto dto)
    {
        if (!ModelState.IsValid) return BadRequest(ModelState);

        var category = await _context.Categories.FindAsync(id);
        if (category == null) return NotFound(new { status = false, message = "Không tìm thấy danh mục" });

        category.Name = dto.Name;
        category.Description = dto.Description;

        await _context.SaveChangesAsync();
        return Ok(new { status = true, message = "Cập nhật danh mục thành công", data = category });
    }

    [HttpDelete("{id}")]
    [Authorize]
    public async Task<IActionResult> Delete(int id)
    {
        var category = await _context.Categories.FindAsync(id);
        if (category == null) return NotFound(new { status = false, message = "Không tìm thấy danh mục" });

        _context.Categories.Remove(category);
        await _context.SaveChangesAsync(); // Products will have CategoryId set to null automatically

        return Ok(new { status = true, message = "Xóa danh mục thành công (các sản phẩm liên quan đã chuyển sang Chưa phân loại)" });
    }
}
