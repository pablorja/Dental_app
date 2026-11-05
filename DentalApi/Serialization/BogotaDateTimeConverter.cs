using System.Globalization;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace DentalApi.Serialization;

public sealed class BogotaDateTimeConverter : JsonConverter<DateTime>
{
    private static readonly TimeZoneInfo BogotaTimeZone = TimeZoneInfo.FindSystemTimeZoneById(
        OperatingSystem.IsWindows() ? "SA Pacific Standard Time" : "America/Bogota");

    public override DateTime Read(ref Utf8JsonReader reader, Type typeToConvert, JsonSerializerOptions options)
    {
        if (reader.TokenType != JsonTokenType.String)
            throw new JsonException("La fecha debe enviarse como texto ISO 8601.");

        var text = reader.GetString();
        if (string.IsNullOrWhiteSpace(text))
            throw new JsonException("La fecha no puede estar vacía.");

        var hasExplicitOffset = text.EndsWith("Z", StringComparison.OrdinalIgnoreCase)
            || (text.Length >= 6 && (text[^6] == '+' || text[^6] == '-'));

        if (hasExplicitOffset)
        {
            if (!DateTimeOffset.TryParse(text, CultureInfo.InvariantCulture, DateTimeStyles.None, out var dateWithOffset))
                throw new JsonException("La fecha debe tener un desplazamiento válido, por ejemplo -05:00 o Z.");

            return dateWithOffset.UtcDateTime;
        }

        if (!DateTime.TryParse(text, CultureInfo.InvariantCulture, DateTimeStyles.None, out var localDate))
            throw new JsonException("La fecha debe tener formato ISO 8601.");

        var bogotaLocalDate = DateTime.SpecifyKind(localDate, DateTimeKind.Unspecified);
        return TimeZoneInfo.ConvertTimeToUtc(bogotaLocalDate, BogotaTimeZone);
    }

    public override void Write(Utf8JsonWriter writer, DateTime value, JsonSerializerOptions options)
    {
        var utcDate = value.Kind switch
        {
            DateTimeKind.Utc => value,
            DateTimeKind.Local => value.ToUniversalTime(),
            _ => DateTime.SpecifyKind(value, DateTimeKind.Utc)
        };

        var bogotaDate = TimeZoneInfo.ConvertTimeFromUtc(utcDate, BogotaTimeZone);
        var offset = new DateTimeOffset(bogotaDate, BogotaTimeZone.GetUtcOffset(bogotaDate));
        writer.WriteStringValue(offset.ToString("yyyy-MM-dd'T'HH:mm:ss.fffzzz", CultureInfo.InvariantCulture));
    }
}
