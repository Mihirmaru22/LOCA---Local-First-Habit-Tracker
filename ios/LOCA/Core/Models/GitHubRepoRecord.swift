import SwiftUI
import SwiftData
import Foundation

// MARK: - AIDomain

/// Primary AI engineering & computer science domain classifications.
public enum AIDomain: String, Codable, CaseIterable, Identifiable, Sendable {
    case autonomousAgents = "Autonomous Agents"
    case llmReasoning     = "LLMs & Reasoning"
    case visionMultimodal  = "Vision & Multimodal"
    case mlopsKernels     = "MLOps & Kernels"
    case localFirstClient = "Local-First Client"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .autonomousAgents: return "point.3.connected.trianglepath.dotted"
        case .llmReasoning:     return "brain.head.profile"
        case .visionMultimodal: return "eye.fill"
        case .mlopsKernels:     return "cpu.fill"
        case .localFirstClient: return "laptopcomputer.and.iphone"
        }
    }

    public var accentColor: Color {
        switch self {
        case .autonomousAgents: return Color.cyan
        case .llmReasoning:     return Color(red: 0.95, green: 0.75, blue: 0.15) // Gold / Amber
        case .visionMultimodal: return Color.purple
        case .mlopsKernels:     return Color(red: 0.95, green: 0.40, blue: 0.40) // Coral Red
        case .localFirstClient: return Color.green
        }
    }

    public var accentColorHex: String {
        switch self {
        case .autonomousAgents: return "#06B6D4" // Cyan
        case .llmReasoning:     return "#EAB308" // Amber Gold
        case .visionMultimodal: return "#A855F7" // Purple
        case .mlopsKernels:     return "#F87171" // Coral
        case .localFirstClient: return "#22C55E" // Emerald Green
        }
    }

    public var tagline: String {
        switch self {
        case .autonomousAgents: return "Multi-agent swarms, tool protocols, memory graphs & self-reflection loops"
        case .llmReasoning:     return "Fine-tuning adapters, distillation harnesses & GRPO reasoning models"
        case .visionMultimodal: return "Vision-language grounding, diffusion pipelines & sensory embeddings"
        case .mlopsKernels:     return "Custom CUDA/Triton kernels, Metal acceleration & vLLM inference"
        case .localFirstClient: return "Sovereign native Apple OS, offline SwiftData & on-device CoreML"
        }
    }
}

// MARK: - AIModelTelemetry

/// Rich performance, evaluation, and architecture metrics for an AI repository.
public struct AIModelTelemetry: Codable, Sendable {
    public var baseModelArchitecture: String
    public var parameterSize: String
    public var quantizationFormat: String
    public var contextWindowLength: Int
    public var evalAccuracyScore: Double
    public var tokensPerSecond: Double
    public var latencyMs: Double
    public var benchmarkName: String
    public var trainingLossSummary: String

    public init(
        baseModelArchitecture: String = "Llama-3.3-70B",
        parameterSize: String = "70B",
        quantizationFormat: String = "MLX 4-bit",
        contextWindowLength: Int = 131072,
        evalAccuracyScore: Double = 94.2,
        tokensPerSecond: Double = 68.5,
        latencyMs: Double = 120.0,
        benchmarkName: String = "MATH-500: 88.4%",
        trainingLossSummary: String = "Final Loss: 0.142"
    ) {
        self.baseModelArchitecture = baseModelArchitecture
        self.parameterSize = parameterSize
        self.quantizationFormat = quantizationFormat
        self.contextWindowLength = contextWindowLength
        self.evalAccuracyScore = evalAccuracyScore
        self.tokensPerSecond = tokensPerSecond
        self.latencyMs = latencyMs
        self.benchmarkName = benchmarkName
        self.trainingLossSummary = trainingLossSummary
    }

    public var formattedContext: String {
        if contextWindowLength >= 1000 {
            return "\(contextWindowLength / 1000)k tokens"
        } else {
            return "\(contextWindowLength) tokens"
        }
    }

    public var formattedThroughput: String {
        String(format: "%.1f tok/s", tokensPerSecond)
    }

