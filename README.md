# Lobmindergo - Activities Notifier

App Flutter para gestionar tareas y notificaciones programadas.

## Comandos

### Desarrollo
```bash
# Instalar dependencias
flutter pub get

# Ejecutar en dispositivo/emulador
flutter run -d {device_name}

# Build debug APK
flutter build apk --debug
```

### Producción
```bash
# Build release APK
flutter build apk --release
```

## Funcionalidades (Junio 2026)

### Tareas
- ✅ Ver lista de tareas del cronograma actual
- ✅ Crear nueva tarea con proyecto, hora y minuto
- ✅ Editar tarea (deslizar a la derecha)
- ✅ Eliminar tarea (deslizar a la izquierda)
- ✅ Completar/descompletar tarea (tocar)
- ✅ Animación fade-in al cargar tareas

### Cronogramas
- ✅ Selector de cronograma en menú lateral
- ✅ Cargar automáticamente el cronograma del día
- ✅ Mostrar fecha y progreso del cronograma

### Notificaciones
- ✅ Programar notificaciones según hora de cada tarea
- ✅ Notificaciones con sonido y vibración
- ✅ Zona horaria: Bogotá (America/Bogota)
- ✅ Usar fecha del cronograma (no fecha actual)
- ✅ Check automático cada hora para reprogramar
- ✅ Skip tareas pasadas o ya completadas

### UI/UX
- ✅ Theme oscuro con acentos en azul (#2196F3)
- ✅ Banner de estado con animación
- ✅ Spinner de carga en acciones
- ✅ Efectos visuales en cards

### Configuración
- ✅ Activar/desactivar sonido
- ✅ Activar/desactivar vibración

## Permisos Android

- INTERNET
- POST_NOTIFICATIONS
- VIBRATE
- RECEIVE_BOOT_COMPLETED
- WAKE_LOCK
- SCHEDULE_EXACT_ALARM
- USE_EXACT_ALARM
