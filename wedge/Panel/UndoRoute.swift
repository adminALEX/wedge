/// What ⌘Z undoes in the panel: unsaved typing in the focused field wins over Undo Done.
enum UndoRoute: Equatable {
    /// Leave ⌘Z to the focused field's own undo.
    case text
    /// Undo the last Done.
    case done
    case none

    static func resolve(fieldHasUnsavedTyping: Bool, canUndoDone: Bool) -> UndoRoute {
        if fieldHasUnsavedTyping { return .text }
        return canUndoDone ? .done : .none
    }
}
