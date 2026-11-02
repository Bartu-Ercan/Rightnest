/// Presentation state only. Permission is always established by the live OS check,
/// never by a saved preference, an opened Settings page, or the prompt's return value.
public enum PermissionFlow: Equatable, Sendable {
    case required, waiting, granted, revoked

    public init(trusted: Bool, requested: Bool, previouslyGranted: Bool) {
        if trusted { self = .granted }
        else if previouslyGranted { self = .revoked }
        else if requested { self = .waiting }
        else { self = .required }
    }
}
