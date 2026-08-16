import SwiftUI

/// Minimal stub for Task 4. Task 5 replaces this body with the full
/// one-thing + up-next list UI; the `store`/`onChange` signature stays
/// stable so `StatusItemController` doesn't need to change.
struct PopoverContentView: View {
    let store: WedgeStore
    let onChange: () -> Void

    var body: some View {
        Text("Wedge")
            .padding()
    }
}
