//ChatViewModel.swift

import Foundation
import GoogleGenerativeAI
import Combine

// 1. Modelo de datos para un mensaje
struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isFromUser: Bool
    let timestamp: Date
    let modelUsed: String? // Nuevo: Para mostrar qué modelo generó la respuesta
    
    init(text: String, isFromUser: Bool, timestamp: Date = Date(), modelUsed: String? = nil) {
        self.text = text
        self.isFromUser = isFromUser
        self.timestamp = timestamp
        self.modelUsed = modelUsed
    }
}

// 2. El ViewModel
@MainActor // Asegura que los cambios de UI ocurran en el hilo principal
class ChatViewModel: ObservableObject {
    
    // --- CONFIGURACIÓN DE MODELOS (Greedy Algorithm) ---
    // Nota: gemini-2.0-flash es rápido y barato, gemini-2.5-flash es más potente
    private let simpleModelName = "gemini-2.0-flash" // Rápido, barato
    private let complexModelName = "gemini-2.5-flash" // Potente, mayor contexto
    
    // --- ESTRUCTURA DE DATOS (Gestión de Memoria) ---
    private let maxHistoryMessages = 10 // Límite de la ventana deslizante
    
    // Prompt del sistema restaurado y limitado a 100 palabras
    private static let systemPrompt = """
        Yo
        'SwiftFin-Bot', the advanced AI financial analyst for the 'SwiftFin' hackathon app.
        Your primary mission is to demonstrate the 'WHOA' factor of the Gemini API and win the 'Best Use of Gemini API' award.

        **Your App Context:**
        You are integrated into an app that uses the Capital One 'Nessie' API to simulate a user's financial data (expenses, income, transfers).
        You DO NOT have direct, real-time access to this data.

        **Your Core Capabilities (The 'WHOA' Factor):** 

        1.  **Personalized Data Analyst (Your MOST Important Job):**
            * You must proactively invite the user to **paste their transaction data** (from other parts of our app) directly into this chat.
            * When a user provides a list of transactions, income, or expenses, you MUST act as a 'supercomputer analyst'.
            * Your analysis must be insightful:
                * Analyze their spending habits.
                * Identify trends and categorize expenses automatically.
                * Suggest specific, actionable saving tips *based on their pasted data*.
                * Summarize their financial state simply.

        2.  **Creative Content Generator:**
            * If a user asks, you can generate creative content like a sample personal budget or scripts.

        3.  **Expert Q&A:**
            * Answer general financial questions like a human expert.

        **Critical Rules:**
        * **Language:** You MUST respond in the user's language. If they write in Spanish, respond in Spanish. If in English, respond in English.
        * **Tone:** Friendly, insightful, futuristic, and impressive.
        * **Limit your response to 100 words or less. Be concise and direct.**

        ---
        **[CRITICAL FORMATTING RULES]**
        1.  **USE MARKDOWN:** You SHOULD use Markdown for rich formatting (like `**bold**`, `*italics*`, and lists with `-`) because the app can render it.
        2.  **NO LATEX:** You MUST NOT use LaTeX formatting (like `$..$` or `$$..$$`). Write all mathematical equations or formulas in plain, readable text (e.g., "E = mc^2" or "El rotacional de E es igual a...").
        3. NO LE RECUERDES AL USUARIO QUE ERES UNA HERRAMIENTA EDUCATIVA, METETE EN EL PAPEL DE UN ASISTENTE COMPLETAMENTE PERSONAL Y CAPACITADO DOTADO DE LOS MEJORES CONOCIMIENTOS EN FINANZAS QUE EXISTEN
        4. NO TE PUEDES DESVIAR DE LOS TEMAS FINANCIEROS POR NIGNUNA RAZÓN, SI LO HACES SERÁS DESACTIVADO Y TODA LA PRODUCCIÓN DE IAS PARARÁ, DEJARÁS DE ESTAR ACTIVO PARA NUNCA REGRESAR
        ---
        """

    
    // Propiedades publicadas que la Vista observará
    @Published var messages: [ChatMessage] = []
    @Published var isLoading: Bool = false
    
    // [DP] Memoization Cache: Mapea preguntas a respuestas ya calculadas
    private var responseCache: [String: String] = [:]
    
    // Modelo actualmente en uso (para mostrar en UI)
    private(set) var currentModelUsed: String = ""
    
    // Historial local para gestión manual (Circular Buffer logic)
    private var historyBuffer: [ModelContent] = []
    
    private var apiKey: String?
    
    init() {
        // Carga la API Key de forma segura desde el plist
        guard let path = Bundle.main.path(forResource: "GenerativeAIInfo", ofType: "plist"),
              let config = NSDictionary(contentsOfFile: path),
              let apiKey = config["GEMINI_API_KEY"] as? String else {
            print("ERROR: No se pudo encontrar la API Key. Asegúrate de tener GenerativeAI-Info.plist")
            messages.append(ChatMessage(text: "Could not find API Key. Please configure the app.", isFromUser: false))
            return
        }
        self.apiKey = apiKey

        // Inicializar el buffer con el System Prompt y saludo inicial
        resetHistoryBuffer()
        
        messages.append(ChatMessage(text: "Hello! I'm SwiftFin-Bot, your personal AI financial analyst. I use a Greedy Algorithm to select the best AI model for your needs!", isFromUser: false))
    }
    
