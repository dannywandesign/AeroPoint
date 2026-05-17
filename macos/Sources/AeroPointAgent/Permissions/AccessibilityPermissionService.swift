import ApplicationServices
import Foundation

public final class AccessibilityPermissionService {
    public init() {}

    public var isTrusted: Bool {
        AXIsProcessTrusted()
    }

    public func requestTrustPrompt() {
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }
}
