<template>
  <div id="About">
    <div class="row justify-center">
      <div class="col-xs-0 col-lg-2"></div>
      <div class="col-12 col-lg-8 justify-center q-pr-md q-ma-auto">
        <div class="row">
          <div class="col-12 col-md-6 q-pl-md">
            <h4>Overview</h4>
            <p>
              Antimicrobial peptides (AMPs) are small peptides (operationally
              defined here as proteins with 10-100 amino acid residues). These
              small proteins are able to disturb microbial growth and can be
              produced by a wide range of organisms from all domains of life.
              These peptides are ancient defense molecules and some recently
              have shown activity against multi-resistant pathogens. Besides
              their potential to clinical applications, AMPs also are widely
              used in food preservation and agriculture.
            </p>
            <p>
              Because of their small size, AMPs cannot be detected with high
              confidence by standard gene prediction methods. Therefore, AMPs
              are often discarded (<a href="https://peerj.com/articles/10555/">Santos-Júnior <i>et al</i>; PeerJ
              2020</a>).
            </p>
            <p>
              Recently, <a href="https://big-data-biology.org/">we</a>
              developed <a
                href="https://big-data-biology.org/software/macrel/">Macrel</a>,
              which unlike other methods, was developed for metagenomes. Using
              Macrel, we started the Global Survey for AMPs, a project which
              intends to collect all AMP sequences available in the
              publicly-available databases to date.
              Thus, motivated to develop a database-assisted platform that
              provides comprehensive functional and physicochemical features of
              large-scale (meta)genomic-derived AMPs, we created AMPsphere!
            </p>
            <p>
              Just as the ecosphere is the worldwide sum of all ecosystems, the
              AMPsphere comprises the complexity of prokaryotic AMPs assembled
              in one dataset. To date, we analyzed the 86k high-quality genomes
              in <a href="https://progenomes.embl.de/">proGenomes2</a>, and
              over 63k metagenomes from <a
               href="https://www.ebi.ac.uk/ena/browser/">ENA</a>, <a
                href="https://ncbi.nlm.nih.gov/">NCBI</a> and
              <a href="https://genome.jgi.doe.gov/portal/">JGI</a>. After
              redundancy removal, we produced a collection of AMPs from the
              global microbiome, containing 863,498 distinct sequences,
              clustered into 10,715 AMP families with at
              least 7 sequences each.
            </p>
            <p>
              AMPSphere is deposited in Zenodo under <a
                href="https://doi.org/10.5281/zenodo.4574468">DOI:
              10.5281/zenodo.4574468</a>.
            </p>

          </div>
          <div class="col-12 col-md-6 q-pl-md ">
            <h4>Benefits and Features</h4>

            <div class="text-bold">Integration</div>
            <p>AMPSphere is available as a web resource that displays each AMP
              for browsing by family, location, and samples where it was
              found.</p>

            <div class="text-bold">Functional and physicochemical properties</div>
            <p>In the individual AMP cards, information such as pI, charge,
              molecular weight, hydrophobicity, the proportion of charged
              residues, and the probabilities associated with the predictions of
              its antimicrobial and hemolytic activities are available.</p>

            <div class="text-bold">AMPs from different species</div>
            <p>Collected AMPs can be mapped back to species, NCBI taxID accession
              codes, and also the accession of (meta)genomes. Besides that, AMP
              families also have pre-calculated phylogenetic trees, hidden Markov
              models (HMM), and alignments available.</p>

            <div class="text-bold">Tools</div>
            <p>AMPSphere has two tools for
              sequence searching by homology direct alignment and HMM profiles of
              families preloaded with our database.

            </p>

            <div class="text-bold">Getting more help</div>
            <p>Questions can be sent to the <a
                href="https://groups.google.com/g/ampsphere-users">mailing list</a>
              dedicated to the project. To enable local analyses, the complete
              database is available for download</p>

            <div class="text-bold">Downloads &amp; API</div>
            <p>Advanced users can <a href="/downloads">download all our data</a>
              or query it using <a href="/api">the API</a>.</p>

            <div class="text-bold">Acknowledgements</div>
            <p>This project is conducted in collaboration with the <a
                href="https://delafuentelab.seas.upenn.edu/">de la Fuente Lab
                at UPenn</a>, the <a
            href="https://www.embl.org/groups/bork/">Bork Group at EMBL</a> and
              the <a href="http://compgenomics.org/">Huerta-Cepas group at
                CPGB</a>.</p>

            <p>We would like to acknowledge in particular: M. D. Torres, T.S.B.
            Schmidt; A.N. Fullam; P. Bork; X. Zhao and J. Huerta-Cepas.</p>
          </div>
        </div>
      </div>
      <div class="col-xs-0 col-lg-2"></div>
        <div class="row justify-center">
            <div class="col-xs-0 col-lg-2"></div>
            <div class="col-12 col-lg-8 justify-center q-pr-md q-ma-auto">
                <div class="row justify-center q-ma-auto">
                    <h4 class="text-center">Quality tests</h4>
                    <p>
                        Several quality tests were applied to the small open
                        reading frames (smORFs) to evaluate them for quality.
                        While none are definite, they do select for higher
                        quality smORFs. Details can be found in (<a
                        href="https://doi.org/10.1101/2023.08.31.555663">Santos-Júnior
                        et al., 2023</a>), but we summarize them here:

                    </p>
                </div>
                <div class="row">
                    <div class="col-12 col-md-6 q-pl-md">
                        <div class="text-bold">Antifam</div>
                        <p>
                            <a href="https://www.ebi.ac.uk/research/bateman/software/antifam-tool-identify-spurious-proteins">AntiFam</a>
                            is a tool to detect spurious ORFs by matching them against a database of
                            (1) erroneous Pfam families built in the past from erroneous gene predictions;
                            (2) translations of commonly occurring non-coding RNAs such as tRNAs.
                        </p>
                        <p>
                            The antifams are recurrently used as a quality control step for protein sequence databases
                            of diverse origins, such as genomes and metagenomes. The details of Antifams are available
                            in Eberhardt et al. (2012). SmORFs from GMSC and AMPSphere were searched for
                            Antifams v.7.0 using HMMSearch (command: <code>hmmsearch --cut_ga AntiFam.hmm AMPSphere.fasta</code>).
                        </p>

                        <div class="text-bold">Terminal positioning in contigs</div>
                        <p>
                            Predicted smORFs used for the AMPSphere all contain both START and STOP codons.
                            Nonetheless, as START codons may be difficult to distinguish from other ATG codons,
                            we cannot guarantee that all smORFs are complete. However, if there is an inframe STOP
                            codon <em>upstream of the START codon</em>, the
                            smORF can be considered as a complete ORF.
                        </p>
                        <div class="text-bold">RNACode</div>
                        <p>
                        <a href="https://github.com/ViennaRNA/RNAcode">RNAcode</a> predicts protein coding regions
                        based on evolutionary signatures typical of protein genes. Some of the analyses
                        include the synonyomous/conservative nucleotide mutations, conservation of the
                        reading frame and absence of internal stop codons.
                        For more details, see <a
                        href="https://doi.org/10.1261/rna.2536111">Washietl et
                        al. (2011)</a>.
                        </p>
                        <p>
                        The RNACode analysis depends on a set of homologous and non-identical genes.
                        Therefore, it can only be applied to families of smORFs. In particular, we
                        applied RNACode to smORFs encoded by at least 8 gene variants.
                        </p>
                    </div>
                    <div class="col-12 col-md-6 q-pl-md">
                        <div class="text-bold">Presence in metatranscriptomes</div>
                        <p>
                        This test checks whether we can detect the smORF in a
                        set of 221 publicly available metatranscriptomes,
                        comprising human gut (142), peat (48), plant (13), and
                        symbiont (17) [<a
                        href="https://github.com/BigDataBiology/AMPSphereBackend/blob/main/data/qc/metaT_metadata.csv">full
                        list</a>]. </p>
                        <p>
                        Using <a
                        href="http://bio-bwa.sourceforge.net/">bwa</a>), the
                        short reads from the metatranscriptomes were mapped
                        against the smORF sequences. A smORF was considered to
                        be present in metatranscriptomics data when at least 1
                        read was mapped in a minimum of two samples (<a
                        href="https://ngless.embl.de/">NGLess</a> was used to
                        count the number of reads mapped to each smORF).
                        </p>

                        <div class="text-bold">Presence in metaproteomes</div>
                        <p>
                        Following a similar rationale as used to detect smORFs
                        in metatranscriptomes, we searched for smORFs in
                        metaproteomes data available in <a
                        href="https://www.ebi.ac.uk/pride/">PRIDE</a>. A total
                        of 109 publicly-available metaproteomes from 37
                        environments was used [<a
                        href="https://github.com/BigDataBiology/AMPSphereBackend/blob/main/data/qc/metaP_PRIDE_list.csv">full
                        list</a>].
                        </p>
                        <p>We used the test introduced by <a
                        href="https://doi.org/10.1038/s41587-022-01226-0">Ma et
                        al. (2022)</a> whereby a peptide is considered to be
                        present in a metaproteome if a kmer covering at least
                        half of the peptide sequence is found in the
                        metaproteome (exact matches only).
                        </p>
                        <div class="text-bold">References</div>
                        <ul>
                        <li>
                        <a href="https://doi.org/10.1093%2Fdatabase%2Fbas003">Eberhardt RY, Haft DH, Punta M, Martin M, O’Donovan C, Bateman A (2012) AntiFam: a tool to help identify spurious ORFs in protein annotation. Database 2012:Bas003</a>.
                        </li>
                        <li>
                        <a href="https://doi.org/10.1261/rna.2536111">Washietl S, Findeiss S, Müller SA, Kalkhof S, von Bergen M, Hofacker IL, Stadler PF, Goldman N (2011) RNAcode: robust discrimination of coding and noncoding regions in comparative sequence data. RNA  2011; 17(4):578-94</a>.
                        </li>
                        <li>
                        <a
                        href="https://doi.org/10.1038/s41587-022-01226-0">Ma,
                        Y., Guo, Z., Xia, B. et al. Identification of
                        antimicrobial peptides from the human gut microbiome
                        using deep learning. Nat Biotechnol 40, 921–931 (2022).
                        https://doi.org/10.1038/s41587-022-01226-0</a>.
                        </li>
                        <li>
                        <a href="https://doi.org/10.1101/2023.08.31.555663">Santos-Júnior CD, Torres MDC, Duan Y, del Río AR, Schmidt TBS, Chong H, Fullam A, Kuhn M, Zhu C, Houseman A, Somborski J, Vines A, Zhao XM, Bork P, Huerta-Cepas J, Fuente-Nunez C, Coelho LP bioRxiv 2023.08.31.555663; doi: https://doi.org/10.1101/2023.08.31.555663</a>.
                        </li>
                        </ul>
                    </div>
                </div>
            </div>
            <div class="col-xs-0 col-lg-2"></div>
        </div>
    </div>
  </div>
</template>

<script>
export default {
  name: "About",
}
</script>

<style scoped>

</style>
