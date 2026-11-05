using System.ComponentModel.DataAnnotations;

namespace DentalApi.Models;

public sealed class Paciente
{
    public int Id { get; set; }
    [Required, StringLength(100)] public string Nombre { get; set; } = string.Empty;
    [Required, StringLength(30)] public string Documento { get; set; } = string.Empty;
    [Required, Phone, StringLength(30)] public string Telefono { get; set; } = string.Empty;
    [EmailAddress, StringLength(150)] public string? Correo { get; set; }
    [StringLength(1000)] public string? Notas { get; set; }
    public DateTime CreadoEn { get; set; } = DateTime.UtcNow;
    public ICollection<Cita> Citas { get; set; } = new List<Cita>();
}
