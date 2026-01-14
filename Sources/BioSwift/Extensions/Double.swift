//
//  Double.swift
//  BioSwift
//
//  Created by Koen van der Drift on 12/22/16.
//  Copyright © 2016 - 2025 Koen van der Drift. All rights reserved.
//

import Foundation

public extension Double {
    @available(macOS 12.0, *)
    func roundedString(to places: Int) -> String {
        return self.formatted(.number.precision(.fractionLength(places)))
    }

    func roundTo(places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }

    // via: https://stackoverflow.com/questions/27338573/rounding-a-double-value-to-x-number-of-decimal-places-in-swift

    func roundedDecimal(to scale: Int = 0, mode: NSDecimalNumber.RoundingMode = .plain) -> Decimal {
        var decimalValue = Decimal(self)
        var result = Decimal()
        NSDecimalRound(&result, &decimalValue, scale, mode)

        return result
    }

    func roundedDecimalAsString(to scale: Int = 0, mode: NSDecimalNumber.RoundingMode = .plain) -> String {
        var decimalValue = roundedDecimal(to: scale, mode: mode)

        return NSDecimalString(&decimalValue, nil)
    }

    func roundToDecimal(_ fractionDigits: Int) -> Double {
        let multiplier = pow(10, Double(fractionDigits))
        return Darwin.round(self * multiplier) / multiplier
    }
}

public extension Decimal {
    @available(macOS 12.0, *)
    func roundedString(to places: Int) -> String {
        return self.formatted(.number.precision(.fractionLength(places)))
    }
    
    func roundedDecimal(to scale: Int = 0, mode: NSDecimalNumber.RoundingMode = .plain) -> Decimal {
        var decimalValue = self
        var result = Decimal()
        NSDecimalRound(&result, &decimalValue, scale, mode)
        return result
    }

    func roundedDouble(to places: Int) -> Double {
        return doubleValue().roundTo(places: places)
    }

    func intValue() -> Int {
        Int(truncating: self as NSNumber)
    }
    
    func doubleValue() -> Double {
        Double(truncating: self as NSNumber)
    }
}
