# Plan de Implementación: Firebase Cloud Messaging (FCM)

## Objetivo
Reemplazar las notificaciones programadas locales (AndroidAlarmManager) con notificaciones push desde el servidor via FCM.

## Problemas actuales a resolver
- Teléfono debe estar prendido
- Honor/Huawei bloquean alarmas en segundo plano
- Sin internet no funciona
- AlarmManager puede fallar en Android 14+

## Solución: FCM
- ✅ Llega aunque teléfono esté apagado (cuando lo enciendan)
- ✅ No necesita permisos de alarma exacta
- ✅ Funciona con batería optimizada
- ✅ El servidor controla cuándo y qué enviar

---

## Paso 1: Configurar Firebase en el proyecto

1. Crear proyecto en [Firebase Console](https://console.firebase.google.com)
   - Nombre: `lobmindergo`
   - Package: `com.activities.activities_notifier_app`

2. Descargar `google-services.json` y colocar en:
   ```
   android/app/google-services.json
   ```

3. Agregar plugin al build.gradle (android/build.gradle.kts):
   ```kotlin
   plugins {
     id("com.google.gms.google-services") version "4.4.2" apply false
   }
   ```

4. Aplicar plugin en android/app/build.gradle.kts:
   ```kotlin
   plugins {
     id("com.google.gms.google-services")
   }
   ```

---

## Paso 2: Agregar dependencias

En `pubspec.yaml`:
```yaml
dependencies:
  firebase_core: ^3.12.0
  firebase_messaging: ^15.1.0
```

---

## Paso 3: Configurar Android

En `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>

<application>
  <service
    android:name="com.google.firebase.messaging.FcmService"
    android:exported="false">
    <intent-filter>
      <action android:name="com.google.firebase.MESSAGING_EVENT"/>
    </intent-filter>
  </service>
</application>
```

---

## Paso 4: Modificar NotificationService

Eliminar:
- Import de `android_alarm_manager_plus`
- Código de `_scheduleAlarm()`
- Código de `_alarmCallback()`

Agregar:
```dart
import 'package:firebase_messaging/firebase_messaging.dart';

Future<void> initialize() async {
  // ... código existente ...
  await _initFcm();
}

Future<void> _initFcm() async {
  final fcm = FirebaseMessaging.instance;
  
  // Pedir permisos
  final settings = await fcm.requestPermission();
  
  // Obtener token
  final token = await fcm.getToken();
  print('FCM Token: $token');
  
  // Guardar token en servidor (pendiente de implementar)
  
  // Escuchar mensajes
  FirebaseMessaging.onMessage.listen(_handleFcmMessage);
}

void _handleFcmMessage(RemoteMessage message) {
  final title = message.notification?.title ?? 'Tarea';
  final body = message.notification?.body ?? '';
  final data = message.data;
  
  // Mostrar notificación local
  _showNotification(title, body, data);
}
```

---

## Paso 5: Implementar en el servidor

### Guardar token FCM
Cuando el usuario inicia sesión, guardar el token FCM en la API:
```graphql
mutation UpdateFcmToken($userId: ID!, $token: String!) {
  updateFcmToken(userId: $userId, token: $token)
}
```

### Enviar notificación
El servidor envía POST a FCM:
```bash
curl -X POST https://fcm.googleapis.com/fcm/send \
  -H "Authorization: key=SERVER_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "to": "DISPOSITIVO_TOKEN",
    "notification": {
      "title": "Tarea: Completar informe",
      "body": "08:00 - Proyecto Alpha"
    },
    "data": {
      "taskId": "abc123",
      "cronId": "cron456"
    },
    "android": {
      "priority": "high",
      "notification": {
        "channelId": "task_alarm",
        "sound": "default"
      }
    }
  }'
```

---

## Costo estimado FCM

| Mensajes/mes | Costo |
|-------------|-------|
| 200,000 primeros | **Gratis** |
| 200,001 - 1,000,000 | $0.04 / 1000 |
| 1,000,001 - 5,000,000 | $0.03 / 1000 |
| 5,000,001+ | $0.02 / 1000 |

**Para tu caso (~20 tareas/día = ~600/mes)**: **Totalmente gratis**

---

## Pendiente de implementar

- [ ] Crear proyecto Firebase
- [ ] Descargar google-services.json
- [ ] Configurar build.gradle
- [ ] Agregar dependencias
- [ ] Modificar NotificationService
- [ ] Guardar token FCM en API
- [ ] Endpoint del servidor para enviar notificaciones

---

## Notas

- FCM solo funciona con Google Play Services (no funciona en Huawei sin servicios de Google)
- Para Huawei, mantener solución actual como backup
- El token FCM puede cambiar, el servidor debe actualizarlo periódicamente