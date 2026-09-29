# BioSwift TODO

## Correctness and API behavior

- Review peptide-fragment adduct handling. Fragment generation currently treats
  `adducts.count` as charge and replaces adducts with protons; divalent or non-proton
  adducts may therefore produce incorrect fragment ions.
- Decide whether `clamped(toSequenceLength:)` should clamp out-of-bounds ranges or be
  renamed to describe its current rejection behavior.
- Revisit `BiologicalRange.isValidRange`, which currently accepts zero even though the
  type represents one-based coordinates.
- Consider making invalid formula input consistently observable. The nonthrowing
  `Formula` initializer currently logs an error and produces an empty formula.
- Replace `fatalError` in bundled-reference convenience accessors with recoverable error
  handling where practical.

## Precision and performance

- Keep mass-tolerance calculations decimal throughout; conversion from binary
  floating-point values can introduce artifacts.
- Bound FASTA parsing concurrency instead of creating one task per record for very large
  files.
- Add an `O(min(m,n))` memory, score-only sequence-alignment mode.
- Explore affine gap penalties and banded alignment for long or closely related
  sequences.

## Concurrency

- Remove or isolate mutable global state in
  `BioSwiftDiagnostics.isDebugLoggingEnabled` for stricter Swift 6 concurrency safety.

## Future capabilities

- Expand UniProt import support.
- Add more substitution matrices and alignment scoring presets.
- Consider returning multiple equally optimal sequence alignments.
