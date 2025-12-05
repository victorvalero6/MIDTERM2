# 🏦 SwiftFin - AI-Powered Financial Assistant

**SwiftFin** es una aplicación iOS inteligente que combina análisis financiero personalizado con inteligencia artificial avanzada (Gemini API) para ayudar a los usuarios a gestionar sus finanzas de manera eficiente y accesible.

## ✨ Características Principales

- 🤖 **Chat AI con Gemini**: Asistente financiero impulsado por Google Gemini con selección inteligente de modelos
- 📊 **Análisis Financiero**: Visualización y análisis de gastos, ingresos y transacciones
- 🎙️ **Modo Voz**: Interacción por voz con reconocimiento de voz (Speech Recognition) y síntesis de voz (ElevenLabs TTS)
- ⚡ **Algoritmo Greedy**: Selección dinámica entre modelos Gemini 2.0-flash (rápido) y 2.5-flash (potente) para optimizar costos y latencia
- 💾 **Dynamic Programming**: Caché de respuestas (Memoization) y gestión inteligente del contexto conversacional
- 🏦 **Integración con Capital One Nessie API**: Simulación de datos financieros reales

## 📋 Requisitos Previos

### Software Requerido

- **macOS**: 13.0 (Ventura) o superior
- **Xcode**: 15.0 o superior
- **iOS Deployment Target**: iOS 17.0+
- **Swift**: 5.9+

### APIs y Claves

