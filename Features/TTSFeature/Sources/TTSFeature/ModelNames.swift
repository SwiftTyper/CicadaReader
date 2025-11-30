import Foundation

/// Model repositories on HuggingFace
public enum Repo: String, CaseIterable {
    case kokoro = "FluidInference/kokoro-82m-coreml"

    /// Repository slug (without owner)
    public var name: String {
        switch self {
        case .kokoro:
            return "kokoro-82m-coreml"
        }
    }

    /// Fully qualified HuggingFace repo path (owner/name)
    public var remotePath: String {
        "FluidInference/\(name)"
    }

    /// Local folder name used for caching
    public var folderName: String {
        switch self {
            case .kokoro:
                return "kokoro"
        }
    }
}

/// Centralized model names for all FluidAudio components
public enum ModelNames {
    /// TTS model names
    public enum TTS {

        /// Available Kokoro variants shipped with the library.
        public enum Variant: CaseIterable, Sendable {
            case fiveSecond
            case fifteenSecond

            /// Underlying model bundle filename.
            public var fileName: String {
                switch self {
                case .fiveSecond:
                    return "kokoro_21_5s.mlmodelc"
                case .fifteenSecond:
                    return "kokoro_21_15s.mlmodelc"
                }
            }

            /// Approximate maximum duration in seconds handled by the variant.
            public var maxDurationSeconds: Int {
                switch self {
                case .fiveSecond:
                    return 5
                case .fifteenSecond:
                    return 15
                }
            }
        }

        /// Preferred variant for general-purpose synthesis.
        public static let defaultVariant: Variant = .fifteenSecond

        /// Convenience accessor for bundle name lookup.
        public static func bundle(for variant: Variant) -> String {
            variant.fileName
        }

        /// Default bundle filename (legacy accessor).
        public static var defaultBundle: String {
            defaultVariant.fileName
        }

        /// All Kokoro model bundles required by the downloader.
        public static var requiredModels: Set<String> {
            Set(Variant.allCases.map { $0.fileName })
        }
    }

    static func getRequiredModelNames(for repo: Repo, variant: String?) -> Set<String> {
        switch repo {
        case .kokoro:
            return ModelNames.TTS.requiredModels
        }
    }
}
