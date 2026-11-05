using System.ComponentModel.DataAnnotations;
namespace DentalApi.Models;
public sealed class Cita
{
    public int Id { get; set; }
    [Required] public int PacienteId { get; set; }
    [Required] public int OdontologoId { get; set; }
    public DateTime FechaInicio { get; set; }
    public DateTime FechaFin { get; set; }
    [Required, StringLength(30)] public string Estado { get; set; } = "Programada";
    [StringLength(1000)] public string? Motivo { get; set; }
    [StringLength(1000)] public string? Notas { get; set; }
    public DateTime CreadoEn { get; set; } = DateTime.UtcNow;
    public Paciente Paciente { get; set; } = null!;
    public Odontologo Odontologo { get; set; } = null!;
    public ICollection<CitaTratamiento> Tratamientos { get; set; } = new List<CitaTratamiento>();
}
