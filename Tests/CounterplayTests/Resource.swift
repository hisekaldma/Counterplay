import Counterplay

enum Resource: UInt, SmallRawUInt8 {
    case lumber
    case wool
    case grain
    case brick
    case ore
    case gold
    case silver
    case bronze
}

extension Resource: CustomDebugStringConvertible {
    var debugDescription: String {
        switch self {
        case .lumber: ".lumber"
        case .wool:   ".wool"
        case .grain:  ".grain"
        case .brick:  ".brick"
        case .ore:    ".ore"
        case .gold:   ".gold"
        case .silver: ".silver"
        case .bronze: ".bronze"
        }
    }
}

extension Resource: CharacterRepresentable {
    init?(character: Character) {
        switch character {
        case "🪵": self = .lumber
        case "🐑": self = .wool
        case "🌾": self = .grain
        case "🧱": self = .brick
        case "🪨": self = .ore
        case "🥇": self = .gold
        case "🥈": self = .silver
        case "🥉": self = .bronze
        default: return nil
        }
    }

    var character: Character {
        switch self {
        case .lumber: "🪵"
        case .wool: "🐑"
        case .grain: "🌾"
        case .brick: "🧱"
        case .ore: "🪨"
        case .gold: "🥇"
        case .silver: "🥈"
        case .bronze: "🥉"
        }
    }
}
