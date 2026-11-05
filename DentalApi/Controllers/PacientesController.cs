using DentalApi.Data;
using DentalApi.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace DentalApi.Controllers;

[ApiController]
[Route("api/[controller]")]
public sealed class PacientesController(DentalDbContext db) : ControllerBase
{
    [HttpGet]
    public async Task<ActionResult<IEnumerable<Paciente>>> GetAll(CancellationToken cancellationToken) =>
        Ok(await db.Pacientes.AsNoTracking().OrderBy(paciente => paciente.Nombre).ToListAsync(cancellationToken));

    [HttpGet("{id:int}")]
    public async Task<ActionResult<Paciente>> GetById(int id, CancellationToken cancellationToken)
    {
        var paciente = await db.Pacientes.AsNoTracking().FirstOrDefaultAsync(p => p.Id == id, cancellationToken);
        return paciente is null ? NotFound() : Ok(paciente);
    }

    [HttpPost]
    public async Task<ActionResult<Paciente>> Create(Paciente paciente, CancellationToken cancellationToken)
    {
        if (await db.Pacientes.AnyAsync(p => p.Documento == paciente.Documento, cancellationToken))
            return Conflict(new { mensaje = "Ya existe un paciente con ese documento." });

        paciente.Id = 0;
        paciente.CreadoEn = DateTime.UtcNow;
        db.Pacientes.Add(paciente);
        await db.SaveChangesAsync(cancellationToken);
        return CreatedAtAction(nameof(GetById), new { id = paciente.Id }, paciente);
    }

    [HttpPut("{id:int}")]
    public async Task<IActionResult> Update(int id, Paciente datos, CancellationToken cancellationToken)
    {
        var paciente = await db.Pacientes.FindAsync([id], cancellationToken);
        if (paciente is null) return NotFound();

        if (await db.Pacientes.AnyAsync(p => p.Id != id && p.Documento == datos.Documento, cancellationToken))
            return Conflict(new { mensaje = "Ya existe un paciente con ese documento." });

        paciente.Nombre = datos.Nombre;
        paciente.Documento = datos.Documento;
        paciente.Telefono = datos.Telefono;
        paciente.Correo = datos.Correo;
        paciente.Notas = datos.Notas;
        await db.SaveChangesAsync(cancellationToken);
        return NoContent();
    }

    [HttpDelete("{id:int}")]
    public async Task<IActionResult> Delete(int id, CancellationToken cancellationToken)
    {
        var paciente = await db.Pacientes.FindAsync([id], cancellationToken);
        if (paciente is null) return NotFound();

        db.Pacientes.Remove(paciente);
        await db.SaveChangesAsync(cancellationToken);
        return NoContent();
    }
}
