# BioSwift

BioSwift is a Swift package for working with proteins, peptides, DNA, RNA, glycans,
molecular formulas, and common bioinformatics calculations.

The project is educational and under active development. 

Note that the API may change, and BioSwift is not intended for clinical or production-critical use.

## Requirements

- Swift 6
- macOS 15 or later
- iOS 18 or later

BioSwift has no external package dependencies.

## Adding BioSwift

After adding the package to an Xcode project, add `BioSwift` to the target dependencies:

```swift
import BioSwift
```

## Capabilities

- Protein, peptide, DNA, and RNA models with one or more chains
- Branched glycan models with condensed and extended IUPAC parsing and formatting
- FASTA parsing and molecule creation from FASTA records
- Monoisotopic, average, and nominal mass calculations
- Molecular formulas, modifications, adducts, and cross-links
- Bundled chemical-element, amino-acid, enzyme, hydrophobicity, and modification data
- Protein digestion, peptide fragmentation, and oligonucleotide fragmentation
- Protein extinction coefficients, concentration calculations, hydropathy profiles, and
  isoelectric-point calculations
- DNA transcription and DNA/RNA translation
- DNA and RNA complement, reverse, and reverse-complement operations
- Sequence and mass searching
- Needleman-Wunsch global alignment and Smith-Waterman local alignment
- BLOSUM62, nucleotide, protein-identity, and custom alignment scoring

## Molecules and sequences

Create molecules from a sequence string or from multiple chains:

```swift
let protein = Protein(sequence: "MKTAYIAKQRQIS")
let dna = DNA(sequence: "GATTACA")
let rna = RNA(sequence: "GAUUACA")

let multiChainProtein = Protein(sequences: ["MPEPTIDE", "ANOTHER"])

print(protein.sequence)
print(dna.sequenceLength)
```

Sequence positions and ranges throughout BioSwift are zero-based. Swift ranges are
half-open, so `2..<5` contains positions 2, 3, and 4.

The convenience properties return the first chain. For multi-chain molecules, use
`sequence(chainIndex:)` and `sequenceLength(chainIndex:)` with an explicit chain index,
or use a chain's name:

```swift
let chain = ProteinChain(sequence: "ANOTHER", name: "light chain")
let namedProtein = Protein(chains: [chain])

print(namedProtein.sequence(chainName: "light chain") as Any) // Optional("ANOTHER")
```

Name-based accessors return `nil` when no chain has that name. If names are duplicated,
they deterministically select the first matching chain.

`Protein` stores `ProteinChain` values, while `Peptide` represents standalone peptides
and products of protein digestion. BioSwift does not impose an arbitrary sequence-length
cutoff between the two concepts.

### DNA and RNA transformations

```swift
let dna = DNA(sequence: "ATCG")

print(dna.complement.sequence)        // TAGC
print(dna.reverse.sequence)           // GCTA
print(dna.reverseComplement.sequence) // CGAT
```

The same properties are available on `RNA`, `DNAChain`, and `RNAChain`.

### Transcription and translation

```swift
let dna = DNA(sequence: "ATGGCC")
let rna = dna.transcribed()
let protein = dna.translated()

print(rna.sequence)     // AUGGCC
print(protein.sequence) // MA
```

### Nucleotides and oligonucleotide fragmentation

DNA and RNA expose their `Nucleotide` residues directly. Sequence truncation removes a
zero-based, half-open range while preserving the remaining nucleotides:

```swift
let dna = try DNA(sequence: "ATCG")

print(dna.nucleotides.map(\.oneLetterCode)) // ["A", "T", "C", "G"]
print(try dna.truncate(by: 1..<3).sequence) // AG
```

`OligonucleotideFragmenter` calculates negatively charged McLuckey terminal product ions
for a `DNAChain` or `RNAChain`. It produces a, a−B, b, c, and d five-prime ions and w, x,
y, and z three-prime ions, as well as the precursor ion:

```swift
let chain = try RNAChain(sequence: "ACGU")
let precursor = try chain.ionized(with: [negativeProtonAdduct])
let fragmenter = OligonucleotideFragmenter(precursor: precursor)

let fragments = fragmenter.fragments
let w2 = fragmenter.fragment(at: 2, for: .wIon)

print(w2?.structure.sequenceString as Any) // Optional("GU")
print(w2?.monoisotopicMass as Any)
```

The precursor's negative charge determines the available product charge states. Use
`fivePrimeIons()`, `threePrimeIons()`, or `fragment(at:for:with:)` to select products.

## Glycans

`Glycan` represents a rooted tree whose root is the reducing-end or
attachment-proximal monosaccharide. Parse branched condensed or extended IUPAC notation
with `GlycanIUPACParser`:

