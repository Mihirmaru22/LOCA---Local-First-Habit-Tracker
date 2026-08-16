import SwiftUI
import Foundation

// MARK: - TechNodeStatus

enum TechNodeStatus: String, Codable, Sendable {
    case mastered   = "Mastered"
    case inProgress = "In Progress"
    case locked     = "Locked"

    var badgeColor: Color {
        switch self {
        case .mastered:   return Color(red: 0.95, green: 0.75, blue: 0.15) // Gold
        case .inProgress: return Color.cyan
        case .locked:     return Color.gray.opacity(0.5)
        }
    }
}

// MARK: - TechTreeNode

struct TechTreeNode: Identifiable, Sendable {
    let id: String
    let title: String
    let tier: Int
    let branch: AIDomain
    let summary: String
    let capability: String
    let icon: String
    let status: TechNodeStatus
    let progress: Double
    let contributingRepos: [String]
    let prerequisiteNodeIDs: [String]

    var tierName: String {
        switch tier {
        case 1: return "Tier I · Foundational"
        case 2: return "Tier II · Intermediate"
        case 3: return "Tier III · Advanced"
        case 4: return "Tier IV · Master"
        default: return "Tier \(tier)"
        }
    }
}

// MARK: - TechTreeEvaluationEngine

enum TechTreeEvaluationEngine {

