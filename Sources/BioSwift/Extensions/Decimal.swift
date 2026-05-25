//
//  Decimal.swift
//  BioSwift
//
//  Created by Koen van der Drift on 25.05.2026.
//

import Foundation

func decimal(_ value: String) -> Decimal {
    guard let result = Decimal(string: value, locale: Locale(identifier: "en_US_POSIX")) else {
        preconditionFailure("Invalid Decimal test value: \(value)")
    }

    return result
}

public extension Decimal {
    /// Returns a Decimal rounded to the requested number of fractional digits.
    func rounded(
        scale: Int = 0,
        mode: Decimal.RoundingMode = .plain
    ) -> Decimal {
        var value = self
        var result = Decimal()
        NSDecimalRound(&result, &value, scale, mode)
        return result
    }

    /// Returns the value rounded to an integer, or nil if it cannot fit in Int.
    func roundedInt(
        mode: Decimal.RoundingMode = .plain
    ) -> Int? {
        let value = rounded(scale: 0, mode: mode)

        guard value >= Decimal(Int.min),
              value <= Decimal(Int.max) else {
            return nil
        }

        return NSDecimalNumber(decimal: value).intValue
    }

    /// Returns a localized display string with a fixed number of fractional digits.
    func formatted(
        fractionDigits: Int,
        mode: Decimal.RoundingMode = .plain,
        locale: Locale = .current
    ) -> String {
        precondition(fractionDigits >= 0, "fractionDigits must be non-negative")

        return rounded(scale: fractionDigits, mode: mode)
            .formatted(
                .number
                    .precision(.fractionLength(fractionDigits))
                    .locale(locale)
            )
    }

    /// Converts the Decimal to Double without additional rounding.
    var asDouble: Double {
        NSDecimalNumber(decimal: self).doubleValue
    }

    /// Rounds as Decimal first, then converts to Double.
    func roundedDouble(
        scale: Int,
        mode: Decimal.RoundingMode = .plain
    ) -> Double {
        rounded(scale: scale, mode: mode).asDouble
    }
}
