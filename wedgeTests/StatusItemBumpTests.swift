import AppKit
import QuartzCore
import Testing

@testable import wedge

@Suite("StatusItemBump")
@MainActor
struct StatusItemBumpTests {
    private let bounds = CGRect(x: 0, y: 0, width: 80, height: 22)

    /// Where a point in bounds coordinates lands, relative to the anchor point, once transformed.
    private func apply(_ transform: CATransform3D, to point: CGPoint, anchorPoint: CGPoint) -> CGPoint {
        let anchor = CGPoint(x: anchorPoint.x * bounds.width, y: anchorPoint.y * bounds.height)
        let relative = CGPoint(x: point.x - anchor.x, y: point.y - anchor.y)
        return relative.applying(CATransform3DGetAffineTransform(transform))
    }

    @Test(arguments: [CGPoint.zero, CGPoint(x: 0.5, y: 0.5), CGPoint(x: 1, y: 0)])
    func centreStaysPut(anchorPoint: CGPoint) {
        let transform = StatusItemBump.transform(scale: 1.08, bounds: bounds, anchorPoint: anchorPoint)
        let centre = CGPoint(x: bounds.midX, y: bounds.midY)
        let moved = apply(transform, to: centre, anchorPoint: anchorPoint)
        let expected = apply(CATransform3DIdentity, to: centre, anchorPoint: anchorPoint)
        #expect(abs(moved.x - expected.x) < 0.0001)
        #expect(abs(moved.y - expected.y) < 0.0001)
    }

    @Test func cornerMovesOutwardFromCentre() {
        let transform = StatusItemBump.transform(scale: 1.08, bounds: bounds, anchorPoint: .zero)
        let corner = apply(transform, to: .zero, anchorPoint: .zero)
        #expect(abs(corner.x - (40 - 40 * 1.08)) < 0.0001)
        #expect(abs(corner.y - (11 - 11 * 1.08)) < 0.0001)
    }

    @Test func animationSpringsFromBumpBackToIdentity() throws {
        let animation = StatusItemBump.animation(bounds: bounds, anchorPoint: .zero)
        #expect(animation.keyPath == "transform")
        let to = try #require(animation.toValue as? NSValue)
        #expect(CATransform3DIsIdentity(to.caTransform3DValue))
        #expect(animation.duration > 0 && animation.duration < 1)
        #expect(StatusItemBump.scale == 1.08)
    }
}
