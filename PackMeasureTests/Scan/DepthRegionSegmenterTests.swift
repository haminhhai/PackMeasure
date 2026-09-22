import XCTest
@testable import PackMeasure

final class DepthRegionSegmenterTests: XCTestCase {
    func testSegmentsCenteredObjectAndRejectsDistantBackground() throws {
        var grid = DepthGrid.fixture(width: 15, height: 15, depth: 3.0)
        grid.fill(x: 4...10, y: 3...11, depth: 1.25, confidence: 2)

        let region = try XCTUnwrap(DepthRegionSegmenter().segment(grid))

        XCTAssertEqual(region.pixelCount, 63)
        XCTAssertEqual(region.bounds, PixelBounds(minX: 4, minY: 3, maxX: 10, maxY: 11))
        XCTAssertEqual(region.seedDepthMeters, 1.25, accuracy: 0.001)
        XCTAssertTrue(region.indices.allSatisfy { grid.depths[$0] < 2.0 })
    }

    func testFollowsGradualDepthAcrossVisibleSideButStopsAtEdge() throws {
        var grid = DepthGrid.fixture(width: 17, height: 11, depth: 3.5)
        for x in 3...13 {
            let slopedDepth = 1.1 + Float(abs(x - 8)) * 0.045
            grid.fill(x: x...x, y: 2...8, depth: slopedDepth, confidence: 2)
        }

        let region = try XCTUnwrap(DepthRegionSegmenter().segment(grid))

        XCTAssertEqual(region.bounds, PixelBounds(minX: 3, minY: 2, maxX: 13, maxY: 8))
        XCTAssertEqual(region.pixelCount, 77)
    }

    func testSegmentsRoundedSlopedSuitcaseAndExcludesFartherFloorAndBackground() throws {
        let width = 21
        let height = 17
        var grid = DepthGrid.fixture(width: width, height: height, depth: 3.4)
        grid.fill(x: 0...(width - 1), y: 14...16, depth: 2.45, confidence: 2)

        let silhouette: [Int: ClosedRange<Int>] = [
            3: 8...12,
            4: 6...14,
            5: 5...15,
            6: 4...16,
            7: 4...16,
            8: 4...16,
            9: 4...16,
            10: 4...16,
            11: 4...16,
            12: 5...15,
            13: 6...14,
        ]
        var expectedIndices = Set<Int>()
        for (y, xRange) in silhouette {
            for x in xRange {
                let slopedDepth = 1.12
                    + Float(abs(x - width / 2)) * 0.035
                    + Float(abs(y - height / 2)) * 0.008
                grid.set(x: x, y: y, depth: slopedDepth, confidence: 2)
                expectedIndices.insert(y * width + x)
            }
        }

        let region = try XCTUnwrap(DepthRegionSegmenter().segment(grid))

        XCTAssertEqual(Set(region.indices), expectedIndices)
        XCTAssertEqual(region.bounds, PixelBounds(minX: 4, minY: 3, maxX: 16, maxY: 13))
        XCTAssertTrue(region.contains(x: 10, y: 8, gridWidth: width))
        XCTAssertFalse(region.contains(x: 3, y: 8, gridWidth: width))
        XCTAssertFalse(region.contains(x: 10, y: 14, gridWidth: width))
    }

    func testExcludesLowConfidencePixelsEvenWhenDepthMatches() throws {
        var grid = DepthGrid.fixture(width: 13, height: 13, depth: 4.0)
        grid.fill(x: 3...9, y: 3...9, depth: 1.0, confidence: 2)
        grid.set(x: 3, y: 6, depth: 1.0, confidence: 0)
        grid.set(x: 9, y: 6, depth: 1.0, confidence: 0)

        let region = try XCTUnwrap(DepthRegionSegmenter(minimumConfidence: 1).segment(grid))

        XCTAssertEqual(region.pixelCount, 47)
        XCTAssertFalse(region.contains(x: 3, y: 6, gridWidth: grid.width))
        XCTAssertFalse(region.contains(x: 9, y: 6, gridWidth: grid.width))
    }

    func testFindsNearbyValidSeedWhenExactCenterIsMissing() throws {
        var grid = DepthGrid.fixture(width: 11, height: 11, depth: .nan, confidence: 0)
        grid.fill(x: 2...8, y: 2...8, depth: 1.4, confidence: 2)
        grid.set(x: 5, y: 5, depth: .nan, confidence: 0)

        let region = try XCTUnwrap(DepthRegionSegmenter().segment(grid))

        XCTAssertEqual(region.pixelCount, 48)
        XCTAssertEqual(region.seedDepthMeters, 1.4, accuracy: 0.001)
    }

