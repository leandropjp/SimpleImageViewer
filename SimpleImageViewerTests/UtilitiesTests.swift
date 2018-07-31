import XCTest

class UtilitiesTests: XCTestCase {
    fileprivate let screenRect = CGRect(x: 0, y: 0, width: 640, height: 960)
    
    func testRectForSize() {
        let square = CGSize(width: 600, height: 600)
        let landscape = CGSize(width: 1600, height: 900)
        let portrait = CGSize(width: 900, height: 1600)
        
        let expectedRectForSquare = CGRect(origin: .zero, size: square)
        let expectedRectForLandscape = CGRect(origin: .zero, size: landscape)
        let expectedRectForPortrait = CGRect(origin: .zero, size: portrait)
        
        XCTAssertEqual(expectedRectForSquare, Utilities.rect(forSize: square))
        XCTAssertEqual(expectedRectForLandscape, Utilities.rect(forSize: landscape))
        XCTAssertEqual(expectedRectForPortrait, Utilities.rect(forSize: portrait))
    }
    
    func testAspectFitRectForSizeIntoRect() {
        let square = CGSize(width: 600 , height: 600)
        let landscape = CGSize(width: 1600, height: 900)
        let portrait = CGSize(width: 900, height: 1600)
        
        let expectedAspectFitForSquare = CGRect(x: 0, y: 160, width: 640, height: 640)
        let expectedAspectFitForLandscape = CGRect(x: 0, y: 300, width: 640, height: 360)
        let expectedAspectFitForPortrait = CGRect(x: 50, y: 0, width: 540, height: 960)
        
        XCTAssertEqual(expectedAspectFitForSquare, Utilities.aspectFitRect(forSize: square, insideRect: screenRect))
        XCTAssertEqual(expectedAspectFitForLandscape, Utilities.aspectFitRect(forSize: landscape, insideRect: screenRect))
        XCTAssertEqual(expectedAspectFitForPortrait, Utilities.aspectFitRect(forSize: portrait, insideRect: screenRect))
    }
    
    func testAspectFillRectForSizeIntoRect() {
        let square = CGSize(width: 600 , height: 600)
        let landscape = CGSize(width: 1600, height: 900)
        let portrait = CGSize(width: 900, height: 1600)
        
        let expectedAspectFillForSquare = CGRect(x: 0, y: 0, width: 960, height: 960)
        let expectedAspectFillForLandscape = CGRect(x: 0, y: 0, width: 1706, height: 960)
        let expectedAspectFillForPortrait = CGRect(x: 0, y: 0, width: 640, height: 1137)
        
        XCTAssertEqual(expectedAspectFillForSquare, Utilities.aspectFillRect(forSize: square, insideRect: screenRect))
        XCTAssertEqual(expectedAspectFillForLandscape, Utilities.aspectFillRect(forSize: landscape, insideRect: screenRect))
        XCTAssertEqual(expectedAspectFillForPortrait, Utilities.aspectFillRect(forSize: portrait, insideRect: screenRect))
    }
}
