//
//  FragmentAdductStateGenerator.swift
//  BioSwift
//

enum IonPolarity {
    case positive
    case negative

    func includes(_ charge: Charge) -> Bool {
        switch self {
        case .positive:
            charge > 0
        case .negative:
            charge < 0
        }
    }
}

/// Generates the unique adduct combinations available to product ions while
/// preserving the precursor's actual adduct composition.
struct FragmentAdductStateGenerator {
    let adducts: [Adduct]
    let polarity: IonPolarity
    let maximumAbsoluteCharge: Int

    func states() -> [[Adduct]] {
        let matchingAdducts = adducts.filter { polarity.includes($0.charge) }
        var result: [[Adduct]] = []

        func addCombinations(startingAt index: Int, current: [Adduct], charge: Charge) {
            for adductIndex in index..<matchingAdducts.count {
                let adduct = matchingAdducts[adductIndex]
                let updatedCharge = charge + adduct.charge

                guard abs(updatedCharge) <= maximumAbsoluteCharge else {
                    continue
                }

                let combination = current + [adduct]
                if result.contains(combination) == false {
                    result.append(combination)
                }

                addCombinations(
                    startingAt: adductIndex + 1,
                    current: combination,
                    charge: updatedCharge
                )
            }
        }

        addCombinations(startingAt: 0, current: [], charge: 0)
        return result.sorted { lhs, rhs in
            abs(lhs.totalCharge) < abs(rhs.totalCharge)
        }
    }
}

private extension Array where Element == Adduct {
    var totalCharge: Charge {
        reduce(0) { $0 + $1.charge }
    }
}
