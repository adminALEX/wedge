import Foundation

/// Which running copy of Wedge a new launch hands off to (spec §10.3). Copies are ordered by
/// launch date, then process ID, so every copy agrees on which is oldest: a newer copy defers to
/// the oldest live one and exits, and the oldest keeps running. Two copies starting together
/// therefore leave exactly one, and a copy that is already quitting is never asked to reopen.
enum SingleInstance {
    struct Copy: Equatable {
        let processID: pid_t
        /// Nil when Launch Services did not record one; it then counts as the oldest possible.
        let launchDate: Date?
        let isTerminated: Bool
    }

    /// The copy `current` should hand off to, or nil when `current` is the oldest live copy.
    static func handOffTarget(current: Copy, running: [Copy]) -> Copy? {
        running
            .filter { !$0.isTerminated && $0.processID != current.processID && isOlder($0, than: current) }
            .min { isOlder($0, than: $1) }
    }

    static func isOlder(_ lhs: Copy, than rhs: Copy) -> Bool {
        let lhsDate = lhs.launchDate ?? .distantPast
        let rhsDate = rhs.launchDate ?? .distantPast
        return lhsDate != rhsDate ? lhsDate < rhsDate : lhs.processID < rhs.processID
    }
}
