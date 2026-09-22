import Testing
@testable import PackMeasure

struct DimensionAxisTests {
    @Test
    func displayNamesAreStable() {
        #expect(DimensionAxis.length.displayName == "Length")
        #expect(DimensionAxis.width.displayName == "Width")
        #expect(DimensionAxis.height.displayName == "Height")
    }

    @Test
    func compactLabelsAreSingleLetters() {
        #expect(DimensionAxis.length.compactLabel == "L")
        #expect(DimensionAxis.width.compactLabel == "W")
        #expect(DimensionAxis.height.compactLabel == "H")
    }

    @Test
    func allCasesAreOrderedLengthWidthHeight() {
        #expect(DimensionAxis.allCases == [.length, .width, .height])
    }
}
