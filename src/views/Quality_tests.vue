<template>
    <div id="QualityTests">
        <div class="row justify-center">
            <div class="col-xs-0 col-lg-2"></div>
            <div class="col-12 col-lg-8 justify-center q-pr-md q-ma-auto">
                <div class="row justify-center q-ma-auto">
                    <h4 class="text-center">Quality tests</h4>
                    <p>
                        Several quality tests were applied in the small ORFs (smORFs) to check their quality.
                        These tests followed specific rationales to ensure that the observed peptides were not
                        simply artifacts or even fragments of larger proteins.
                    </p>
                </div>
                <div class="row">
                    <div class="col-12 col-md-6 q-pl-md">
                        <div class="text-bold">Antifam</div>
                        <p>
                            <a href="https://www.ebi.ac.uk/research/bateman/software/antifam-tool-identify-spurious-proteins">AntiFam</a>
                            is a tool to detect spurious ORFs. This resource consists in a set of profile-HMMs
                            designed from two sources:
                            (1) Erroneous Pfam families built in the past from erroneous gene predictions;
                            (2) Translations of commonly occurring non-coding RNAs such as tRNAs.
                        </p>
                        <p>
                            The antifams are recurrently used as a quality control step for protein sequence databases
                            of diverse origins, such as genomes and metagenomes. The details of Antifams are available
                            in Eberhardt et al. (2012). SmORFs from GMSC and AMPSphere were searched for
                            Antifams v.7.0 using HMMSearch (command: hmmsearch --cut_ga AntiFam.hmm &lt;GMSC/AMPSphere.fasta	&gt;).
                        </p>

                        <div class="text-bold">Terminal positioning in contigs</div>
                        <p>
                            Predicted smORFs may be part of larger genes due to the fragmentary assemblies,
                            even in the case they contain start and stop codons.
                            Therefore, we examined if smORFs are located in the 5' terminal of the contigs.
                        </p>
                        <p>
                            Using the coordinates files obtained from the gene prediction, we placed the smORFs
                            in the contigs and if there is a stop codon upstream the smORF, it was marked as a
                            true gene. The rationale is based in the previous large gene ending before the smORFs,
                            otherwise the smORF was marked as false.
                        </p>
                        <p>
                            If two or more smORFs are predicted on the same contig, we only checked the first
                            in-frame one. The smORFs downstream the first one will be consequently defined
                            as true.
                        </p>
                        <div class="text-bold">RNACode</div>
                        <p>
                        <a href="https://github.com/ViennaRNA/RNAcode">RNAcode</a> predicts protein coding regions
                        based on evolutionary signatures typical for protein genes. Some of the analysis
                        include the synonyomous/conservative nucleotide mutations, conservation of the
                        reading frame and absence of internal stop codons.
                        For more details read Washietl et al. (2011). 
                        </p>
                        <p>
                        The RNACode analysis depends on a set of homologous and non-identical genes.
                        To that, smORFs were hierarchically clustered by identity and then smORFs
                        encoded by at least 8 gene variants were submitted to RNACode.
                        </p>
                    </div>
                    <div class="col-12 col-md-6 q-pl-md">
                        <div class="text-bold">Presence in metatranscriptomes</div>
                        <p>
                        The main idea of this test relies on the fact that metatranscriptomes could detect
                        at low levels the transcription of smORFs. To that, a set of 221 publicly available
                        metatranscriptome sets was curated, comprising human gut (142), peat (48),
                        plant (13), symbiont (17).
                        </p>
                        <p>
                        Using bwa (http://bio-bwa.sourceforge.net/), the smORF genes were mapped against
                        the reads from the metatranscriptomes. The number of reads mapped per gene was
                        counter using ngless (https://ngless.embl.de/). In the case that at least 1 read
                        was mapped across a minimum of two samples, the smORF was marked as true.
                        </p>
                        <p>
                        To verify the set of metatranscriptomes used,
                        follow this <a href="https://github.com/BigDataBiology/AMPSphereBackend/blob/include_gtdb_and_new_QC_result/data/qc/metaT_metadata.csv">link</a> to the metadata.
                        </p>

                        <div class="text-bold">Presence in metaproteomes</div>
                        
                        <p>
                        Following a similar rationale, the detection of peptides previously obtained in 
                        metaproteomes data available in <a href="https://www.ebi.ac.uk/pride/">PRIDE</a>. The set of
                        metaproteomes was curated in a set of 109 publicly available metaproteomes from 
                        37 environments. To access the metadata related to this set, follow this 
                        <a href="https://github.com/BigDataBiology/AMPSphereBackend/blob/include_gtdb_and_new_QC_result/data/qc/metaP_PRIDE_list.csv">link</a>.
                        </p>
                        <p>
                        Using python3, we verified the exact string matching of peptides from 
                        GMSC/AMPSphere mapped against the peptides from the metaproteomes.
                        The number of mapped peptides against the set of samples was counted and 
                        those peptides with at least 1 match was marked as true.
                        </p>
                        <div class="text-bold">References</div>
                        <p>
                        Eberhardt RY, Haft DH, Punta M, Martin M, O’Donovan C, Bateman A (2012) AntiFam: a tool to help identify spurious ORFs in protein annotation. Database 2012:Bas003.
                        </p>
                        <p>
                        Washietl S, Findeiss S, Müller SA, Kalkhof S, von Bergen M, Hofacker IL, Stadler PF, Goldman N (2011) RNAcode: robust discrimination of coding and noncoding regions in comparative sequence data. RNA  2011; 17(4):578-94.
                        </p>
                    </div>
                </div>
            </div>
            <div class="col-xs-0 col-lg-2"></div>
        </div>
    </div>
</template>

<script>
export default {
  name: "QualityTests",
}
</script>