import XCTest
@testable import ArmoryInventory

final class FirearmConfigurationResolutionTests: XCTestCase {
    func testPartsOverrideEachFieldIndependentlyInPriorityOrder() {
        let firearmCaliber = Caliber(name: "9mm")
        let upperCaliber = Caliber(name: "5.56 NATO")
        let slideCaliber = Caliber(name: ".40 S&W")
        let firearm = Firearm(
            brand: "Example",
            modelName: "Host",
            purchasePriceCents: 0,
            type: .rifle,
            action: .semiAuto,
            barrelLengthInches: 16,
            caliber: firearmCaliber
        )
        let upper = Part(
            brand: "Example", modelName: "Upper", type: .upperReceiver,
            purchasePriceCents: 0, barrelLengthInches: 14.5, caliber: upperCaliber
        )
        let slide = Part(
            brand: "Example", modelName: "Slide", type: .slide,
            purchasePriceCents: 0, caliber: slideCaliber
        )
        let barrel = Part(
            brand: "Example", modelName: "Barrel", type: .barrel,
            purchasePriceCents: 0, barrelLengthInches: 10.3
        )

        let result = firearm.resolvedConfiguration(parts: [upper, slide, barrel])

        XCTAssertEqual(result.caliber?.name, ".40 S&W")
        XCTAssertEqual(result.caliberSource, .slide)
        XCTAssertTrue(result.caliberSourcePart === slide)
        XCTAssertEqual(result.barrelLengthInches, 10.3)
        XCTAssertEqual(result.barrelLengthSource, .barrel)
        XCTAssertTrue(result.barrelLengthSourcePart === barrel)
        XCTAssertEqual(firearm.caliber?.name, "9mm")
        XCTAssertEqual(firearm.barrelLengthInches, 16)
    }

    func testLinkedKitPartsParticipateInResolution() {
        let firearm = Firearm(
            brand: "Example", modelName: "Host", purchasePriceCents: 0,
            type: .rifle, action: .semiAuto
        )
        let caliber = Caliber(name: "300 BLK")
        let barrel = Part(
            brand: "Example", modelName: "Kit Barrel", type: .barrel,
            purchasePriceCents: 0, barrelLengthInches: 8, caliber: caliber
        )
        let component = KitComponent(category: .part, part: barrel)
        let kit = Kit(name: "Upper", kind: .upperReceiver, status: .linked, firearm: firearm, components: [component])
        component.kit = kit

        let result = firearm.resolvedConfiguration(kits: [kit])

        XCTAssertEqual(result.caliber?.name, "300 BLK")
        XCTAssertEqual(result.barrelLengthInches, 8)
        XCTAssertEqual(result.caliberSource, .barrel)
        XCTAssertTrue(result.caliberSourcePart === barrel)
    }
}
