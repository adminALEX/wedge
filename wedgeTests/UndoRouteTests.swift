import Testing
@testable import wedge

@Suite("UndoRoute")
@MainActor
struct UndoRouteTests {
    @Test func undoRoutes() {
        #expect(UndoRoute.resolve(fieldHasUnsavedTyping: true, canUndoDone: true) == .text)
        #expect(UndoRoute.resolve(fieldHasUnsavedTyping: false, canUndoDone: true) == .done)
        #expect(UndoRoute.resolve(fieldHasUnsavedTyping: false, canUndoDone: false) == .none)
        #expect(UndoRoute.resolve(fieldHasUnsavedTyping: true, canUndoDone: false) == .text)
    }
}
