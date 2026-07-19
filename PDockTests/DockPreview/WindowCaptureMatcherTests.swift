import XCTest
@testable import PDock

final class WindowCaptureMatcherTests: XCTestCase {
    func testAmbiguousCaptureCandidatesAreRejected() {
        let window = SwitchableWindow(
            id: WindowIdentity(processID: 77, elementID: 1),
            title: "Untitled",
            frame: CGRect(x: 100, y: 100, width: 800, height: 600),
            isMinimized: false
        )
        let candidates = [
            WindowCaptureCandidate(
                windowID: 10,
                processID: 77,
                title: "Untitled",
                frame: window.frame
            ),
            WindowCaptureCandidate(
                windowID: 11,
                processID: 77,
                title: "Untitled",
                frame: window.frame
            )
        ]

        let matches = WindowCaptureMatcher().match(
            windows: [window],
            candidates: candidates
        )

        XCTAssertNil(matches[window.id])
    }
}
