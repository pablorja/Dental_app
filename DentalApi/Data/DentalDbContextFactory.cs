using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;
namespace DentalApi.Data;
public sealed class DentalDbContextFactory : IDesignTimeDbContextFactory<DentalDbContext>
{
    public DentalDbContext CreateDbContext(string[] args)
    {
        var connectionString = Environment.GetEnvironmentVariable("ConnectionStrings__DentalDatabase")
            ?? "Host=localhost;Port=5432;Database=dental_api;Username=postgres;Password=design-time-only";
        var options = new DbContextOptionsBuilder<DentalDbContext>().UseNpgsql(connectionString).Options;
        return new DentalDbContext(options);
    }
}
