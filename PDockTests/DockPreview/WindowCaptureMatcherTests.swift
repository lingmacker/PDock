import XCTest
@testable import PDock

final class WindowCaptureMatcherTests: XCTestCase {
    func testUniqueExactFrameMatchesWhenCaptureTitleIsMissing() {
        let window = SwitchableWindow(
            id: WindowIdentity(processID: 77, elementID: 1),
            title: "Keysmith",
            frame: CGRect(x: 100, y: 100, width: 800, height: 600),
            isMinimized: false
        )
        let candidate = WindowCaptureCandidate(
            windowID: 10,
            processID: 77,
            title: "",
            frame: window.frame
        )

        let matches = WindowCaptureMatcher().match(
            windows: [window],
            candidates: [candidate]
        )

        XCTAssertEqual(matches[window.id], candidate.windowID)
    }

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

    func testNonMainDialogIsNotSwitchable() {
        XCTAssertFalse(
            isSwitchableWindow(
                role: kAXWindowRole as String,
                subrole: "AXDialog",
                isMain: false
            )
        )
    }

    func testOnScreenCandidateDisambiguatesDuplicateFrames() {
        let window = SwitchableWindow(
            id: WindowIdentity(processID: 77, elementID: 1),
            title: "PDock",
            frame: CGRect(x: 58, y: 33, width: 1412, height: 923),
            isMinimized: false
        )
        let candidates = [
            WindowCaptureCandidate(
                windowID: 10,
                processID: 77,
                title: "",
                frame: window.frame
            ),
            WindowCaptureCandidate(
                windowID: 11,
                processID: 77,
                title: "PDock",
                frame: window.frame,
                isOnScreen: true
            )
        ]

        let matches = WindowCaptureMatcher().match(
            windows: [window],
            candidates: candidates
        )

        XCTAssertEqual(matches[window.id], 11)
    }

    func testMinimizedDialogRemainsSwitchable() {
        XCTAssertTrue(
            isSwitchableWindow(
                role: kAXWindowRole as String,
                subrole: "AXDialog",
                isMain: false,
                isMinimized: true
            )
        )
    }

    func testNewestCandidateDisambiguatesMinimizedDuplicateFrames() {
        let window = SwitchableWindow(
            id: WindowIdentity(processID: 77, elementID: 1),
            title: "PDock",
            frame: CGRect(x: 58, y: 33, width: 1412, height: 923),
            isMinimized: true
        )
        let candidates = [
            WindowCaptureCandidate(
                windowID: 40,
                processID: 77,
                title: "",
                frame: window.frame
            ),
            WindowCaptureCandidate(
                windowID: 45,
                processID: 77,
                title: "",
                frame: window.frame
            )
        ]

        let matches = WindowCaptureMatcher().match(
            windows: [window],
            candidates: candidates
        )

        XCTAssertEqual(matches[window.id], 45)
    }

    func testPreviewTitleIncludesApplicationNameForDocumentWindows() {
        XCTAssertEqual(
            windowPreviewTitle(
                applicationName: "Fork",
                windowTitle: "PDock"
            ),
            "Fork — PDock"
        )
        XCTAssertEqual(
            windowPreviewTitle(
                applicationName: "微信",
                windowTitle: "微信"
            ),
            "微信"
        )
    }

    func testOnlyActiveWindowIsKeptForSameFrameTabGroup() {
        let inactive = SwitchableWindow(
            id: WindowIdentity(processID: 77, elementID: 1),
            title: "Inactive",
            frame: CGRect(x: 58, y: 33, width: 1412, height: 923),
            isMinimized: true
        )
        let active = SwitchableWindow(
            id: WindowIdentity(processID: 77, elementID: 2),
            title: "Active",
            frame: inactive.frame,
            isMinimized: false
        )
        let separate = SwitchableWindow(
            id: WindowIdentity(processID: 77, elementID: 3),
            title: "Separate",
            frame: CGRect(x: 200, y: 100, width: 900, height: 700),
            isMinimized: false
        )

        XCTAssertEqual(
            activeWindowsCollapsingTabGroups([inactive, active, separate]).map(\.id),
            [active.id, separate.id]
        )
    }
}