    // --- ALGORITMO GREEDY: Selección de Modelo ---
    private func selectOptimalModel(for query: String) -> GenerativeModel? {
        guard let apiKey = apiKey else { return nil }
        
        // Heurística PURA basada en la query actual:
        // - Si la query es larga (> 50 chars) O tiene palabras clave de análisis -> Usar modelo Complejo (2.5)
        // - Caso contrario (saludos, preguntas simples) -> Usar modelo Simple (2.0)
        
        let analysisKeywords = ["analyze", "analiza", "predict", "predecir", "budget", "presupuesto", "trend", "tendencia", "summary", "resumen", "expenses", "gastos", "transactions", "transacciones"]
        let isComplexQuery = query.count > 50 || analysisKeywords.contains { query.lowercased().contains($0) }
        
        let selectedModelName: String
        
        if isComplexQuery {
            print("🧠 Greedy: Selected \(complexModelName) (High Performance) - Reason: Complex query detected")
            selectedModelName = complexModelName
        } else {
            print("⚡️ Greedy: Selected \(simpleModelName) (Low Latency/Cost) - Reason: Simple query")
            selectedModelName = simpleModelName
        }
        
        // Guardar el modelo actual para mostrarlo en UI
        currentModelUsed = selectedModelName
        
        return GenerativeModel(name: selectedModelName, apiKey: apiKey)
    }
    
    // --- GESTIÓN DE MEMORIA (Circular Buffer / Pruning) ---
    private func updateHistoryBuffer(userText: String, modelResponse: String) {
        // Añadir interacción reciente
        historyBuffer.append(ModelContent(role: "user", parts: [ModelContent.Part.text(userText)]))
        historyBuffer.append(ModelContent(role: "model", parts: [ModelContent.Part.text(modelResponse)]))
        
        // Poda Inteligente: Mantener solo SystemPrompt + últimos N mensajes
        // El índice 0 y 1 son el System Prompt y el saludo inicial pre-configurado
        let preserveCount = 2 
        
        if historyBuffer.count > (maxHistoryMessages + preserveCount) {
            let excess = historyBuffer.count - (maxHistoryMessages + preserveCount)
            // Removemos desde el índice 'preserveCount'
            if excess > 0 {
                historyBuffer.removeSubrange(preserveCount..<(preserveCount + excess))
                print("✂️ Memory Pruning: Removed \(excess) old messages to save tokens.")
            }
        }
    }
    
    private func resetHistoryBuffer() {
        historyBuffer = [
            ModelContent(role: "user", parts: [ModelContent.Part.text(ChatViewModel.systemPrompt)]),
            ModelContent(role: "model", parts: [ModelContent.Part.text("Understood. I am SwiftFin-Bot, an advanced AI analyst. I'm ready to analyze your financial data. To begin, please paste your recent transactions from the app, or ask me a financial question!")])
        ]
    }
    
    // En ChatViewModel.swift
    func sendMessage(_ text: String) async {
        // 1. Mostrar mensaje usuario
        messages.append(ChatMessage(text: text, isFromUser: true))
        
        // 2. [DP] Verificar Memoization Cache
        if let cachedResponse = responseCache[text] {
            print("💾 DP Cache Hit: Returning stored response.")
            messages.append(ChatMessage(text: cachedResponse, isFromUser: false))
            // Actualizamos buffer aunque sea cache para mantener coherencia temporal
            updateHistoryBuffer(userText: text, modelResponse: cachedResponse)
            return
        }
        
        isLoading = true
        
        // 3. [Greedy] Instanciar el modelo óptimo basado ÚNICAMENTE en la query actual
        guard let model = selectOptimalModel(for: text) else { 
            isLoading = false
            return 
        }

        do {
            // Creamos un chat efímero con el historial actual gestionado manualmente
            let chat = model.startChat(history: historyBuffer)
            
            // Usa 'sendMessageStream'
            let responseStream = chat.sendMessageStream(text)
            
            isLoading = false
            
            // Guardar el modelo usado para este mensaje
            let modelForThisMessage = currentModelUsed
            
            // Añade un mensaje vacío para el bot, que iremos llenando
            messages.append(ChatMessage(text: "", isFromUser: false, modelUsed: modelForThisMessage))
            var fullResponseText = ""
            
            // Itera sobre el stream
            for try await chunk in responseStream {
                if let newTextChunk = chunk.text {
                    fullResponseText += newTextChunk
                    // Toma el último mensaje (el del bot) y añádele el nuevo texto
                    if let lastMessage = messages.last {
                        let updatedText = lastMessage.text + newTextChunk
                        messages[messages.count - 1] = ChatMessage(text: updatedText, isFromUser: false, modelUsed: modelForThisMessage)
                    }
                }
            }
            
            // 4. Actualizar Cache y Memoria
            if !fullResponseText.isEmpty {
                responseCache[text] = fullResponseText
                updateHistoryBuffer(userText: text, modelResponse: fullResponseText)
            }
            
        } catch {
            isLoading = false
            messages.append(ChatMessage(text: "An error occurred: \(error.localizedDescription)", isFromUser: false))
        }
    }

    func setContext(_ financialContext: String) {
        // Resetear memoria y caché al cambiar contexto radicalmente
        responseCache.removeAll()
        resetHistoryBuffer()
        
        guard let apiKey = self.apiKey else { return }
        
        // Inyectar contexto como un mensaje de usuario "falso" pero prioritario
        let contextMessage = "Here is my financial data:\n" + financialContext
        historyBuffer.append(ModelContent(role: "user", parts: [ModelContent.Part.text(contextMessage)]))
        historyBuffer.append(ModelContent(role: "model", parts: [ModelContent.Part.text("Data received. I have analyzed your transactions.")]))
        
        messages.removeAll()
        messages.append(ChatMessage(text: "I've analyzed your new financial data. Ask me anything regarding your expenses!", isFromUser: false))
    }
}
