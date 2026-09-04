import SwiftUI

private struct EndSessionActionKey: EnvironmentKey {
    static let defaultValue: () -> Void = {}
}

extension EnvironmentValues {
    var endSession: () -> Void {
        get { self[EndSessionActionKey.self] }
        set { self[EndSessionActionKey.self] = newValue }
    }
}
