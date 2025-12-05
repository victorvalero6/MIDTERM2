# 🏦 SwiftFin - AI Financial Assistant

SwiftFin es una app iOS que usa inteligencia artificial (Google Gemini) para analizar tus finanzas y darte consejos personalizados.

## ✨ Características

- 🤖 **Chat con IA**: Habla con un asistente financiero inteligente
- 📊 **Análisis de gastos**: Visualiza y entiende tus transacciones
- 🎙️ **Modo voz**: Pregunta usando tu voz
- ⚡ **Optimización inteligente**: Usa diferentes modelos de IA según la pregunta
- 🏦 **Simulación real**: Integrado con Capital One Nessie API

## 👥 Equipo

| Miembro                 | Responsabilidad          |
| ----------------------- | ------------------------ |
| **Marco** | 🧮 Algoritmo Greedy      |
| **Juan Luis**   | 💾 Dynamic Programming   |
| **Victor Valero**       | 🎨 UI/UX y Visualización |


## 🚀 Instalación Rápida

### 1. Requisitos

- macOS 13.0+
- Xcode 15.0+
- iOS 17.0+

### 2. Clonar y Abrir

```bash
git clone https://github.com/tu-usuario/HackathonMTY.git
cd HackathonMTY
open CapitalOneDemo.xcodeproj
```

### 3. Configurar API Keys

**Archivo: `CapitalOneDemo/Config/GenerativeAIInfo.plist`**

```xml
<dict>
    <key>GEMINI_API_KEY</key>
    <string>tu_api_key_aqui</string>
</dict>
```

**Archivo: `CapitalOneDemo/Config/LocalSecrets.swift`**

```swift
return "tu_nessie_api_key_aqui"
```

### 4. Compilar

Presiona **⌘ + R** en Xcode

## 🔑 Obtener API Keys

- **Gemini API**: https://makersuite.google.com/app/apikey
- **Nessie API**: http://api.nessieisreal.com/

## 🧠 Tecnología

### Algoritmo Greedy (Miguel Ángel)

Selecciona automáticamente el modelo de IA más eficiente:

- 🟢 **Gemini 2.0-flash**: Preguntas simples y rápidas
- 🔴 **Gemini 2.5-flash**: Análisis financieros complejos

### Dynamic Programming (Juan Luis)

Optimiza memoria y reduce costos:

- **Cache inteligente**: Guarda respuestas previas
- **Gestión de historial**: Solo mantiene lo relevante

### UI Visual (Victor)

- Tags de colores que muestran qué modelo se está usando
- Interfaz intuitiva con animaciones fluidas

### Integración APIs (Cruz Yael)

- Conexión con Gemini para respuestas inteligentes
- Reconocimiento y síntesis de voz
- Manejo de errores robusto

## 📖 Cómo Usar

1. Abre la app y ve a la pestaña **"FinBot"**
2. Escribe o habla tu pregunta financiera
3. Observa el tag de color en la respuesta:
   - 🟢 = Modelo rápido
   - 🔴 = Modelo potente

### Ejemplos

**Preguntas simples** (activan 🟢 2.0-flash):

```
Hola
¿Qué es el IVA?
```

**Análisis complejos** (activan 🔴 2.5-flash):

```
Analiza mis gastos del mes
Dame consejos de ahorro
```

## 🛠️ Problemas Comunes

**Error: "Could not find API Key"**
→ Verifica que configuraste `GenerativeAIInfo.plist`

**Error: "GenerateContentError error 1"**
→ Tu API Key de Gemini no es válida o no tiene acceso al modelo

**Modo voz no funciona**
→ Es normal si no tienes ElevenLabs API Key. El chat de texto funciona perfectamente sin voz.

## 📁 Estructura del Proyecto

```
CapitalOneDemo/
├── Config/                  # API Keys
├── Models/                  # Datos
├── Services/                # APIs y lógica
├── ViewModels/              # Algoritmos (Greedy + DP)
├── Views/                   # Interfaces
└── Components/              # UI reutilizable
```

## 💡 Contribuciones Detalladas

### Marco - Greedy Algorithm

- Decide en tiempo real qué modelo usar
- Optimiza costos y velocidad
- Heurística basada en keywords y longitud

**Archivo**: `ChatViewModel.swift` (función `selectOptimalModel`)

### Juan Luis - Dynamic Programming

- Sistema de caché para respuestas repetidas
- Buffer circular que ahorra hasta 70% de tokens
- Gestión eficiente de memoria

**Archivo**: `ChatViewModel.swift` (variables `responseCache` y `historyBuffer`)

### Victor - UI/UX

- Tags visuales con colores (verde/rojo)
- Interfaz moderna y animada
- Documentación completa

**Archivos**: `MessageBubble.swift`, `ChatView.swift`

## 🎯 Stack Tecnológico

- **Lenguaje**: Swift 5.9
- **UI**: SwiftUI
- **IA**: Google Gemini API
- **Arquitectura**: MVVM

## 📄 Licencia

Proyecto educativo desarrollado para HackathonMTY.

---

**¿Preguntas?** Revisa la sección de problemas comunes o consulta la [documentación de Gemini](https://ai.google.dev/docs).
