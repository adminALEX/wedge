import AppKit
import QuartzCore

/// The menu-bar half of the Done moment (spec §3.2): after the title swaps, the status item
/// gets a small spring bump. Skipped under Reduce Motion.
enum StatusItemBump {
    static let scale: CGFloat = 1.08
    static let perceptualDuration: TimeInterval = 0.3
    static let bounce: CGFloat = 0.3
    private static let animationKey = "doneBump"

    /// Scales by `scale` about the centre of `bounds`, for a layer whose anchor point (unit
    /// coordinates) is `anchorPoint`. AppKit owns the anchor point and position of a view's
    /// layer and may reset them on layout, so the bump moves its pivot with the transform instead.
    static func transform(scale: CGFloat, bounds: CGRect, anchorPoint: CGPoint) -> CATransform3D {
        let dx = bounds.midX - (bounds.minX + anchorPoint.x * bounds.width)
        let dy = bounds.midY - (bounds.minY + anchorPoint.y * bounds.height)
        var transform = CATransform3DMakeTranslation(dx, dy, 0)
        transform = CATransform3DScale(transform, scale, scale, 1)
        return CATransform3DTranslate(transform, -dx, -dy, 0)
    }

    /// Springs from `scale` back to identity; the layer's model transform is never changed.
    static func animation(bounds: CGRect, anchorPoint: CGPoint) -> CASpringAnimation {
        let animation = CASpringAnimation(perceptualDuration: perceptualDuration, bounce: bounce)
        animation.keyPath = "transform"
        animation.fromValue = NSValue(
            caTransform3D: transform(scale: scale, bounds: bounds, anchorPoint: anchorPoint))
        animation.toValue = NSValue(caTransform3D: CATransform3DIdentity)
        animation.duration = animation.settlingDuration
        return animation
    }

    static func play(on button: NSStatusBarButton) {
        guard !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion else { return }
        button.wantsLayer = true
        // The new title may have resized the button; bump around its new centre.
        button.window?.layoutIfNeeded()
        guard let layer = button.layer else { return }
        // Same key: a Done during a bump replaces it (restarts), never queues.
        layer.add(animation(bounds: layer.bounds, anchorPoint: layer.anchorPoint), forKey: animationKey)
    }
}
