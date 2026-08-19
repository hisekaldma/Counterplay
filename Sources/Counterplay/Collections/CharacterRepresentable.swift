/// A value that can be represented by an extended grapheme cluster.
///
/// Typically conformed to by enums that can be represented by emoji:
///
///     enum Resource {
///         case lumber, wool, grain, brick, ore
///     }
///
///     extension Resource: CharacterRepresentable {
///         init?(character: Character) {
///             switch character {
///             case "🪵": self = .lumber
///             case "🐑": self = .wool
///             case "🌾": self = .grain
///             case "🧱": self = .brick
///             case "🪨": self = .ore
///             default: return nil
///             }
///         }
///
///         var character: Character {
///             switch self {
///             case .lumber: "🪵"
///             case .wool: "🐑"
///             case .grain: "🌾"
///             case .brick: "🧱"
///             case .ore: "🪨"
///             }
///         }
///     }
public nonisolated protocol CharacterRepresentable {
    /// Creates a new instance with the specified character.
    init?(character: Character)

    /// The character representing this value.
    var character: Character { get }
}
