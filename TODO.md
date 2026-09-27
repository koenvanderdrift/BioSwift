• Fragment generation treats adducts.count as charge and replaces the adducts with protons. A single divalent adduct or a sodium adduct would therefore generate incorrect fragment ions. This is separate from the deferred negative-ion work.
PeptideFragmenter.swift

• clamped(toSequenceLength:) rejects out-of-bounds ranges instead of clamping them. Either the behavior or the name should change.
Range.swift

• BiologicalRange.isValidRange accepts zero even though the type is explicitly one-based.
Range.swift

• MassTolerance.value remains a Double and is converted to Dalton/Decimal during calculation. That can reintroduce binary floating-point artifacts into otherwise decimal-based mass calculations.
Search.swift

• The nonthrowing Formula initializer silently converts an invalid formula into an empty formula after only logging the error. This makes invalid user input difficult for an application to distinguish from a legitimate empty formula.
Formula.swift

• Bundled reference convenience accessors terminate the process with fatalError if resources cannot be loaded. That is fairly harsh behavior for a framework API when throwing alternatives already exist.

• FASTA parsing creates one task per record through concurrentMap; a large FASTA file could create thousands of simultaneous tasks. Bounded concurrency or synchronous parsing would be safer.

• BioSwiftDiagnostics.isDebugLoggingEnabled is mutable global state and could become a Swift 6 concurrency issue.

