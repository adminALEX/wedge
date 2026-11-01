import AppIntents

/// Makes the three actions available in Shortcuts and Spotlight without setup.
nonisolated struct WedgeShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AddToUpNextIntent(),
            phrases: ["Add to Up Next in \(.applicationName)"],
            shortTitle: "Add to Up Next",
            systemImageName: "plus"
        )
        AppShortcut(
            intent: MarkDoneIntent(),
            phrases: ["Mark Done in \(.applicationName)"],
            shortTitle: "Mark Done",
            systemImageName: "checkmark.circle"
        )
        AppShortcut(
            intent: GetNowIntent(),
            phrases: ["What's Now in \(.applicationName)"],
            shortTitle: "Get Now",
            systemImageName: "target"
        )
    }
}
