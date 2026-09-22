import Testing
@testable import PackMeasure

/// Guards the display contract in
/// specs/001-measurement-accuracy-units/contracts/measurement-display.md.
@Suite("Dimension formatter")
struct DimensionFormatterTests {
    private let length = 0.610
    private let width = 0.508
    private let height = 0.508

    @Test("The compact form labels every value")
    func compactFormLabelsEveryValue() {
        let formatter = DimensionFormatter(unit: .centimeters)
        let compact = formatter.compact(
            lengthMeters: length,
            widthMeters: width,
            heightMeters: height
        )
        #expect(compact == "L 61.0 cm · W 50.8 cm · H 50.8 cm")
    }

    @Test("No rendering produces a bare A x B x C string")
    func neverProducesABareTriple() {
        let formatter = DimensionFormatter(unit: .feetAndInches)
        let compact = formatter.compact(
            lengthMeters: length,
            widthMeters: width,
            heightMeters: height
        )
        #expect(compact.contains("L "))
        #expect(compact.contains("W "))
        #expect(compact.contains("H "))
        #expect(compact.contains("×") == false)
    }

    @Test("The full form produces one labeled row per axis in order")
    func fullFormProducesOneRowPerAxis() {
        let rows = DimensionFormatter(unit: .millimeters).rows(
            lengthMeters: length,
            widthMeters: width,
            heightMeters: height
        )
        #expect(rows.count == 3)
        #expect(rows.map(\.axis) == [.length, .width, .height])
        #expect(rows[0].label == "Length")
        #expect(rows[0].value == "610 mm")
        #expect(rows[1].label == "Width")
        #expect(rows[1].value == "508 mm")
        #expect(rows[2].label == "Height")
        #expect(rows[2].value == "508 mm")
    }

    @Test("VoiceOver output names the axis, the value, and the spelled-out unit")
    func accessibilityLabelIsOneCoherentPhrase() {
        let metric = DimensionFormatter(unit: .centimeters)
        #expect(
            metric.accessibilityLabel(axis: .length, meters: length)
                == "Length, 61.0 centimeters"
        )

        let imperial = DimensionFormatter(unit: .feetAndInches)
        #expect(
            imperial.accessibilityLabel(axis: .height, meters: height)
                == "Height, 1 foot 8 inches"
        )
    }

    @Test("VoiceOver output never reads the raw compact string")
    func accessibilityNeverReadsCompactSymbols() {
        let formatter = DimensionFormatter(unit: .centimeters)
        let label = formatter.accessibilityLabel(axis: .width, meters: width)
        #expect(label.contains("cm") == false)
        #expect(label.hasPrefix("W ") == false)
        #expect(label.contains("centimeters"))
    }

    @Test("Singular units read correctly")
    func singularUnitsReadCorrectly() {
        let formatter = DimensionFormatter(unit: .feetAndInches)
        // 0.3302 m is 13 in: one foot, one inch.
        #expect(
            formatter.accessibilityLabel(axis: .length, meters: 0.3302)
                == "Length, 1 foot 1 inch"
        )
    }

    @Test("A whole triple can be spoken as one summary")
    func summaryJoinsEveryAxis() {
        let summary = DimensionFormatter(unit: .meters).accessibilitySummary(
            lengthMeters: length,
            widthMeters: width,
            heightMeters: height
        )
        #expect(summary == "Length, 0.610 meters, Width, 0.508 meters, Height, 0.508 meters")
    }

    @Test("The formatter renders an item, an estimate, and an angle identically")
    func rendersEveryMeasurementSource() {
        let formatter = DimensionFormatter(unit: .centimeters)
        let item = MeasuredItem(
            name: "Carton",
            lengthMeters: length,
            widthMeters: width,
            heightMeters: height,
            confidence: .high
        )
        let estimate = MeasurementEstimate(
            lengthMeters: length,
            widthMeters: width,
            heightMeters: height,
            confidence: .high,
            sampleCount: 100,
            frameCount: 3
        )
        let angle = AngleMeasurement(
            sequence: 1,
            lengthMeters: length,
            widthMeters: width,
            heightMeters: height,
            pointCloudConfidence: .high,
            agreedWithConsensus: true
        )

        let expected = "L 61.0 cm · W 50.8 cm · H 50.8 cm"
        #expect(formatter.compact(for: item) == expected)
        #expect(formatter.compact(for: estimate) == expected)
        #expect(formatter.compact(for: angle) == expected)
    }

    @Test("Changing the formatter's unit re-renders from the stored meters")
    func rerendersFromStoredMeters() {
        var formatter = DimensionFormatter(unit: .centimeters)
        let metric = formatter.compact(
            lengthMeters: length, widthMeters: width, heightMeters: height
        )
        formatter.unit = .feetAndInches
        let imperial = formatter.compact(
            lengthMeters: length, widthMeters: width, heightMeters: height
        )
        formatter.unit = .centimeters
        let backToMetric = formatter.compact(
            lengthMeters: length, widthMeters: width, heightMeters: height
        )

        #expect(metric != imperial)
        #expect(backToMetric == metric)
    }
}