1. **Google Gemini API Key** ([Obtener aquí](https://makersuite.google.com/app/apikey))
2. **Capital One Nessie API Key** ([Obtener aquí](http://api.nessieisreal.com/))
3. **ElevenLabs API Key** (Opcional, solo para síntesis de voz) ([Obtener aquí](https://elevenlabs.io/))

## 🚀 Instalación

### 1. Clonar el Repositorio

```bash
git clone https://github.com/tu-usuario/HackathonMTY.git
cd HackathonMTY
```

### 2. Abrir el Proyecto en Xcode

```bash
open CapitalOneDemo.xcodeproj
```

O simplemente haz doble clic en el archivo `CapitalOneDemo.xcodeproj` desde Finder.

### 3. Instalar Dependencias

El proyecto usa **Swift Package Manager** (SPM). Las dependencias se resolverán automáticamente al abrir el proyecto:

- `GoogleGenerativeAI` - Para integración con Gemini API

Si las dependencias no se descargan automáticamente:

1. En Xcode, ve a **File → Packages → Resolve Package Versions**
2. Espera a que se descarguen todas las dependencias

## 🔑 Configuración de API Keys

### Paso 1: Configurar `GenerativeAIInfo.plist`

1. Navega a `CapitalOneDemo/Config/GenerativeAIInfo.plist`
2. Abre el archivo y añade tus claves:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>GEMINI_API_KEY</key>
    <string>TU_GEMINI_API_KEY_AQUI</string>
    <key>ELEVEN_API_KEY</key>
    <string>TU_ELEVENLABS_API_KEY_AQUI</string>
</dict>
</plist>
```

### Paso 2: Configurar Capital One Nessie API

1. Abre `CapitalOneDemo/Config/LocalSecrets.swift`
2. Reemplaza `YOUR_DEFAULT_API_KEY_HERE` con tu API Key de Nessie:

```swift
enum LocalSecrets {
    static var nessieApiKey: String {
        if let key = Bundle.main.object(forInfoDictionaryKey: "API_KEY") as? String, !key.isEmpty {
            return key
        }
        return "TU_NESSIE_API_KEY_AQUI" // ← Reemplaza aquí
    }
}
```

**Alternativa (Recomendada)**: Usa `localSecrets.xcconfig`

1. Crea o edita `CapitalOneDemo/Config/localSecrets.xcconfig`:

```
API_KEY = tu_nessie_api_key_aqui
```

2. Asegúrate de que `localSecrets.xcconfig` esté en el `.gitignore` para no exponer tus claves.

### ⚠️ Importante: Seguridad de las Claves

**NUNCA** subas tus API keys a GitHub. El proyecto incluye archivos de ejemplo, pero debes crear tus propias versiones locales:

```bash
# Añadir a .gitignore si no está
echo "CapitalOneDemo/Config/localSecrets.xcconfig" >> .gitignore
echo "CapitalOneDemo/Config/GenerativeAIInfo.plist" >> .gitignore
```

## 🔨 Compilación y Ejecución

### Opción 1: Usando Xcode GUI

1. Abre el proyecto en Xcode
2. Selecciona un simulador o dispositivo iOS (iPhone 15 Pro recomendado)
3. Presiona **⌘ + R** o haz clic en el botón ▶️ "Run"

### Opción 2: Usando Command Line

```bash
# Compilar el proyecto
xcodebuild -project CapitalOneDemo.xcodeproj -scheme CapitalOneDemo -configuration Debug build

# Ejecutar en simulador
xcrun simctl boot "iPhone 15 Pro"
xcodebuild -project CapitalOneDemo.xcodeproj -scheme CapitalOneDemo -destination 'platform=iOS Simulator,name=iPhone 15 Pro' run
```

## 📁 Estructura del Proyecto

```
CapitalOneDemo/
├── Assets.xcassets/         # Recursos visuales (iconos, imágenes)
├── Components/              # Componentes reutilizables de UI
├── Config/                  # Configuración y API keys
│   ├── GenerativeAIInfo.plist
│   ├── LocalSecrets.swift
│   └── localSecrets.xcconfig
├── Models/                  # Modelos de datos
│   ├── Models.swift
│   ├── GetModels.swift
│   └── AntExpense.swift
├── Services/                # Lógica de negocio y APIs
│   ├── NessieService.swift
│   ├── Audio/
│   │   ├── ElevenLabsTTSClient.swift
│   │   └── SpeechRecognizer.swift
│   └── AuthStore.swift
├── ViewModels/              # ViewModels (MVVM)
│   ├── ChatViewModel.swift  # ← Algoritmos Greedy + DP aquí
│   ├── OverviewViewModel.swift
│   └── ExpensesViewModel.swift
├── Views/                   # Vistas SwiftUI
│   ├── ChatView.swift
│   ├── OverviewView.swift
│   └── MainAppView.swift
└── Info.plist
```

## 🧠 Arquitectura: Algoritmos Avanzados

### Algoritmo Greedy (Selección de Modelo)

El sistema utiliza un **algoritmo greedy** para seleccionar dinámicamente el modelo de IA óptimo:

- **Gemini 2.0-flash** 🟢: Para consultas simples (< 50 caracteres, sin keywords complejas)
  - Ventaja: Baja latencia, menor costo
- **Gemini 2.5-flash** 🔴: Para análisis financieros complejos
  - Ventaja: Mayor capacidad de razonamiento

Implementación: `ChatViewModel.swift → selectOptimalModel()`

### Dynamic Programming (Gestión de Contexto)

- **Memoization**: Caché de respuestas repetidas (O(1) lookup)
- **Circular Buffer**: Ventana deslizante que mantiene solo los últimos N mensajes relevantes, reduciendo tokens enviados al modelo

Implementación: `ChatViewModel.swift → responseCache` y `historyBuffer`

## 🛠️ Solución de Problemas

### Error: "Could not find API Key"

**Causa**: `GenerativeAIInfo.plist` no está configurado correctamente.

**Solución**:

1. Verifica que el archivo existe en `CapitalOneDemo/Config/`
2. Asegúrate de que contiene la clave `GEMINI_API_KEY`
3. Limpia el build: **⌘ + Shift + K** y vuelve a compilar

### Error: "GoogleGenerativeAI.GenerateContentError error 1"

**Causa**: El modelo de Gemini especificado no está disponible para tu API Key.

**Solución**:

1. Verifica que tu API Key de Gemini es válida
2. Revisa que tienes acceso a los modelos `gemini-2.0-flash` y `gemini-2.5-flash`
3. Prueba con `gemini-1.5-flash` si los modelos 2.x no están disponibles

### Error: "ElevenLabs TTS 401 Unusual Activity"

**Causa**: Tu cuenta de ElevenLabs (Free Tier) fue bloqueada por uso sospechoso o límite excedido.

**Solución**:

- La app funcionará perfectamente en **modo texto** (el error solo afecta la síntesis de voz)
- Puedes desactivar el modo voz desde el botón de la toolbar
- Para resolver: actualiza tu plan de ElevenLabs o usa una nueva API Key

### Dependencias no se resuelven

```bash
# En la carpeta del proyecto
rm -rf ~/Library/Developer/Xcode/DerivedData
xcodebuild -resolvePackageDependencies
```

### Simulador no arranca

```bash
# Reiniciar simuladores
xcrun simctl shutdown all
xcrun simctl erase all
```

## 🎯 Uso de la Aplicación

### Modo Chat (Texto)

1. Navega a la pestaña **"FinBot"**
2. Escribe tu pregunta financiera en el campo de texto
3. Observa el **tag de color** en cada respuesta:
   - 🟢 **Verde**: Respuesta generada con Gemini 2.0-flash (rápido)
   - 🔴 **Rojo**: Respuesta generada con Gemini 2.5-flash (análisis complejo)

### Modo Voz

1. Toca el ícono de **micrófono** en la toolbar
2. Habla tu pregunta
3. El bot responderá con voz (si ElevenLabs está configurado)

### Ejemplos de Prompts

**Para activar Gemini 2.0-flash** 🟢:

```
Hola
¿Qué es el IVA?
Hi there
```

**Para activar Gemini 2.5-flash** 🔴:

```
Analiza mis gastos del mes pasado y dame recomendaciones
Dame un resumen de mis transacciones
Can you predict my spending trends?
```

## 📊 Características Técnicas

- **Lenguaje**: Swift 5.9
- **UI Framework**: SwiftUI
- **Arquitectura**: MVVM (Model-View-ViewModel)
- **Networking**: URLSession + async/await
- **AI**: Google Gemini API (2.0-flash y 2.5-flash)
- **Speech**: Apple Speech Framework + ElevenLabs TTS
- **Persistencia**: Keychain (para tokens de autenticación)

## 👥 Colaboradores

- **Miguel Ángel Gavito González**
- **Juan Luis Alvarez Cisneros**
- **Cruz Yael Pérez González**
- **Victor Valero**

## 📄 Licencia

Este proyecto fue desarrollado para el **HackathonMTY** y es de uso educativo.

## 🙋 Soporte

Si encuentras problemas durante la instalación o ejecución:

1. Revisa la sección **Solución de Problemas** arriba
2. Verifica que todas las API keys están correctamente configuradas
3. Consulta la documentación oficial:
   - [Gemini API Docs](https://ai.google.dev/docs)
   - [Capital One Nessie API](http://api.nessieisreal.com/)

---

**¡Disfruta usando SwiftFin! 🚀💰**