    public var formattedLatency: String {
        String(format: "%.0f ms TTFT", latencyMs)
    }
}

// MARK: - GitHubRepoRecord

/// A code repository, research codebase, or AI system tracked in Pluto's GitHub & AI Engineering Cosmos.
@Model
final class GitHubRepoRecord {

    // Identity & Core Metadata
    var id:                  UUID   = UUID()
    var name:                String = ""
    var owner:               String = ""
    var repoDescription:     String = ""
    var primaryLanguage:     String = "Python"
    var languagesJSON:       String = "{}"
    var starCount:           Int    = 0
    var forkCount:           Int    = 0
    var openIssuesCount:     Int    = 0
    var commitCount:         Int    = 0
    var lastPushedAt:        Date   = Date()
    var defaultBranch:       String = "main"
    var htmlURL:             String = ""
    var domainRaw:           String = AIDomain.autonomousAgents.rawValue
    var telemetryJSON:       String? = nil
    var techStackTagsJSON:   String = "[]"
    var isPinned:            Bool   = false
    var isArchived:          Bool   = false
    var createdAt:           Date   = Date()

    // MARK: - Initializer

    init(
        id: UUID = UUID(),
        name: String,
        owner: String = "Mihirmaru22",
        repoDescription: String = "",
        primaryLanguage: String = "Python",
        starCount: Int = 0,
        forkCount: Int = 0,
        openIssuesCount: Int = 0,
        commitCount: Int = 1,
        lastPushedAt: Date = Date(),
        defaultBranch: String = "main",
        htmlURL: String = "",
        domain: AIDomain = .autonomousAgents,
        telemetry: AIModelTelemetry? = nil,
        techStackTags: [String] = [],
        isPinned: Bool = false
    ) {
        self.id = id
        self.name = name
        self.owner = owner
        self.repoDescription = repoDescription
        self.primaryLanguage = primaryLanguage
        self.starCount = starCount
        self.forkCount = forkCount
        self.openIssuesCount = openIssuesCount
        self.commitCount = commitCount
        self.lastPushedAt = lastPushedAt
        self.defaultBranch = defaultBranch
        self.htmlURL = htmlURL.isEmpty ? "https://github.com/\(owner)/\(name)" : htmlURL
        self.domainRaw = domain.rawValue
        self.isPinned = isPinned
        self.createdAt = Date()

        if let tagsData = try? JSONEncoder().encode(techStackTags),
           let tagsStr = String(data: tagsData, encoding: .utf8) {
            self.techStackTagsJSON = tagsStr
        }

        if let tel = telemetry,
           let telData = try? JSONEncoder().encode(tel),
           let telStr = String(data: telData, encoding: .utf8) {
            self.telemetryJSON = telStr
        }
    }

    // MARK: - Computed Properties

    var domain: AIDomain {
        get { AIDomain(rawValue: domainRaw) ?? .autonomousAgents }
        set { domainRaw = newValue.rawValue }
    }

    var telemetry: AIModelTelemetry? {
        get {
            guard let json = telemetryJSON, let data = json.data(using: .utf8) else { return nil }
            return try? JSONDecoder().decode(AIModelTelemetry.self, from: data)
        }
        set {
            if let val = newValue,
               let data = try? JSONEncoder().encode(val),
               let str = String(data: data, encoding: .utf8) {
                telemetryJSON = str
            } else {
                telemetryJSON = nil
            }
        }
    }

    var techStackTags: [String] {
        get {
            guard let data = techStackTagsJSON.data(using: .utf8) else { return [] }
            return (try? JSONDecoder().decode([String].self, from: data)) ?? []
        }
        set {
            if let data = try? JSONEncoder().encode(newValue),
               let str = String(data: data, encoding: .utf8) {
                techStackTagsJSON = str
            }
        }
    }

    var formattedStars: String {
        if starCount >= 1000 {
            return String(format: "%.1fk", Double(starCount) / 1000.0)
        } else {
            return "\(starCount)"
        }
    }

    var formattedCommits: String {
        "\(commitCount.formatted()) commits"
    }

    var formattedPushedTime: String {
        lastPushedAt.formatted(date: .abbreviated, time: .shortened)
    }
}
