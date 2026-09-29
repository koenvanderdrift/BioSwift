## BioSwift API design

* What should be public
* What should be private


public:

* creating and editing a sequence
* obtaining sequence properties


`BioMolecule` is generic over a concrete `Chain` type:

```swift
Protein = BioMolecule<ProteinChain>
DNA = BioMolecule<DNAChain>
RNA = BioMolecule<RNAChain>
```

This keeps every molecule's chain collection strongly typed. `ProteinChain` represents
a chain belonging to a protein; `Peptide` represents standalone peptides and digestion
products. Both conform to `AminoAcidChain`.

Structure -> Residue -> Chain -> BioMolecule
Structure -> FunctionalGroup
Residue: AminoAcid, Nucleobase, Nucleoside, Nucleotide

Protein = BioMolecule<ProteinChain>
DNA = BioMolecule<DNAChain>
RNA = BioMolecule<RNAChain>

An oligo would be a protein modification (as a Chain)

protocol RangedChain: subchain range in full chain
protocol Symbolized: letter
protocol Structure: name, formula

If the implementer is something, name the protocol with a noun, e.g. Sequence, View,
Repository
If the implementer is doing something, name the protocol with an adjective ending with
ing, e.g. Loading, Generating, Coordinating
If something is done to the implementer, name the protocol with an adjective ending
with able or ible, e.g. Comparable, Codable, Cachable

struct Chain: Structure
struct ChemicalElement: Structure, Symbolized
struct Residue: Structure
struct Modification: Structure
struct FunctionalGroup: Structure
struct Enzyme

calculators:
Mass
pKA
Digest peptides = protein.digest(using: settings)
Fragment fragments = peptide.fragments()

https://medium.com/@marcosantadev/protocol-composition-in-swift-e2b165ff8106
