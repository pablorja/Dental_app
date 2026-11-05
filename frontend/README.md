# DentalCare Flutter

Frontend Flutter para administrar pacientes usando la API REST DentalApi.

## Funciones

- Listado con búsqueda por nombre, documento, teléfono y correo.
- Crear, editar y eliminar pacientes con confirmación.
- Validación de datos y mensajes cuando la API devuelve errores.
- Interfaz adaptable a móvil, tableta, navegador y escritorio.

## Ejecutar

Desde esta carpeta:

```powershell
flutter pub get
flutter run
```

La app usa `http://localhost:5181/api/pacientes` en Flutter Web y escritorio, y `http://10.0.2.2:5181/api/pacientes` en el emulador Android.
En un teléfono físico, configura la IP local del computador:

```powershell
flutter run --dart-define=API_BASE_URL=http://IP_DEL_PC:5181/api/pacientes
```

También puedes sobrescribir la URL para cualquier plataforma con `API_BASE_URL`.
La API debe estar ejecutándose y aceptar solicitudes CORS para Flutter Web.

