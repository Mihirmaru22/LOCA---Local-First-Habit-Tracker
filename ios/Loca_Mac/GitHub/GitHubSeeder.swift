import SwiftUI
import SwiftData
import Foundation

// MARK: - GitHubSeeder

/// Pre-seeds the SwiftData store with high-fidelity, production-grade AI engineering repositories.
enum GitHubSeeder {

    @MainActor
    static func seedIfNeeded(context: ModelContext) {
        let descriptor = FetchDescriptor<GitHubRepoRecord>()
        let existingCount = (try? context.fetchCount(descriptor)) ?? 0

        guard existingCount == 0 else { return }

        let sampleRepos = makeSeedRepos()
        for repo in sampleRepos {
            context.insert(repo)
        }

        try? context.save()
    }

    static func makeSeedRepos() -> [GitHubRepoRecord] {
        let calendar = Calendar.current
        let now = Date()

        // 1. Pluto Local-First OS
        let pluto = GitHubRepoRecord(
            name: "Pluto-Local-First-OS",
            owner: "Mihirmaru22",
            repoDescription: "Sovereign local-first executive OS for habits, life strategy, mountain expeditions, and AI engineering cosmos.",
            primaryLanguage: "Swift",
            starCount: 1420,
            forkCount: 184,
            openIssuesCount: 4,
            commitCount: 840,
            lastPushedAt: now,
            defaultBranch: "main",
            htmlURL: "https://github.com/Mihirmaru22/Plut0",
            domain: .localFirstClient,
            telemetry: AIModelTelemetry(
                baseModelArchitecture: "On-Device CoreML + SwiftData",
                parameterSize: "Local Native",
                quantizationFormat: "FP16 Unified Memory",
                contextWindowLength: 65536,
                evalAccuracyScore: 99.4,
                tokensPerSecond: 180.0,
                latencyMs: 8.0,
                benchmarkName: "Zero-Cloud Latency: 8ms",
                trainingLossSummary: "Fully Deterministic Offline Engine"
            ),
            techStackTags: ["Swift", "SwiftUI", "SwiftData", "MapKit", "CoreLocation", "Local-First"],
            isPinned: true
        )

        // 2. Agentic Search Synthesis Harness
        let agentic = GitHubRepoRecord(
            name: "Agentic-Search-Synthesis-Harness",
            owner: "Mihirmaru22",
            repoDescription: "Multi-agent research swarm with recursive tool calling, source verification, and citation trees.",
            primaryLanguage: "Python",
            starCount: 2850,
            forkCount: 410,
            openIssuesCount: 12,
            commitCount: 460,
            lastPushedAt: calendar.date(byAdding: .hour, value: -6, to: now) ?? now,
            defaultBranch: "main",
            htmlURL: "https://github.com/Mihirmaru22/Agentic-Search-Synthesis-Harness",
            domain: .autonomousAgents,
            telemetry: AIModelTelemetry(
                baseModelArchitecture: "Qwen-2.5-Coder-32B",
                parameterSize: "32B",
                quantizationFormat: "GGUF Q4_K_M",
                contextWindowLength: 131072,
                evalAccuracyScore: 94.2,
                tokensPerSecond: 68.5,
                latencyMs: 140.0,
                benchmarkName: "GAIA Swarm Benchmark: 78.4%",
                trainingLossSummary: "Step Loss: 0.124 · 128k Context Verified"
            ),
            techStackTags: ["Python", "PyTorch", "MCP Protocol", "LangGraph", "FastAPI", "AsyncIO"],
            isPinned: true
        )

        // 3. DeepSeek-R1 Distill GRPO Lab
        let r1Lab = GitHubRepoRecord(
            name: "DeepSeek-R1-Distill-GRPO-Lab",
            owner: "Mihirmaru22",
            repoDescription: "Specialized mathematical and code reasoning distillation pipeline using Group Relative Policy Optimization (GRPO).",
            primaryLanguage: "Python",
            starCount: 5600,
            forkCount: 890,
            openIssuesCount: 18,
            commitCount: 320,
            lastPushedAt: calendar.date(byAdding: .day, value: -1, to: now) ?? now,
            defaultBranch: "main",
            htmlURL: "https://github.com/Mihirmaru22/DeepSeek-R1-Distill-GRPO-Lab",
            domain: .llmReasoning,
            telemetry: AIModelTelemetry(
                baseModelArchitecture: "DeepSeek-V3 ➔ Llama-3.1-8B Distill",
                parameterSize: "8B",
                quantizationFormat: "MLX 4-bit / BF16",
                contextWindowLength: 65536,
                evalAccuracyScore: 96.1,
                tokensPerSecond: 112.0,
                latencyMs: 95.0,
                benchmarkName: "MATH-500: 88.4% · GSM8K: 96.1%",
                trainingLossSummary: "GRPO Reward Convergence: +1.48 Margin"
            ),
            techStackTags: ["Python", "PyTorch", "vLLM", "DeepSpeed", "HuggingFace", "GRPO-RL"],
            isPinned: true
        )

        // 4. Flash Attention 3 Metal Kernel
        let flashMetal = GitHubRepoRecord(
            name: "Flash-Attention-3-Metal-Kernel",
            owner: "Mihirmaru22",
            repoDescription: "Custom Apple Silicon Metal Shading Language (MSL) & Triton attention kernel for M-series unified memory.",
            primaryLanguage: "C++",
            starCount: 1980,
            forkCount: 240,
            openIssuesCount: 6,
            commitCount: 195,
            lastPushedAt: calendar.date(byAdding: .day, value: -3, to: now) ?? now,
            defaultBranch: "main",
            htmlURL: "https://github.com/Mihirmaru22/Flash-Attention-3-Metal-Kernel",
            domain: .mlopsKernels,
            telemetry: AIModelTelemetry(
                baseModelArchitecture: "Apple M-Series Metal Shaders",
                parameterSize: "Kernel Compute",
                quantizationFormat: "FP16 / BF16 Native",
                contextWindowLength: 262144,
                evalAccuracyScore: 99.8,
                tokensPerSecond: 240.0,
                latencyMs: 4.0,
                benchmarkName: "140.0 TFLOPS sustained on M4 Max",
                trainingLossSummary: "2.8x Speedup over PyTorch Naive MSL"
            ),
            techStackTags: ["C++", "Metal MSL", "Triton", "CUDA", "PyTorch C-Extension"],
            isPinned: false
        )

        // 5. Multimodal Vision Action Pipeline
        let visionAction = GitHubRepoRecord(
            name: "Multimodal-Vision-Action-Pipeline",
            owner: "Mihirmaru22",
            repoDescription: "Real-time visual grounding and UI manipulation model for autonomous desktop & browser automation.",
            primaryLanguage: "Python",
            starCount: 3200,
            forkCount: 510,
            openIssuesCount: 9,
            commitCount: 280,
            lastPushedAt: calendar.date(byAdding: .day, value: -5, to: now) ?? now,
            defaultBranch: "main",
            htmlURL: "https://github.com/Mihirmaru22/Multimodal-Vision-Action-Pipeline",
            domain: .visionMultimodal,
            telemetry: AIModelTelemetry(
                baseModelArchitecture: "Pixtral-12B Vision Transformer",
                parameterSize: "12B",
                quantizationFormat: "AWQ 4-bit",
                contextWindowLength: 32768,
                evalAccuracyScore: 91.5,
                tokensPerSecond: 45.0,
                latencyMs: 42.0,
                benchmarkName: "ScreenSpot Grounding: 89.2%",
                trainingLossSummary: "Bounding Box IoU Loss: 0.082"
            ),
            techStackTags: ["Python", "PyTorch", "Transformers", "OpenCV", "Diffusion", "Playwright"],
            isPinned: false
        )

        // 6. Local RAG Neural Index
        let localRAG = GitHubRepoRecord(
            name: "Local-RAG-Neural-Index",
            owner: "Mihirmaru22",
            repoDescription: "Hybrid dense vector + sparse BM25 retrieval engine with semantic chunking and cross-encoder re-ranking.",
            primaryLanguage: "Rust",
            starCount: 1150,
            forkCount: 130,
            openIssuesCount: 3,
            commitCount: 175,
            lastPushedAt: calendar.date(byAdding: .day, value: -8, to: now) ?? now,
            defaultBranch: "main",
            htmlURL: "https://github.com/Mihirmaru22/Local-RAG-Neural-Index",
            domain: .autonomousAgents,
            telemetry: AIModelTelemetry(
                baseModelArchitecture: "BGE-M3 Dense + BM25 Sparse",
                parameterSize: "560M",
                quantizationFormat: "ONNX Int8",
                contextWindowLength: 8192,
                evalAccuracyScore: 93.8,
                tokensPerSecond: 320.0,
                latencyMs: 8.0,
                benchmarkName: "MTEB Retrieval Score: 74.5",
                trainingLossSummary: "Contrastive InfoNCE Loss: 0.041"
            ),
            techStackTags: ["Rust", "FAISS", "Tantivy", "ONNX-Runtime", "Vector-DB"],
            isPinned: false
        )

        return [pluto, agentic, r1Lab, flashMetal, visionAction, localRAG]
    }
}
