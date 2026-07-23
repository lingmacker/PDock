import CoreGraphics
import Foundation

struct WindowCaptureCandidate: Sendable {
    let windowID: UInt32
    let processID: Int32
    let title: String
    let frame: CGRect
}

struct WindowCaptureMatcher {
    func match(
        windows: [SwitchableWindow],
        candidates: [WindowCaptureCandidate]
    ) -> [WindowIdentity: UInt32] {
        let candidateIndexesByWindow = windows.map { window in
            candidates.indices.filter { index in
                matches(window, candidates[index])
            }
        }

        var result: [WindowIdentity: UInt32] = [:]
        for (windowIndex, candidateIndexes) in candidateIndexesByWindow.enumerated() {
            guard candidateIndexes.count == 1, let candidateIndex = candidateIndexes.first else {
                continue
            }

            let matchingWindowCount = candidateIndexesByWindow.count {
                $0.contains(candidateIndex)
            }
            guard matchingWindowCount == 1 else {
                continue
            }
            result[windows[windowIndex].id] = candidates[candidateIndex].windowID
        }
        return result
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
