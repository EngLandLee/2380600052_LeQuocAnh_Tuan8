using System.ComponentModel.DataAnnotations;

namespace backend.Models.DTOs;

public class ProductDto
{
    [Required, MaxLength(150)]
    public string Name { get; set; } = string.Empty;

    public decimal Price { get; set; }

    public string? Description { get; set; }

    public int? CategoryId { get; set; }
}
