// Services/Audio/ElevenLabsTTSClient.swift
import Foundation
import AVFoundation

// Ajustes de la voz en ElevenLabs
struct ElevenVoiceSettings: Codable {
    var stability: Double = 0.35
    var similarity_boost: Double = 0.90
    var style: Double = 0.55
    var use_speaker_boost: Bool = true
}

final class ElevenLabsTTSClient: NSObject {
    // Config
    private let apiKey: String
    private(set) var voiceId: String
    private(set) var modelId: String
    private(set) var settings: ElevenVoiceSettings
    private(set) var playbackRate: Float   // 1.0 normal; 1.15–1.25 suena más natural
    private(set) var boostGainDb: Float    // ganancia adicional (dB), p.ej. 6–18

    // Players
    private var audioPlayer: AVAudioPlayer?
    private var avPlayer: AVPlayer?

    // AudioEngine para BOOST
    private let engine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private let varispeed = AVAudioUnitVarispeed()
    private let eq = AVAudioUnitEQ(numberOfBands: 0) // usaremos globalGain
    private var usingEngine = false

    // MARK: - Init
    init(apiKey: String,
         voiceId: String = "21m00Tcm4TlvDq8ikWAM", // ⚠️ cámbiala por tu voz ES
         modelId: String = "eleven_multilingual_v2",
         settings: ElevenVoiceSettings? = nil,
         playbackRate: Float = 1.20,
         boostGainDb: Float = 12.0) {
        self.apiKey = apiKey
        self.voiceId = voiceId
        self.modelId = modelId
        self.settings = settings ?? ElevenVoiceSettings()
        self.playbackRate = playbackRate
        self.boostGainDb = boostGainDb
    }

    // Cambios en caliente
    func updateVoice(voiceId: String? = nil,
                     modelId: String? = nil,
                     settings: ElevenVoiceSettings? = nil,
                     playbackRate: Float? = nil,
                     boostGainDb: Float? = nil) {
        if let v = voiceId { self.voiceId = v }
        if let m = modelId { self.modelId = m }
        if let s = settings { self.settings = s }
        if let r = playbackRate { self.playbackRate = max(0.5, min(2.0, r)) }
        if let g = boostGainDb { self.boostGainDb = min(max(g, 0), 24) } // 0..24 dB
    }

    // MARK: - Speak (con BOOST)
    func speak(text: String) async throws {
        stop()

        // 1) Descarga audio
        let data = try await fetchAudio(text: text)

        // 2) Guarda a archivo temporal
        let tmpURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("tts-\(UUID().uuidString).mp3")
        try data.write(to: tmpURL, options: .atomic)

        // 3) Intenta con AudioEngine (boost + velocidad)
        do {
            try playWithEngine(fileURL: tmpURL)
            return
        } catch {
            // Si el engine fallara, intenta con AVAudioPlayer (sin boost, pero fuerte)
            do {
                try playWithAVAudioPlayer(fileURL: tmpURL)
                return
            } catch {
                // Último recurso, AVPlayer
                try playWithAVPlayer(fileURL: tmpURL)
            }
        }
    }

    /// Detiene cualquier reproducción
    func stop() {
        if usingEngine {
            playerNode.stop()
            engine.stop()
            usingEngine = false
        }
        audioPlayer?.stop()
        audioPlayer = nil
        avPlayer?.pause()
        avPlayer = nil
    }

    // MARK: - Private playback paths

    /// Ruta preferida: AVAudioEngine con EQ (globalGain) y Varispeed (rate)
    private func playWithEngine(fileURL: URL) throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .default, options: [.defaultToSpeaker, .allowBluetoothA2DP])
        try session.setActive(true)

        // Reset del grafo
        engine.stop()
        engine.reset()
        engine.detach(playerNode)
        engine.attach(playerNode)
        engine.detach(varispeed)
        engine.attach(varispeed)
        engine.detach(eq)
        engine.attach(eq)

        // Ganancia
        eq.globalGain = boostGainDb // 🔊 BOOST (ej. 12 dB)

        // Velocidad
        varispeed.rate = playbackRate // 1.2 = 20% más rápido

        // Conexiones: player -> varispeed -> eq -> mainMixer
        engine.connect(playerNode, to: varispeed, format: nil)
        engine.connect(varispeed, to: eq, format: nil)
        engine.connect(eq, to: engine.mainMixerNode, format: nil)

        let audioFile = try AVAudioFile(forReading: fileURL)
        playerNode.stop()
        playerNode.scheduleFile(audioFile, at: nil, completionHandler: nil)

        if !engine.isRunning {
            try engine.start()
        }
        playerNode.volume = 1.0
        playerNode.play()
        usingEngine = true
    }

    /// Fallback 1: AVAudioPlayer (volumen a tope; sin boost)
    private func playWithAVAudioPlayer(fileURL: URL) throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .default, options: [.defaultToSpeaker, .allowBluetoothA2DP])
        try session.setActive(true)

        let p = try AVAudioPlayer(contentsOf: fileURL)
        p.enableRate = true
        p.rate = playbackRate
        p.volume = 1.0 // 🔊
        p.prepareToPlay()
        DispatchQueue.main.async { _ = p.play() }
        self.audioPlayer = p
    }

    /// Fallback 2: AVPlayer (tolerante con ruteos)
    private func playWithAVPlayer(fileURL: URL) throws {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default, options: [.defaultToSpeaker])
        try? session.setActive(true)

        let item = AVPlayerItem(url: fileURL)
        let player = AVPlayer(playerItem: item)
        player.volume = 1.0
        player.isMuted = false
        self.avPlayer = player
        DispatchQueue.main.async { player.play() }
    }

    // MARK: - Networking
    private func fetchAudio(text: String) async throws -> Data {
        var req = URLRequest(url: URL(string: "https://api.elevenlabs.io/v1/text-to-speech/\(voiceId)")!)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("audio/mpeg", forHTTPHeaderField: "Accept")
        req.setValue(apiKey, forHTTPHeaderField: "xi-api-key")

        struct Body: Codable {
            let text: String
            let model_id: String
            let voice_settings: ElevenVoiceSettings
        }
        let payload = Body(text: text, model_id: modelId, voice_settings: settings)
        req.httpBody = try JSONEncoder().encode(payload)

        let (data, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse else {
            throw NSError(domain: "ElevenTTS", code: -1, userInfo: [NSLocalizedDescriptionKey: "Respuesta HTTP inválida"])
        }
        guard http.statusCode == 200 else {
            let msg = String(data: data, encoding: .utf8) ?? "sin cuerpo"
            throw NSError(domain: "ElevenTTS", code: http.statusCode,
                          userInfo: [NSLocalizedDescriptionKey: "HTTP \(http.statusCode): \(msg)"])
        }
        guard data.count > 500 else {
            throw NSError(domain: "ElevenTTS", code: -2,
                          userInfo: [NSLocalizedDescriptionKey: "Audio vacío o muy corto (\(data.count) bytes)"])
        }
        return data
    }
}