    /// Evaluates the 18 specialized AI engineering technology nodes based on the user's active repositories.
    static func buildAllNodes(repos: [GitHubRepoRecord]) -> [TechTreeNode] {
        var nodes: [TechTreeNode] = []

        // MARK: - Branch 1: Autonomous Agents & Protocols 🤖

        let agentRepos = repos.filter { $0.domain == .autonomousAgents }
        let hasMcp = agentRepos.contains { $0.techStackTags.contains(where: { $0.localizedCaseInsensitiveContains("mcp") || $0.localizedCaseInsensitiveContains("langgraph") }) }
        let hasRag = repos.contains { $0.name.localizedCaseInsensitiveContains("rag") || $0.repoDescription.localizedCaseInsensitiveContains("rag") }

        nodes.append(
            TechTreeNode(
                id: "agent_1_prompt_tool",
                title: "Prompt Engineering & Function Calling",
                tier: 1,
                branch: .autonomousAgents,
                summary: "Zero-shot prompting, JSON schemas, and deterministic tool dispatch.",
                capability: "Single-turn schema enforcement, system instructions, and tool calling primitives.",
                icon: "terminal.fill",
                status: .mastered,
                progress: 1.0,
                contributingRepos: repos.prefix(2).map(\.name),
                prerequisiteNodeIDs: []
            )
        )

        nodes.append(
            TechTreeNode(
                id: "agent_2_rag_dense",
                title: "Structured Output & Dense RAG",
                tier: 2,
                branch: .autonomousAgents,
                summary: "Vector embeddings, cosine similarity search & chunking pipelines.",
                capability: "Context window grounding, cross-encoder re-ranking, and dense retrieval.",
                icon: "doc.text.magnifyingglass",
                status: hasRag ? .mastered : .inProgress,
                progress: hasRag ? 1.0 : 0.8,
                contributingRepos: repos.filter { $0.name.localizedCaseInsensitiveContains("rag") }.map(\.name),
                prerequisiteNodeIDs: ["agent_1_prompt_tool"]
            )
        )

        nodes.append(
            TechTreeNode(
                id: "agent_3_mcp_swarms",
                title: "MCP Protocol & Multi-Agent Swarms",
                tier: 3,
                branch: .autonomousAgents,
                summary: "Standardized Model Context Protocol servers and coordinated agent graphs.",
                capability: "Asynchronous multi-agent consensus, shared tool execution, and state machines.",
                icon: "point.3.connected.trianglepath.dotted",
                status: hasMcp ? .mastered : .inProgress,
                progress: hasMcp ? 1.0 : 0.6,
                contributingRepos: repos.filter { $0.name.localizedCaseInsensitiveContains("agentic") }.map(\.name),
                prerequisiteNodeIDs: ["agent_2_rag_dense"]
            )
        )

        nodes.append(
            TechTreeNode(
                id: "agent_4_reflection_memory",
                title: "Self-Reflection & Graph Memory",
                tier: 4,
                branch: .autonomousAgents,
                summary: "Episodic memory graphs, self-correction loops & autonomous task delegation.",
                capability: "Multi-step backtracking, long-term memory retrieval, and self-healing agent pipelines.",
                icon: "arrow.triangle.2.circlepath",
                status: hasRag ? .mastered : .inProgress,
                progress: 0.9,
                contributingRepos: repos.filter { $0.name.localizedCaseInsensitiveContains("rag") || $0.name.localizedCaseInsensitiveContains("agentic") }.map(\.name),
                prerequisiteNodeIDs: ["agent_3_mcp_swarms"]
            )
        )

        // MARK: - Branch 2: LLMs, Fine-Tuning & Reasoning 🧠

        let llmRepos = repos.filter { $0.domain == .llmReasoning }
        let hasReasoning = llmRepos.contains { $0.name.localizedCaseInsensitiveContains("r1") || $0.name.localizedCaseInsensitiveContains("grpo") }

        nodes.append(
            TechTreeNode(
                id: "llm_1_transformer_foundations",
                title: "Transformer Self-Attention Foundations",
                tier: 1,
                branch: .llmReasoning,
                summary: "Multi-Head Attention (MHA), Rotary Positional Embeddings (RoPE) & causal masks.",
                capability: "Deep architectural understanding of scaled dot-product attention and token generation.",
                icon: "brain.head.profile",
                status: .mastered,
                progress: 1.0,
                contributingRepos: ["DeepSeek-R1-Distill-GRPO-Lab"],
                prerequisiteNodeIDs: []
            )
        )

        nodes.append(
            TechTreeNode(
                id: "llm_2_lora_qlora",
                title: "LoRA & QLoRA Parameter-Efficient Tuning",
                tier: 2,
                branch: .llmReasoning,
                summary: "Low-rank adapters, 4-bit NormalFloat (NF4) quantization & gradient checkpointing.",
                capability: "Fine-tuning 70B+ parameter models on consumer/single-node hardware.",
                icon: "slider.horizontal.2.square",
                status: .mastered,
                progress: 1.0,
                contributingRepos: ["DeepSeek-R1-Distill-GRPO-Lab"],
                prerequisiteNodeIDs: ["llm_1_transformer_foundations"]
            )
        )

        nodes.append(
            TechTreeNode(
                id: "llm_3_grpo_reasoning",
                title: "GRPO & RL Reasoning Distillation",
                tier: 3,
                branch: .llmReasoning,
                summary: "Group Relative Policy Optimization on mathematical proofs and code execution traces.",
                capability: "Teaching smaller student models long chain-of-thought verification without value models.",
                icon: "bolt.badge.clock.fill",
                status: hasReasoning ? .mastered : .inProgress,
                progress: 1.0,
                contributingRepos: ["DeepSeek-R1-Distill-GRPO-Lab"],
                prerequisiteNodeIDs: ["llm_2_lora_qlora"]
            )
        )

        nodes.append(
            TechTreeNode(
                id: "llm_4_moe_pretraining",
                title: "MoE Sparse Routing & Custom Pretraining",
                tier: 4,
                branch: .llmReasoning,
                summary: "Mixture-of-Experts top-2 gating, auxiliary load-balancing losses & distributed pretraining.",
                capability: "Designing high-parameter architectures with ultra-fast sparse inference compute.",
                icon: "network",
                status: .inProgress,
                progress: 0.45,
                contributingRepos: ["DeepSeek-R1-Distill-GRPO-Lab"],
                prerequisiteNodeIDs: ["llm_3_grpo_reasoning"]
            )
        )

        // MARK: - Branch 3: MLOps, Hardware & Compute Kernels ⚡

        let kernelRepos = repos.filter { $0.domain == .mlopsKernels }
        let hasKernel = !kernelRepos.isEmpty

        nodes.append(
            TechTreeNode(
                id: "kernel_1_pytorch_ops",
                title: "PyTorch Tensor Operations & Autograd",
                tier: 1,
                branch: .mlopsKernels,
                summary: "Dynamic computational graphs, broadcasting rules & custom backward passes.",
                capability: "Writing modular neural network components and numerical loss functions.",
                icon: "square.grid.3x3.fill",
                status: .mastered,
                progress: 1.0,
                contributingRepos: repos.map(\.name),
                prerequisiteNodeIDs: []
            )
        )

        nodes.append(
            TechTreeNode(
                id: "kernel_2_vllm_quant",
                title: "vLLM PagedAttention & Quantization",
                tier: 2,
                branch: .mlopsKernels,
                summary: "KV cache memory management, Continuous Batching, AWQ & GGUF formats.",
                capability: "Achieving 5x-10x higher serving throughput on high-concurrency model APIs.",
                icon: "memorychip",
                status: .mastered,
                progress: 1.0,
                contributingRepos: ["DeepSeek-R1-Distill-GRPO-Lab", "Flash-Attention-3-Metal-Kernel"],
                prerequisiteNodeIDs: ["kernel_1_pytorch_ops"]
            )
        )

        nodes.append(
            TechTreeNode(
                id: "kernel_3_metal_triton",
                title: "Apple Metal MSL & Triton Kernels",
                tier: 3,
                branch: .mlopsKernels,
                summary: "Fused Flash Attention 3 forward passes in Metal Shading Language & Triton.",
                capability: "Writing hardware-specific GPU kernels utilizing shared memory and warp tiling.",
                icon: "cpu.fill",
                status: hasKernel ? .mastered : .inProgress,
                progress: 1.0,
                contributingRepos: ["Flash-Attention-3-Metal-Kernel"],
                prerequisiteNodeIDs: ["kernel_2_vllm_quant"]
            )
        )

        nodes.append(
            TechTreeNode(
                id: "kernel_4_fp8_distributed",
                title: "Distributed Multi-Node FP8 Engines",
                tier: 4,
                branch: .mlopsKernels,
                summary: "Microscaling FP8 gemm kernels, Megatron tensor parallelism & ZeRO-3 stages.",
                capability: "Scaling models across multi-node H100/M-series clusters with minimal communication overhead.",
                icon: "server.rack",
                status: .locked,
                progress: 0.15,
                contributingRepos: [],
                prerequisiteNodeIDs: ["kernel_3_metal_triton"]
            )
        )

        // MARK: - Branch 4: Vision, Multimodal & Embodied AI 👁️

        let visionRepos = repos.filter { $0.domain == .visionMultimodal }
        let hasVision = !visionRepos.isEmpty

        nodes.append(
            TechTreeNode(
                id: "vision_1_vit_foundations",
                title: "Vision Transformers (ViT) & Patching",
                tier: 1,
                branch: .visionMultimodal,
                summary: "Image patch tokenization, spatial position embeddings & visual backbones.",
                capability: "Extracting dense visual feature representations from high-resolution images.",
                icon: "photo.fill",
                status: .mastered,
                progress: 1.0,
                contributingRepos: ["Multimodal-Vision-Action-Pipeline"],
                prerequisiteNodeIDs: []
            )
        )

        nodes.append(
            TechTreeNode(
                id: "vision_2_clip_embeddings",
                title: "CLIP Cross-Modal Joint Embeddings",
                tier: 2,
                branch: .visionMultimodal,
                summary: "Contrastive language-image pre-training and zero-shot visual classification.",
                capability: "Aligning text and visual latent spaces for semantic image search.",
                icon: "eye.fill",
                status: .mastered,
                progress: 1.0,
                contributingRepos: ["Multimodal-Vision-Action-Pipeline"],
                prerequisiteNodeIDs: ["vision_1_vit_foundations"]
            )
        )

        nodes.append(
            TechTreeNode(
                id: "vision_3_grounding_action",
                title: "Visual Grounding & GUI Action Models",
                tier: 3,
                branch: .visionMultimodal,
                summary: "Bounding box tokenization, ScreenSpot grounding & autonomous GUI clicks.",
                capability: "Allowing multimodal models to visually operate operating systems and mobile apps.",
                icon: "cursorarrow.motionlines",
                status: hasVision ? .mastered : .inProgress,
                progress: 1.0,
                contributingRepos: ["Multimodal-Vision-Action-Pipeline"],
                prerequisiteNodeIDs: ["vision_2_clip_embeddings"]
            )
        )

        // MARK: - Branch 5: Local-First & Sovereign Edge Systems 🍏

        nodes.append(
            TechTreeNode(
                id: "edge_1_swift_persistence",
                title: "Swift & Offline Data Architecture",
                tier: 1,
                branch: .localFirstClient,
                summary: "Strongly typed schemas, local disk SQLite stores & zero-latency queries.",
                capability: "Building deterministic offline applications without mandatory cloud backends.",
                icon: "internaldrive.fill",
                status: .mastered,
                progress: 1.0,
                contributingRepos: ["Pluto-Local-First-OS"],
                prerequisiteNodeIDs: []
            )
        )

        nodes.append(
            TechTreeNode(
                id: "edge_2_swiftui_engine",
                title: "SwiftUI Fluid Canvas Architecture",
                tier: 2,
                branch: .localFirstClient,
                summary: "High-performance reactive UI, 60fps animations & hardware-accelerated MapKit.",
                capability: "Engineering executive-grade native macOS/iOS fluid desktop interfaces.",
                icon: "macwindow",
                status: .mastered,
                progress: 1.0,
                contributingRepos: ["Pluto-Local-First-OS"],
                prerequisiteNodeIDs: ["edge_1_swift_persistence"]
            )
        )

        nodes.append(
            TechTreeNode(
                id: "edge_3_local_first_os",
                title: "Sovereign Executive OS & On-Device AI",
                tier: 3,
                branch: .localFirstClient,
                summary: "On-device CoreML neural inference, encrypted Keychain & complete data ownership.",
                capability: "Empowering users with private, beautiful, local-first operating systems.",
                icon: "lock.shield.fill",
                status: .mastered,
                progress: 1.0,
                contributingRepos: ["Pluto-Local-First-OS"],
                prerequisiteNodeIDs: ["edge_2_swiftui_engine"]
            )
        )

        return nodes
    }

    static func calculateOverallMastery(nodes: [TechTreeNode]) -> Double {
        guard !nodes.isEmpty else { return 0.0 }
        let totalScore = nodes.map(\.progress).reduce(0, +)
        return (totalScore / Double(nodes.count)) * 100.0
    }
}