    func testReturnsNilWhenNoConfidentCenterSeedExists() {
        let grid = DepthGrid.fixture(width: 9, height: 9, depth: .nan, confidence: 0)

        XCTAssertNil(DepthRegionSegmenter().segment(grid))
    }

    // MARK: - Lateral bleed containment (US1, FR-003)

    /// A carton beside a surface that ramps away from it. Every step is under
    /// the local gradient limit and the far end still sits inside the global
    /// seed-delta budget, so the local and global guards both pass it. Only the
    /// cumulative travel guard stops the walk absorbing the neighbour.
    func testStopsLateralRampOntoAdjacentSurface() throws {
        var grid = DepthGrid.fixture(width: 25, height: 11, depth: 4.0)
        // The carton face under the reticle.
        grid.fill(x: 8...12, y: 3...7, depth: 1.10, confidence: 2)
        // A connected ramp running away to the right in 0.06 m steps.
        for x in 13...22 {
            let rampDepth = 1.10 + Float(x - 12) * 0.06
            grid.fill(x: x...x, y: 3...7, depth: rampDepth, confidence: 2)
        }

        let segmenter = DepthRegionSegmenter()
        let region = try XCTUnwrap(segmenter.segment(grid))

        // Both legacy guards would admit the whole ramp: each step is 0.06 m
        // against a local limit of max(0.075, d * 0.035), and the far end is
        // 0.60 m from the seed against a global budget of max(0.75, 0.495).
        let farEndDelta = (1.10 + 10 * 0.06) - 1.10
        XCTAssertLessThan(farEndDelta, max(0.75, 1.10 * 0.45))
        XCTAssertLessThan(Float(0.06), max(segmenter.localJumpMeters, 1.10 * segmenter.localJumpFraction))

        // The cumulative travel budget cuts the walk off partway along the ramp.
        XCTAssertLessThan(region.bounds.maxX, 22)
        XCTAssertTrue(region.indices.allSatisfy { grid.depths[$0] <= 1.10 + segmenter.maximumCumulativeDepthTravelMeters + 0.001 })
    }

    /// The containment must not clip a carton's own visible faces.
    func testKeepsCartonFacesWithinTheTravelBudget() throws {
        var grid = DepthGrid.fixture(width: 21, height: 13, depth: 4.0)
        // A front face plus a side face receding by 0.03 m per column, a total
        // depth span of 0.18 m across the object.
        grid.fill(x: 6...10, y: 3...9, depth: 1.30, confidence: 2)
        for x in 11...16 {
            grid.fill(x: x...x, y: 3...9, depth: 1.30 + Float(x - 10) * 0.03, confidence: 2)
        }

        let region = try XCTUnwrap(DepthRegionSegmenter().segment(grid))

        XCTAssertEqual(region.bounds, PixelBounds(minX: 6, minY: 3, maxX: 16, maxY: 9))
    }

    /// At a 1.5 m working distance the global budget alone is max(0.75, 0.675)
    /// = 0.75 m, which is larger than many cartons. The travel guard must bound
    /// the region regardless of how gently the background recedes.
    func testBoundsRegionAtTypicalWorkingDistance() throws {
        var grid = DepthGrid.fixture(width: 31, height: 9, depth: 5.0)
        grid.fill(x: 13...17, y: 2...6, depth: 1.50, confidence: 2)
        for x in 18...29 {
            grid.fill(x: x...x, y: 2...6, depth: 1.50 + Float(x - 17) * 0.05, confidence: 2)
        }

        let segmenter = DepthRegionSegmenter()
        let region = try XCTUnwrap(segmenter.segment(grid))

        let budget = max(
            segmenter.maximumCumulativeDepthTravelMeters,
            1.50 * segmenter.maximumCumulativeDepthTravelFraction
        )
        let deepest = region.indices.map { grid.depths[$0] }.max() ?? 0
        XCTAssertLessThanOrEqual(deepest, 1.50 + budget + 0.001)
        XCTAssertLessThan(region.bounds.maxX, 29)
    }

}

private extension DepthGrid {
    static func fixture(
        width: Int,
        height: Int,
        depth: Float,
        confidence: UInt8 = 2
    ) -> DepthGrid {
        DepthGrid(
            width: width,
            height: height,
            depths: Array(repeating: depth, count: width * height),
            confidences: Array(repeating: confidence, count: width * height)
        )
    }

    mutating func fill(
        x xRange: ClosedRange<Int>,
        y yRange: ClosedRange<Int>,
        depth: Float,
        confidence: UInt8
    ) {
        for y in yRange {
            for x in xRange {
                set(x: x, y: y, depth: depth, confidence: confidence)
            }
        }
    }

    mutating func set(x: Int, y: Int, depth: Float, confidence: UInt8) {
        let index = y * width + x
        depths[index] = depth
        confidences[index] = confidence
    }
}
