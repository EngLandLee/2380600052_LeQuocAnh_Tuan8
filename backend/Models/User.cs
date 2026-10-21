using Microsoft.AspNetCore.Identity;
using System.ComponentModel.DataAnnotations;

namespace backend.Models;

public class User : IdentityUser
{
    [MaxLength(5)]
    public string? Initials { get; set; }
}
