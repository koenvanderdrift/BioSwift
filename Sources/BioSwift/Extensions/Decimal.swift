//
//  Decimal.swift
//  BioSwift
//
//  Created by Koen van der Drift on 25.05.2026.
//  Copyright © 2026 Koen van der Drift. All rights reserved.
//

import Foundation

extension Decimal {
    /// Returns a Decimal rounded to the requested number of fractional digits.
    public func rounded(scale: Int = 0, mode: Decimal.RoundingMode = .plain) -> Decimal {
        var value = self
        var result = Decimal()
        NSDecimalRound(&result, &value, scale, mode)
        return result
    }

    /// Returns the value rounded to an integer, or nil if it cannot fit in Int.
    public func roundedInt(mode: Decimal.RoundingMode = .plain) -> Int? {
        let value = rounded(scale: 0, mode: mode)

        guard value >= Decimal(Int.min), value <= Decimal(Int.max) else {
            return nil
        }

        return NSDecimalNumber(decimal: value).intValue
    }

    /// Returns a localized display string with a fixed number of fractional digits.
    public func formatted(
        fractionDigits: Int, mode: Decimal.RoundingMode = .plain, locale: Locale = .current
    ) -> String {
        precondition(fractionDigits >= 0, "fractionDigits must be non-negative")

        return rounded(scale: fractionDigits, mode: mode).formatted(
            .number.precision(.fractionLength(fractionDigits)).locale(locale))
    }

}
