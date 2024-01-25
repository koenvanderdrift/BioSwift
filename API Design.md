## BioSwift API design

* What should be public
* What should be private


public:

* creating and editing a sequence
* obtaining sequence properties


BioMolecule2

Ideally we should have:

Protein = BioMolecule<AminoAcid>
DNA = BioMolecule<Nucleotide>
etc

therefore: 

struct BioMolecule<T: Residue>

A BioMolecule consists of at least one Chain:

public struct BioMolecule<T: Residue> {
    public var name: String = ""
    public var chains: [Chain<T>] = []
}

But what if a BioMolecule consists of 2 different Residue chains? Eg protein with oligo?
No problem, oligo will be a Chain as a modification

Structure -&gt; Residue -&gt; Chain -&gt; BioMolecule
Structure -&gt; FunctionalGroup
Residue: AminoAcid, Nucleobase, Nucleoside, Nucleotide

Protein = BioMolecule&lt;AminoAcid&gt;
DNA = BioMolecule&lt;Nucleotide&gt;
RNA = BioMolecule&lt;Nucleotide&gt;

An oligo would be a protein modification (as a Chain)

protocol RangedChain: subchain range in full chain
protocol Modifiable: add and remove modifications
protocol Symbolized: letter
protocol Structure: name, formula

If the implementer is something, name the protocol with a noun, e.g. Sequence, View,
Repository
If the implementer is doing something, name the protocol with an adjective ending with
ing, e.g. Loading, Generating, Coordinating
If something is done to the implementer, name the protocol with an adjective ending
with able or ible, e.g. Comparable, Codable, Cachable

struct Chain: Structure, modifiable
struct ChemicalElement: Structure, Symbolized
struct Residue: Structure, Modifiable
struct Modification, LocalizedModification: Structure
struct FunctionalGroup: Structure
struct Enzyme

calculators:
Mass
pKA
Digest peptides = protein.digest(using: settings)
Fragment fragments = peptide.fragments()

https://medium.com/@marcosantadev/protocol-composition-in-swift-e2b165ff8106
