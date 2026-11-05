using DentalApi.Models;
using Microsoft.EntityFrameworkCore;

namespace DentalApi.Data;

public sealed class DentalDbContext(DbContextOptions<DentalDbContext> options) : DbContext(options)
{
    public DbSet<Paciente> Pacientes => Set<Paciente>();
    public DbSet<Odontologo> Odontologos => Set<Odontologo>();
    public DbSet<Cita> Citas => Set<Cita>();
    public DbSet<Tratamiento> Tratamientos => Set<Tratamiento>();
    public DbSet<CitaTratamiento> CitaTratamientos => Set<CitaTratamiento>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Paciente>().HasIndex(p => p.Documento).IsUnique();
        modelBuilder.Entity<Odontologo>().HasIndex(o => o.Documento).IsUnique();
        modelBuilder.Entity<Cita>(entity =>
        {
            entity.ToTable("Citas", table =>
            {
                table.HasCheckConstraint("CK_Citas_Fechas", "\"FechaFin\" > \"FechaInicio\"");
                table.HasCheckConstraint("CK_Citas_Estado",
                    "\"Estado\" IN ('Programada', 'Confirmada', 'EnCurso', 'Completada', 'Cancelada')");
            });
            entity.HasIndex(c => new { c.OdontologoId, c.FechaInicio });
            entity.HasIndex(c => new { c.PacienteId, c.FechaInicio });
            entity.HasOne(c => c.Paciente).WithMany(p => p.Citas)
                .HasForeignKey(c => c.PacienteId).OnDelete(DeleteBehavior.Restrict);
            entity.HasOne(c => c.Odontologo).WithMany(o => o.Citas)
                .HasForeignKey(c => c.OdontologoId).OnDelete(DeleteBehavior.Restrict);
        });
        modelBuilder.Entity<Tratamiento>(entity =>
        {
            entity.ToTable("Tratamientos", table =>
            {
                table.HasCheckConstraint("CK_Tratamientos_PrecioBase", "\"PrecioBase\" >= 0");
                table.HasCheckConstraint("CK_Tratamientos_Duracion", "\"DuracionMinutos\" > 0");
            });
            entity.Property(t => t.PrecioBase).HasPrecision(10, 2);
            entity.HasIndex(t => t.Nombre).IsUnique();
        });
        modelBuilder.Entity<CitaTratamiento>(entity =>
        {
            entity.ToTable("CitaTratamientos", table =>
                table.HasCheckConstraint("CK_CitaTratamientos_PrecioAplicado", "\"PrecioAplicado\" >= 0"));
            entity.Property(d => d.PrecioAplicado).HasPrecision(10, 2);
            entity.HasOne(d => d.Cita).WithMany(c => c.Tratamientos)
                .HasForeignKey(d => d.CitaId).OnDelete(DeleteBehavior.Cascade);
            entity.HasOne(d => d.Tratamiento).WithMany(t => t.Citas)
                .HasForeignKey(d => d.TratamientoId).OnDelete(DeleteBehavior.Restrict);
        });
    }
}

