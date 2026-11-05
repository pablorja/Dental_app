using System.ComponentModel.DataAnnotations;
namespace DentalApi.Models;
public sealed class Odontologo
{
    public int Id { get; set; }
    [Required, StringLength(100)] public string Nombre { get; set; } = string.Empty;
    [Required, StringLength(30)] public string Documento { get; set; } = string.Empty;
    [StringLength(100)] public string? Especialidad { get; set; }
    [Phone, StringLength(30)] public string? Telefono { get; set; }
    [EmailAddress, StringLength(150)] public string? Correo { get; set; }
    public bool Activo { get; set; } = true;
    public ICollection<Cita> Citas { get; set; } = new List<Cita>();
}
