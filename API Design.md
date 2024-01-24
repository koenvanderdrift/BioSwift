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