```swift
let lactose = try GlycanIUPACParser().parse(
    "Gal(b1-4)Glc",
    name: "Lactose"
)
let branched = try GlycanIUPACParser().parse("Man(a1-3)[Man(a1-6)]Man")

print(lactose.iupacCondensed) // Gal(b1-4)Glc
print(lactose.iupacExtended)  // β-D-Galp-(1→4)-D-Glcp
print(lactose.formulaString)  // C12H22O11
print(branched.monosaccharideCount) // 3
```

Glycans also support programmatic construction from `Monosaccharide` values and
`GlycosidicLinkage` values. Use `add(_:to:linkage:)` to create branches, and inspect
`composition`, `reducingEnd`, and `nonReducingEnds` for structural information.

Attach a glycan to a protein residue with `glycosylate(with:at:chainIndex:)`. The method
creates the modification and automatically removes the water lost during glycosidic bond
formation:

```swift
var protein = Protein(sequence: "NVT")
let glycan = try GlycanIUPACParser().parse("Gal(b1-4)GlcNAc", name: "LacNAc")

try protein.glycosylate(with: glycan, at: 0)
```

Use `glycosylated(with:at:chainIndex:)` when a modified copy is preferred.

## Sequence alignment

BioSwift supports Needleman-Wunsch global alignment and Smith-Waterman local alignment
for proteins, DNA, and RNA. Protein alignment uses BLOSUM62 by default; DNA and RNA use
nucleotide match/mismatch scoring.

```swift
let first = DNA(sequence: "GATTACA")
let second = DNA(sequence: "GCATGCT")

let result = try first.align(
    with: second,
    algorithm: .needlemanWunsch
)

print(result.firstAlignedSequence)
print(result.secondAlignedSequence)
print(result.score)
print(result.identity)
```

Local alignment uses the same API:

```swift
let result = try first.align(with: second, algorithm: .smithWaterman)
```

For multi-chain molecules, select both chains explicitly:

```swift
let result = try firstProtein.align(
    with: secondProtein,
    chainIndex: 1,
    otherChainIndex: 0
)
```

### Alignment conventions

- Positive scores are rewards, negative scores are penalties, and zero is neutral.
- Gap scoring is linear and applied once per gap residue.
- A substitution matrix takes precedence over the basic match and mismatch scores.
- `firstRange` and `secondRange` are zero-based, half-open ranges in the original,
  unaligned sequences.
- A gap is represented by a `nil` residue and index in an `AlignmentColumn`.
- Equal traceback scores prefer diagonal, deletion, then insertion.
- Equal Smith-Waterman maxima use the first cell encountered in row-major order.
- For sequence lengths `m` and `n`, alignment uses `O(mn)` time and `O(mn)` memory.

Custom scoring is available at both the chain and molecule levels:

```swift
let scoring = AlignmentScoring.nucleotide(match: 3, mismatch: -2, gap: -4)
let result = DNAChain(sequence: "GATTACA").align(
    with: DNAChain(sequence: "GCATGCT"),
    algorithm: .needlemanWunsch,
    scoring: scoring
)
```

## Masses and formulas

Molecules expose monoisotopic, average, and nominal masses calculated from their
residues, modifications, cross-links, and adducts:

```swift
let peptide = Peptide(sequence: "PEPTIDE")

print(peptide.formulaString)
print(peptide.monoisotopicMass)
print(peptide.averageMass)
```

Mass values use `Decimal` through the `Dalton` type alias.

## FASTA

Parse FASTA text asynchronously and create typed molecules from its records:

```swift
let records = try await FastaParser().parseFasta(fastaText)
let proteins = records.map(Protein.init(fastaRecord:))
```

`FastaParser` can also parse bundled files or raw `Data`.

## Protein calculations

BioSwift includes:

- Enzymatic digestion with configurable missed cleavages
- Peptide fragmentation and neutral-loss variants
- Molar and percent extinction coefficients
- Beer-Lambert concentration calculations
- Hydrophobicity values and sliding-window profiles
- Isoelectric-point calculations with configurable terminal ionization

Bundled reference libraries provide standard amino acids, enzymes, hydrophobicity
scales, chemical elements, and modification vocabularies.

## Testing

The test suite uses Swift Testing and covers molecule construction, formulas and masses,
reference loading, FASTA workflows, protein calculations, DNA/RNA operations and
fragmentation, glycans and IUPAC parsing, and sequence alignment.

## Project status

Known issues and future work are tracked in [TODO.md](TODO.md). BioSwift is suitable for
education and experimentation, but its results should be independently validated before
being used in scientific decision-making.

## Disclaimer

Although care has been taken with generated data, there are no warranties regarding its
correctness or completeness. All output is provided for research, educational, and
informational purposes and must not be used as a substitute for professional medical
advice, diagnosis, treatment, or care.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.
