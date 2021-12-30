//
//  Fragment.swift
//  BioSwift
//
//  Created by Koen van der Drift on 4/12/19.
//  Copyright © 2019 Koen van der Drift. All rights reserved.
//

import Foundation

public enum FragmentType { // this is only for peptides...
    case precursor
    case immonium
    case nTerminal
    case cTerminal
    case undefined
}

public protocol Fragment {
    var fragmentType: FragmentType { get set }
}


/*
 
 Mongo Oligo Mass Calculator v2.06

 Disclaimer
 Introduction and history
 Interface use and options
 Sequence
 Calculation
 Options
 5' and 3' terminal ends
 Memories
 User residue 'N'
 Output
 Feedback
 References

 Disclaimer

 Before using any of our programs, please read this.
 back to menu
 Introduction and history

 The Mongo Oligo Mass Calculator is a tool for calculating masses of oligonucleotides and fragments obtained by collision induced dissociation (CID) or enzymatic digests.
 Mongo Oligo was a program, originally written in Fortran on a MAC by Pat Limbach, Steven Pomerantz and Jef Rozenski. The current version is rewritten for JavaScript 1.1. In order to let all the functions of this program work, you need to enable JavaScript in the settings of your web browser.
 The current version includes mass calculation of oligonucleotides, CID fragments, endo- and exonuclease digestion. It contains extra output options and utilities for handling the input sequence and user residue assignment. Also, an extensive help is provided.
 back to menu
 Sequence

 A sequence should be entered in the input window starting from 5' end down to the 3' end of the oligonucleotide.
 Modified residues can be entered using one letter codes as defined in the tRNA database [1].
 DNA2RNA
 Use this button to convert the sequence from DNA to the complementary RNA counterpart. Modified residues are ignored.
 RNA2DNA
 Use this button to convert the sequence from RNA to the complementary DNA counterpart. Modified residues are ignored.
 Cleanup
 Allows the user to remove all characters from the sequence that are not A, C, G, T, or U.
 Clear Sequence
 Removes the sequence in the input window.
 back to menu
 Calculation

 Molecular mass
 This option calculates the mass for an entered sequence. Depending on the setting of the monoisotopic/average mass option, the corresponding mass values will be used. Check the selections of the 3' and 5' terminal ends and oligonucleotide type (DNA or RNA).
 Electrospray series
 Electrospray ionization generates multiple charge states of oligonucleotides. This calculation will give the m/z values for the sequence entered together with the sodium and potassium cation adducts, commonly present in oligonucleotide spectra.
 CID fragments
 When oligonucleotides fragment in a collision cell of a mass spectrometer, mainly 2 types of ions are generated (see [2]). The cleavage of a 3'C - 3'O bond yields a fragment with the 3' oligonucleotide end that contains a phosphate at the 5' end and is called the w ion. When a heterocyclic base is lost with the cleavage of the 3'C -3'O bond, the part containing the 5' end of the oligonucleotide is called the a-B ion. If the 'extended output' option is checked, additional fragment ion types will be calculated. For the complete nomenclature see ref. [1].
 Internal fragments
 These are fragments resulting from a double backbone cleavage. They have a phosphate at their 5' end and a furan at the 3' terminal. The calculations are limited to the maximum charge state of (+ or -) 5 or (+ or -) 1 for non-sorted and sorted output respectively.
 Base losses
 The intact oligonucleotide can loose a base anion (B-) or a neutral base (B+H). The anions are more likely to be lost from highly charged oligonucleotides due to electrostatic repulsion.
 RNase T1 digest
 Selection of this calulation will give all fragments obtained by T1 digestion of the oligonucleotide entered. RNase T1 is an endonuclease that cuts RNA at the 3' end of every G in the chain, resulting in a fragment ending on Gp or G>p depending on the reaction conditions. Both possibilities are calculated. The mass of the fragments is also calculated. In the output window of an enzymatic digest, clicking on a partial sequence will transfer the data to the input window, so that additional calculations for that partial sequence can be performed.
 RNase U2 digest
 RNase U2 is an endonuclease that cuts RNA mainly at the 3' end of an A in the chain. For this enzyme both the 3'p and 3'>p ends are calculated.
 RNase A digest
 RNase A is an endonuclease cutting at pyrimidines. Fragments are calculated having a C or U at the 3' end. For this enzyme also both the 3'p and 3'>p ends are calculated.
 5' and 3' exonuclease digest
 These enzymes attack the oligo from the 5' or 3' end and release one nucleotide at the time. The masses of the remaining oligonucleotide chain is calculated baginning with the starting sequence.
 Modified RNA list
 This item gives a list of all currently available modified nucleotides, their codes, the base masses and eventually the sugar modification value. Depending on the setting of the parameter 'average/monoisotopic mass', the corresponding masses will be shown. If the option 'sorted' is checked, the values are printed according to the base masses. Clicking on the one-character code of the modification will transfer you to the corresponding entry in the RNA modification database [3].
 The one-letter codes are taken from the tRNA database [1].
 Some calculations are restricted to oligonucleotides not exceeding a certain length in order to prevent memory overflow. See the table hereafter for the current specifications.
 calculation    maximum
 oligolength    mode    sorted    DNA/RNA
 molecular mass    unlimited    NA    NA    both
 electrospray series    200    + or -    NA    both
 CID fragments    25    + or -    by mass    both
 internal fragments    25    + or -    by mass    both
 base losses    200    + or -    by mass    both
 T1/U2 digests    unlimited    NA    by mass    RNA only
 5' and 3' exonucleases    200    NA    reverses order    both
 modified bases list    not checked    + or -    by base masses    both
 NA : not applicable

 back to menu
 Options

 average/monoisotopic mass
 The appropriate mass selection (average/monoisotopic) should be selected depending on the type of apparatus used or on the purpose of calculation. For more information see ref. []
 negative/positive mode
 Depending on the acquisition mode, positively or negatively charged ions should be considered. This can be set by this option. It does not affect the value of the molecular mass, which is allways the mass of the neutral species.
 DNA/RNA
 The choice of the oligonucleotide type: deoxyribonucleotide (DNA) of ribonucleotide (RNA) determines the sugar type that will be used in the calculations.
 allow undercut
 If this option is checked, also undercut pieces will be calculated for enzymatic digests.
 back to menu
 Terminals

 Select the desired terminal on the 5' end and on the 3' end. The most common occurences are provided. If other groups shoul be present at the terminal ends, use 'user defined residue "N"'.
 back to menu
 Memories

 Sequences can be temporarily stored in one of the 5 available memory locations. Use this feature before taking actions that could affect the sequence in the sequence window (e.g. cleanup, digest followed by CID calculation). Follow these steps:
 Select a memory location (1..5).
 Hit the copy button. The sequence (or the first part if the sequence is long) will appear in the selection window.
 Perform the desired actions.
 To restore a previously stored sequence, hit the paste button.
 Clear all will empty all memory locations.
 back to menu
 User residue 'N'

 A user defined residue, represented by the symbol 'N' in the sequence can be set up by entering the base anion mass and the sugar modification mass. The sugar modification mass represents the mass to be added to an unmodified sugar residue (e.g. for a 2'-O-Me sugar, average mass, type here the value 14.027, corresponding to an addition of CH2).
 This feature can also be used to define a modified terminal (by setting the appropriate sugar modification mass).
 back to menu
 Output

 Close button
 When the 'calculate' button is hit, a new window will be opened if not yet open. This output window will contain the results for the calculations. By default, a 'close' button is provided in order to enable the user easily to close the output window. If that button is not desired (e.g. for printing purposes), simply uncheck the 'close button' option.
 Output summary
 Checking this option will also output the sequence, the terminals, composition and other settings.
 Sequence by
 This options allows the sequence to be printed in sets of 3, 10 or 50 residues for readability.
 Extended output
 If this option is checked, some extra calculations will be included. See following table:
 Calculation    Extended output will add
 Molecular mass
 Electrospray series    sodium and potassium adducts
 CID fragments    y and d-H2O ions
 internal fragments
 base losses
 T1 and U2 digest    3' cyclic phosphates mass
 3' and 5' exonuclease digest
 Modified base list    Nucleoside, nucleotide and nucleotide cyclic phosphate mass

 Show messages
 Unchecking this option allows warnings and messages to be disabled.
 Sorted output
 Checking this options will sort the output. See also the table in the calculation section.
 back to menu
 References

 Sprinzl, M; Horn, C; Brown, M; Ioudovitch, A; Steinberg, S, Nucleic Acids Res. 1998 26, 148-153. the tRNA database
 McLuckey, SA; Van Berkel, GJ; Glish, GL, J. Am. Soc. Mass Spectrom. 1992, 3, 60-70.
 Rozenski, J; Crain, PF; McCloskey, JA, Nucleic Acids Res. 1999 27, 196-197. the RNA modification database
 back to menu

 for DNA:
 
 Sequence :
 GAT TAC A
 5'OH - DNA[7mer] - 3'OH
 C:1  T:2  A:3  G:1
 average mass, negative mode

 CID FRAGMENTS

     n   ch      a-B        w         y       d-H2O

     1   -1             330.217   250.237   328.202
     2   -1   426.307   619.402   539.422   641.412
         -2             309.197   269.207   320.202
     3   -1   739.517   932.612   852.632   945.609
         -2   369.254   465.802   425.812   472.300
         -3             310.198   283.538   314.531
     4   -1  1043.714  1236.809  1156.829  1249.806
         -2   521.353   617.900   577.910   624.399
         -3   347.232   411.597   384.937   415.930
         -4             308.446   288.451   311.695
     5   -1  1347.911  1541.006  1461.026  1563.016
         -2   673.451   769.999   730.009   781.004
         -3   448.631   512.996   486.336   520.333
         -4   336.221   384.495   364.500   389.998
         -5             307.394   291.398   311.796
     6   -1  1661.121  1854.216  1774.236  1852.201
         -2   830.056   926.604   886.614   925.596
         -3   553.035   617.400   590.740   616.728
         -4   414.524   462.798   442.803   462.294
         -5   331.417   370.036   354.040   369.633
         -6             308.196   294.866   307.860


 Sequence :
 GAT TAC A
 5'p - DNA[7mer] - 3'p  // phsphate terminal
 C:1  T:2  A:3  G:1
 average mass, negative mode

 CID FRAGMENTS

     n   ch      a-B        w         y       d-H2O

     1   -1             410.197   330.217   328.202
         -2             204.594   164.604   163.597
     2   -1   506.287   699.382   619.402   641.412
         -2   252.639   349.187   309.197   320.202
         -3             232.455   205.795   213.132
     3   -1   819.497  1012.592   932.612   945.609
         -2   409.244   505.792   465.802   472.300
         -3   272.493   336.858   310.198   314.531
         -4             252.392   232.397   235.646
     4   -1  1123.694  1316.789  1236.809  1249.806
         -2   561.343   657.890   617.900   624.399
         -3   373.892   438.257   411.597   415.930
         -4   280.167   328.441   308.446   311.695
         -5             262.551   246.555   249.154
     5   -1  1427.891  1620.986  1541.006  1563.016
         -2   713.441   809.989   769.999   781.004
         -3   475.291   539.656   512.996   520.333
         -4   356.216   404.490   384.495   389.998
         -5   284.771   323.390   307.394   311.796
         -6             269.324   255.994   259.662
     6   -1  1741.101  1934.196  1854.216  1852.201
         -2   870.046   966.594   926.604   925.596
         -3   579.695   644.060   617.400   616.728
         -4   434.519   482.793   462.798   462.294
         -5   347.413   386.032   370.036   369.633
         -6   289.343   321.526   308.196   307.860
         -7             275.449   264.024   263.736


 */
