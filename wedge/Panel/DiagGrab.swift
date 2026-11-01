import AppKit
import SwiftUI

struct DiagGrab: NSViewRepresentable {
    func makeNSView(context: Context) -> GrabView { GrabView() }
    func updateNSView(_ nsView: GrabView, context: Context) {}

    final class GrabView: NSView {
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            guard let window else { return }
            var level: NSView? = superview
            var hops = 0
            while let container = level, hops < 6 {
                if let field = Self.firstTextField(in: container) {
                    let ok = window.makeFirstResponder(field)
                    NSLog("DiagGrab makeFirstResponder=\(ok) hops=\(hops)")
                    return
                }
                level = container.superview
                hops += 1
            }
            NSLog("DiagGrab no field")
        }

        static func firstTextField(in view: NSView) -> NSTextField? {
            for sub in view.subviews {
                if let field = sub as? NSTextField, field.isEditable { return field }
                if let found = firstTextField(in: sub) { return found }
            }
            return nil
        }
    }
}
