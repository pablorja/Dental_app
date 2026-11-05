# Dental App

Aplicación para administrar pacientes de una clínica odontológica. El repositorio contiene el frontend Flutter, la API REST en ASP.NET Core y el esquema PostgreSQL.

## Componentes

- **Frontend:** Flutter para web, Android e iOS. Permite listar y buscar pacientes, crear registros, editarlos y eliminarlos.
- **API:** ASP.NET Core 10 con Entity Framework Core y PostgreSQL. El CRUD disponible es `api/pacientes`.
- **Base de datos:** PostgreSQL. El modelo contempla pacientes, odontólogos, citas y tratamientos; las citas relacionan pacientes y odontólogos, y `CitaTratamientos` registra los tratamientos realizados en cada cita.
- **Postman:** `DentalApi/DentalApi.postman_collection.json` contiene las solicitudes de ejemplo para el CRUD de pacientes.

## Requisitos

- .NET SDK 10.
- Flutter SDK y Dart.
- PostgreSQL 18 (o una versión compatible con Npgsql).
- Google Chrome para ejecutar la versión web.

## Configurar y ejecutar la API

1. Crea una base llamada `dental_api` en PostgreSQL. El script `dental_api_postgresql.sql` documenta el esquema para una base vacía; en este proyecto se recomienda aplicar el esquema con las migraciones de Entity Framework.
2. Abre PowerShell en la carpeta del repositorio y configura la cadena para la sesión actual. Sustituye `TU_PASSWORD` por la contraseña local de PostgreSQL; no guardes esa contraseña en Git:

   ```powershell
   $env:ConnectionStrings__DentalDatabase = "Host=localhost;Port=5432;Database=dental_api;Username=postgres;Password=TU_PASSWORD"
   cd .\DentalApi
   dotnet restore
   dotnet run --launch-profile http
   ```

   En el entorno `Development`, la API aplica automáticamente las migraciones pendientes al iniciar.

3. Comprueba que la API responda en `http://localhost:5181/api/pacientes`.

## Ejecutar Flutter Web

En otra terminal, desde la raíz del repositorio:

```powershell
cd .\frontend
flutter pub get
flutter run --profile -d chrome --dart-define=API_BASE_URL=http://localhost:5181/api/pacientes
```

La app usa `localhost:5181` por defecto en web y escritorio, y `10.0.2.2:5181` en emuladores Android. Para un teléfono físico, configura `API_BASE_URL` con la IP local del computador y permite que la API reciba conexiones desde la red.

## Endpoints de pacientes

| Método | Ruta | Acción |
| --- | --- | --- |
| GET | `/api/pacientes` | Lista pacientes |
| GET | `/api/pacientes/{id}` | Consulta un paciente |
| POST | `/api/pacientes` | Crea un paciente |
| PUT | `/api/pacientes/{id}` | Actualiza un paciente |
| DELETE | `/api/pacientes/{id}` | Elimina un paciente |

Para crear o actualizar se envían `nombre`, `documento`, `telefono`, `correo` y `notas`. `documento` debe ser único.

## Seguridad y datos locales

La cadena de conexión se proporciona mediante `ConnectionStrings__DentalDatabase`. No subas contraseñas, bases de datos locales, registros de pacientes, archivos `appsettings.Development.json`, `bin/`, `obj/`, ni artefactos de compilación Flutter. El `.gitignore` del repositorio excluye esos archivos.
