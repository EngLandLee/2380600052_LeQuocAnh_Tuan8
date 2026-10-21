using System.ComponentModel.DataAnnotations;

namespace backend.Models.DTOs;

public class CategoryDto
{
    [Required, MaxLength(100)]
    public string Name { get; set; } = string.Empty;

    public string? Description { get; set; }
}
