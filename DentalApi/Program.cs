using DentalApi.Data;
using DentalApi.Serialization;
using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);
var connectionString = builder.Configuration.GetConnectionString("DentalDatabase")
    ?? throw new InvalidOperationException(
        "Falta configurar ConnectionStrings:DentalDatabase. Consulta el README para configurar PostgreSQL.");
builder.Services.AddDbContext<DentalDbContext>(options => options.UseNpgsql(connectionString));
builder.Services.AddControllers().AddJsonOptions(options => options.JsonSerializerOptions.Converters.Add(new BogotaDateTimeConverter()));
builder.Services.AddCors(options => options.AddPolicy("Flutter", policy =>
    policy.AllowAnyOrigin().AllowAnyHeader().AllowAnyMethod()));

var app = builder.Build();
if (app.Environment.IsDevelopment())
{
    using var scope = app.Services.CreateScope();
    var db = scope.ServiceProvider.GetRequiredService<DentalDbContext>();
    await db.Database.MigrateAsync();
}
app.UseCors("Flutter");
app.MapControllers();
app.Run();

