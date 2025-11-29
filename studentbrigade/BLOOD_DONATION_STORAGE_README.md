# Blood Donation Information - SharedPreferences Storage Documentation

## Resumen General

Los datos de donación de sangre se guardan en **SharedPreferences** de forma persistente en el dispositivo. Esto incluye:
1. **Puntos de donación (coordenadas y detalles)**
2. **URL del sitio de donación**

---

## Dónde se Guardan los Datos

### Clase: `BloodDonationStorage`
**Ubicación:** `lib/services/blood_donation_storage.dart`

Este servicio maneja todo el almacenamiento y recuperación de datos en SharedPreferences.

### Claves de Almacenamiento

| Clave | Descripción | Tipo | Ejemplo |
|-------|-------------|------|---------|
| `blood_donation_points` | Lista de centros de donación en formato JSON | `StringList` | `["{"latitude":4.6015,...}","..."]` |
| `blood_donation_url` | URL del sitio de la Cruz Roja | `String` | `https://www.cruzrojacolombiana.org/banco-de-sangre/dona-sangre/` |

---

## Cómo Funcionan las Funciones

### 1. **saveBloodDonationPoints()**
```dart
static Future<void> saveBloodDonationPoints(List<MapLocation> centers) async
```

**Qué hace:**
- Recibe una lista de `MapLocation` (puntos de donación)
- Convierte cada punto a JSON usando `center.toJson()`
- Guarda todos los puntos como una lista de strings en SharedPreferences bajo la clave `blood_donation_points`

**Ejemplo de almacenamiento:**
```
blood_donation_points: [
  '{"latitude":4.6015,"longitude":-74.0665,"name":"Centro Principal","description":"Centro principal de donación","locationType":"LocationType.bloodDonation"}',
  '{"latitude":4.604,"longitude":-74.0645,"name":"Centro Norte","description":"Centro norte","locationType":"LocationType.bloodDonation"}',
  ...
]
```

### 2. **getBloodDonationPoints()**
```dart
static Future<List<MapLocation>> getBloodDonationPoints() async
```

**Qué hace:**
- Lee la lista de strings de `blood_donation_points` desde SharedPreferences
- Decodifica cada JSON de vuelta a objetos `MapLocation`
- Si no hay datos guardados, retorna los datos estáticos de `MapData.bloodDonationCenters`

### 3. **saveDonationUrl()**
```dart
static Future<void> saveDonationUrl(String url) async
```

**Qué hace:**
- Guarda la URL del sitio de donación bajo la clave `blood_donation_url`
- URL por defecto: `https://www.cruzrojacolombiana.org/banco-de-sangre/dona-sangre/`

### 4. **getDonationUrl()**
```dart
static Future<String> getDonationUrl() async
```

**Qué hace:**
- Recupera la URL desde SharedPreferences
- Si no existe, retorna la URL por defecto

### 5. **initialize()**
```dart
static Future<void> initialize() async
```

**Qué hace:**
- Verifica si existen datos en SharedPreferences
- Si no existen, guarda los datos estáticos por defecto
- Se ejecuta automáticamente cuando se abre la página de donación

---

## Estructura de Datos Almacenados

### MapLocation convertido a JSON
```json
{
  "latitude": 4.6015,
  "longitude": -74.0665,
  "name": "Centro de Donación Principal",
  "description": "Centro principal de donación de sangre",
  "locationType": "LocationType.bloodDonation"
}
```

### Coordenadas Incluidas
Las coordenadas se guardan como parte de cada `MapLocation`:
- **latitude**: Coordenada de latitud (ej: 4.6015)
- **longitude**: Coordenada de longitud (ej: -74.0665)

---

## Dónde Visualizar el Almacenamiento

### Método 1: Logs en Consola
El servicio imprime mensajes cuando guarda/carga datos:
```
✅ Puntos de donación guardados en SharedPreferences
✅ URL de donación guardada en SharedPreferences
✅ BloodDonationStorage inicializado
```

Abre la consola de Flutter para ver estos mensajes.

### Método 2: Inspeccionar SharedPreferences (Para Desarrolladores)
En tu código, puedes inspeccionar el contenido:

```dart
import 'package:shared_preferences/shared_preferences.dart';

Future<void> debugPrintSharedPrefs() async {
  final prefs = await SharedPreferences.getInstance();
  
  // Ver todos los puntos de donación
  final points = prefs.getStringList('blood_donation_points');
  print('Puntos guardados: $points');
  
  // Ver URL
  final url = prefs.getString('blood_donation_url');
  print('URL guardada: $url');
}
```

### Método 3: Android Studio / DevTools
Si usas Android Studio:
1. Abre Device File Explorer (View → Tool Windows → Device File Explorer)
2. Navega a: `/data/data/com.example.studentbrigade/shared_prefs/`
3. Abre el archivo `.xml` de preferencias compartidas

Contenido ejemplo:
```xml
<?xml version="1.0" encoding="utf-8"?>
<map>
    <string name="blood_donation_points">["...", "...", "..."]</string>
    <string name="blood_donation_url">https://www.cruzrojacolombiana.org/banco-de-sangre/dona-sangre/</string>
</map>
```

---

## Flujo de Datos en la Aplicación

```
1. Usuario abre BloodDonationPage
   ↓
2. initState() → _initializeData()
   ↓
3. BloodDonationStorage.initialize()
   ↓
4. Si no hay datos → Guarda MapData.bloodDonationCenters en SharedPreferences
   Si hay datos → Los deja como están
   ↓
5. MapVM.getBloodDonationCenters() lee desde SharedPreferences
   ↓
6. La página muestra los datos + el mapa con los puntos
```

---

## Estrategia Offline-First

- **Con Internet:** Los datos se cargan desde `MapData` y se guardan en SharedPreferences para uso offline
- **Sin Internet:** Se recuperan de SharedPreferences
- **Fallback:** Si SharedPreferences está vacío, se usan los datos estáticos

---

## Coordenadas de los Centros de Donación

Las siguientes coordenadas están guardadas:

| Centro | Latitud | Longitud |
|--------|---------|----------|
| Centro Principal | 4.6015 | -74.0665 |
| Centro Norte | 4.6040 | -74.0645 |
| Centro Sur | 4.5990 | -74.0680 |

Todas están cerca de la Universidad Nacional de Colombia (Bogotá).

---

## Resumen de Código Relevante

### En `blood_donation_page.dart`:
```dart
Future<void> _initializeData() async {
  // Inicializa BloodDonationStorage
  await BloodDonationStorage.initialize();
  
  // Carga URL
  _donationUrl = await BloodDonationStorage.getDonationUrl();
  
  // Los centros se cargan a través de MapVM
  final centers = widget.orchestrator.mapVM.getBloodDonationCenters();
}
```

### En `MapVM.dart`:
```dart
Future<void> _loadBloodDonationCenters() async {
  if (_connectivity.hasInternet) {
    // Carga de MapData y guarda en SharedPreferences
    await BloodDonationStorage.saveBloodDonationPoints(_bloodDonationCenters);
  } else {
    // Carga desde SharedPreferences
    _bloodDonationCenters = await BloodDonationStorage.getBloodDonationPoints();
  }
}
```

---

## Conclusión

✅ **Las coordenadas SÍ se guardan en SharedPreferences** en el servicio `BloodDonationStorage`  
✅ **Clave de almacenamiento:** `blood_donation_points`  
✅ **Formato:** Lista de strings JSON con objetos `MapLocation`  
✅ **URL también guardada:** `blood_donation_url`  
✅ **Estrategia:** Offline-first con fallback a datos estáticos
