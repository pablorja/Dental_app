using System.ComponentModel.DataAnnotations;
namespace DentalApi.Models;
public sealed class CitaTratamiento
{
    public int Id { get; set; }
    [Required] public int CitaId { get; set; }
    [Required] public int TratamientoId { get; set; }
    [StringLength(10)] public string? PiezaDental { get; set; }
    public decimal PrecioAplicado { get; set; }
    [StringLength(1000)] public string? Notas { get; set; }
    public Cita Cita { get; set; } = null!;
    public Tratamiento Tratamiento { get; set; } = null!;
}
