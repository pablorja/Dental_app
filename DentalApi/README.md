# DentalApi para Flutter

API REST en ASP.NET Core 10. PostgreSQL guarda los datos y Entity Framework Core mantiene el esquema mediante migraciones.

## PostgreSQL local

La base dental_api fue creada en PostgreSQL 18 y la migración inicial ya está aplicada. appsettings.Development.json define el host, puerto, base y usuario; la contraseña se configura por variable de entorno para no guardarla en el proyecto.

En PowerShell, antes de iniciar la API:

$env:ConnectionStrings__DentalDatabase = "Host=localhost;Port=5432;Database=dental_api;Username=postgres;Password=TU_PASSWORD"
dotnet run --launch-profile http

La variable de entorno reemplaza la cadena base de appsettings.Development.json. No agregues la contraseña real al repositorio.

Para aplicar migraciones futuras:

dotnet ef database update

La API aplica migraciones automáticamente al iniciar en Development; en Production, ejecútalas primero desde el despliegue.

## Relaciones

- Paciente 1:N Citas.
- Odontólogo 1:N Citas.
- Cita 1:N CitaTratamientos.
- Tratamiento 1:N CitaTratamientos. Citas y tratamientos tienen relación N:M, y el detalle guarda precio aplicado, pieza dental y notas.
- Los documentos de pacientes y odontólogos son únicos.
- Se impide eliminar pacientes/odontólogos con citas o tratamientos ya usados. Al borrar una cita, se eliminan sus detalles.
- Estados válidos de cita: Programada, Confirmada, EnCurso, Completada y Cancelada.
- Fechas de cita en ISO 8601 UTC; por ejemplo: 2026-11-05T19:00:00Z.

## Endpoints actuales

El CRUD de pacientes sigue disponible en /api/pacientes y /api/pacientes/{id}.

## Formato de fechas

La API recibe fechas ISO 8601; sin desplazamiento se interpretan como hora de Colombia, y con Z o un desplazamiento explícito se convierten desde ese valor. Las respuestas incluyen el desplazamiento -05:00. PostgreSQL mantiene los instantes almacenados en UTC.
