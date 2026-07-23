import CoreGraphics
import Foundation

struct WindowCaptureCandidate: Sendable {
    let windowID: UInt32
    let processID: Int32
    let title: String
    let frame: CGRect
    let isOnScreen: Bool

    init(
        windowID: UInt32,
        processID: Int32,
        title: String,
        frame: CGRect,
        isOnScreen: Bool = false
    ) {
        self.windowID = windowID
        self.processID = processID
        self.title = title
        self.frame = frame
        self.isOnScreen = isOnScreen
    }
}

struct WindowCaptureMatcher {
    func match(
        windows: [SwitchableWindow],
        candidates: [WindowCaptureCandidate],
        preferredCandidateIDs: [WindowIdentity: UInt32] = [:]
    ) -> [WindowIdentity: UInt32] {
        let candidateIndexByWindow = windows.map { window in
            let matchingIndexes = candidates.indices.filter { index in
                matches(window, candidates[index])
            }
            return disambiguate(
                window: window,
                candidateIndexes: matchingIndexes,
                candidates: candidates,
                preferredCandidateID: preferredCandidateIDs[window.id]
            )
        }

        var result: [WindowIdentity: UInt32] = [:]
        for (windowIndex, candidateIndex) in candidateIndexByWindow.enumerated() {
            guard let candidateIndex else {
                continue
            }

            let matchingWindowCount = candidateIndexByWindow.count {
                $0 == candidateIndex
            }
            guard matchingWindowCount == 1 else {
                continue
            }
            result[windows[windowIndex].id] = candidates[candidateIndex].windowID
        }
        return result
    }

    private func disambiguate(
        window: SwitchableWindow,
        candidateIndexes: [Int],
        candidates: [WindowCaptureCandidate],
        preferredCandidateID: UInt32?
    ) -> Int? {
        if candidateIndexes.count == 1 {
            return candidateIndexes[0]
        }

        if
            let preferredCandidateID,
            let preferredIndex = candidateIndexes.first(where: {
                candidates[$0].windowID == preferredCandidateID
            })
        {
            return preferredIndex
        }

        let exactTitleMatches = candidateIndexes.filter { index in
            !candidates[index].title.isEmpty
                && candidates[index].title == window.title
        }
        if exactTitleMatches.count == 1 {
            return exactTitleMatches[0]
        }

        let onScreenMatches = candidateIndexes.filter {
            candidates[$0].isOnScreen
        }
        if onScreenMatches.count == 1 {
            return onScreenMatches[0]
        }
        if window.isMinimized {
            return candidateIndexes.max {
                candidates[$0].windowID < candidates[$1].windowID
            }
        }
        return nil
    }

    private func matches(
        _ window: SwitchableWindow,
        _ candidate: WindowCaptureCandidate
    ) -> Bool {
        guard window.id.processID == candidate.processID else {
            return false
        }

        let tolerance = 2.0
        return abs(window.frame.minX - candidate.frame.minX) <= tolerance
            && abs(window.frame.minY - candidate.frame.minY) <= tolerance
            && abs(window.frame.width - candidate.frame.width) <= tolerance
            && abs(window.frame.height - candidate.frame.height) <= tolerance
    }
}
