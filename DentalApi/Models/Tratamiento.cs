using System.ComponentModel.DataAnnotations;
namespace DentalApi.Models;
public sealed class Tratamiento
{
    public int Id { get; set; }
    [Required, StringLength(120)] public string Nombre { get; set; } = string.Empty;
    [StringLength(1000)] public string? Descripcion { get; set; }
    public decimal PrecioBase { get; set; }
    public int DuracionMinutos { get; set; }
    public bool Activo { get; set; } = true;
    public ICollection<CitaTratamiento> Citas { get; set; } = new List<CitaTratamiento>();
}
