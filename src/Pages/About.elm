module Pages.About exposing (Model, Msg, page)

import Bootstrap.Card as Card
import Bootstrap.Card.Block as Block
import Bootstrap.Grid as Grid
import Bootstrap.Grid.Col as Col
import Effect exposing (Effect)
import Html exposing (Html)
import Html.Attributes exposing (class, href)
import Layouts
import Page exposing (Page)
import Route exposing (Route)
import Shared
import View exposing (View)


page : Shared.Model -> Route () -> Page Model Msg
page shared route =
    Page.new
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }
        |> Page.withLayout (always <| Layouts.Default {})



-- MODEL


type alias Model =
    {}


init : () -> ( Model, Effect Msg )
init _ =
    ( {}, Effect.none )



-- UPDATE


type Msg
    = NoOp


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    ( model, Effect.none )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- VIEW


view : Model -> View Msg
view model =
    { title = "About"
    , body =
        [ Grid.row []
            [ Grid.col [ Col.lg10, Col.attrs [ class "mx-auto" ] ]
                [ Html.h1 [ class "mb-4" ] [ Html.text "About AMPSphere" ]
                , overviewAndFeaturesCard
                , qualityTestsCard
                , privacyCard
                , citationCard
                , contactCard
                ]
            ]
        ]
    }



-- CARDS


overviewAndFeaturesCard : Html Msg
overviewAndFeaturesCard =
    aboutCard "Overview"
        [ Grid.row []
            [ Grid.col [ Col.md6 ] overviewColumn
            , Grid.col [ Col.md6 ] featuresColumn
            ]
        ]


overviewColumn : List (Html Msg)
overviewColumn =
    [ Html.p []
        [ Html.text "Antimicrobial peptides (AMPs) are small peptides (operationally defined here as proteins with 10–100 amino acid residues). These small proteins are able to disturb microbial growth and can be produced by a wide range of organisms from all domains of life. These peptides are ancient defense molecules and some recently have shown activity against multi-resistant pathogens. Besides their potential for clinical applications, AMPs are also widely used in food preservation and agriculture." ]
    , Html.p []
        [ Html.text "Because of their small size, AMPs cannot be detected with high confidence by standard gene prediction methods. Therefore, AMPs are often discarded ("
        , link "https://peerj.com/articles/10555/" "Santos-Júnior et al., PeerJ 2020"
        , Html.text ")."
        ]
    , Html.p []
        [ Html.text "To address this, we developed "
        , link "https://big-data-biology.org/software/macrel/" "Macrel"
        , Html.text " specifically to target AMP mining from metagenomes. Using Macrel, we started the Global Survey for AMPs, a project which intends to collect all AMP sequences available in publicly-available databases to date. Motivated to develop a database-assisted platform that provides comprehensive functional and physicochemical features of large-scale (meta)genomic-derived AMPs, we created AMPSphere!"
        ]
    , Html.p []
        [ Html.text "Just as the ecosphere is the worldwide sum of all ecosystems, AMPSphere comprises the complexity of prokaryotic AMPs assembled in one dataset. We analyzed the 86k high-quality genomes in "
        , link "https://progenomes.embl.de/" "proGenomes2"
        , Html.text " and over 63k metagenomes from "
        , link "https://www.ebi.ac.uk/ena/browser/" "ENA"
        , Html.text ", "
        , link "https://ncbi.nlm.nih.gov/" "NCBI"
        , Html.text " and "
        , link "https://genome.jgi.doe.gov/portal/" "JGI"
        , Html.text ". After redundancy removal, we produced a collection of AMPs from the global microbiome, containing 863,498 distinct sequences, clustered into 10,715 AMP families with at least 8 sequences each."
        ]
    , Html.p [ class "mb-0" ]
        [ Html.text "AMPSphere is deposited in Zenodo under "
        , link "https://doi.org/10.5281/zenodo.4574468" "DOI: 10.5281/zenodo.4574468"
        , Html.text "."
        ]
    ]


featuresColumn : List (Html Msg)
featuresColumn =
    [ Html.h5 [ class "mt-4 mt-md-0" ] [ Html.text "Benefits and Features" ]
    , feature "Integration"
        [ Html.text "AMPSphere is available as a web resource that displays each AMP for browsing by family, location, and the samples where it was found." ]
    , feature "Functional and physicochemical properties"
        [ Html.text "In the individual AMP cards, information such as pI, charge, molecular weight, hydrophobicity, the proportion of charged residues, and the probabilities associated with the predictions of antimicrobial and hemolytic activity are available." ]
    , feature "AMPs from different species"
        [ Html.text "Collected AMPs can be mapped back to species, NCBI taxID accession codes, and the accession of (meta)genomes. AMP families also have pre-calculated phylogenetic trees, hidden Markov models (HMM), and alignments available." ]
    , feature "Tools"
        [ Html.text "AMPSphere provides two "
        , link "/sequence-search" "sequence-search tools"
        , Html.text ": homology search by direct alignment, and HMM profiles of the families preloaded with our database."
        ]
    , feature "Getting more help"
        [ Html.text "Questions can be sent to the "
        , link "https://groups.google.com/g/ampsphere-users" "mailing list"
        , Html.text " dedicated to the project. To enable local analyses, the complete database is available for download."
        ]
    , feature "Downloads & API"
        [ Html.text "Advanced users can "
        , link "/downloads" "download all our data"
        , Html.text " or query it using "
        , link "/api" "the API"
        , Html.text "."
        ]
    , feature "Acknowledgements"
        [ Html.text "This project is conducted in collaboration with the "
        , link "https://delafuentelab.seas.upenn.edu/" "de la Fuente Lab at UPenn"
        , Html.text ", the "
        , link "https://www.embl.org/groups/bork/" "Bork Group at EMBL"
        , Html.text ", and the "
        , link "http://compgenomics.org/" "Huerta-Cepas group at CBGP"
        , Html.text ". We would like to acknowledge in particular: M. D. Torres, T. S. B. Schmidt, A. N. Fullam, P. Bork, X. Zhao, and J. Huerta-Cepas."
        ]
    ]


qualityTestsCard : Html Msg
qualityTestsCard =
    aboutCard "Quality Tests"
        [ Html.p []
            [ Html.text "Several quality tests were applied to the small open reading frames (smORFs) to evaluate their quality. While none is definitive, they do select for higher-quality smORFs. Peptides passing all of these tests are marked as "
            , Html.strong [] [ Html.text "high quality" ]
            , Html.text ". Details can be found in "
            , link "https://doi.org/10.1016/j.cell.2024.05.013" "Santos-Júnior et al., Cell 2024"
            , Html.text ", but we summarize them here:"
            ]
        , Grid.row []
            [ Grid.col [ Col.md6 ] qualityTestsLeft
            , Grid.col [ Col.md6 ] qualityTestsRight
            ]
        ]


qualityTestsLeft : List (Html Msg)
qualityTestsLeft =
    [ feature "Antifam"
        [ link "https://www.ebi.ac.uk/research/bateman/software/antifam-tool-identify-spurious-proteins" "AntiFam"
        , Html.text " is a tool to detect spurious ORFs by matching them against a database of (1) erroneous Pfam families built in the past from erroneous gene predictions and (2) translations of commonly occurring non-coding RNAs such as tRNAs. AntiFams are recurrently used as a quality-control step for protein sequence databases of diverse origins, such as genomes and metagenomes (Eberhardt et al., 2012). SmORFs from GMSC and AMPSphere were searched for AntiFams v.7.0 using HMMSearch (command: "
        , Html.code [] [ Html.text "hmmsearch --cut_ga AntiFam.hmm AMPSphere.fasta" ]
        , Html.text ")."
        ]
    , feature "Terminal positioning in contigs"
        [ Html.text "Predicted smORFs used for AMPSphere all contain both START and STOP codons. Nonetheless, as START codons may be difficult to distinguish from other ATG codons, we cannot guarantee that all smORFs are complete. However, if there is an in-frame STOP codon "
        , Html.em [] [ Html.text "upstream of the START codon" ]
        , Html.text ", the smORF can be considered a complete ORF."
        ]
    , feature "RNAcode"
        [ link "https://github.com/ViennaRNA/RNAcode" "RNAcode"
        , Html.text " predicts protein-coding regions based on evolutionary signatures typical of protein genes. Some of the analyses include synonymous/conservative nucleotide mutations, conservation of the reading frame, and absence of internal stop codons (see "
        , link "https://doi.org/10.1261/rna.2536111" "Washietl et al., 2011"
        , Html.text "). RNAcode depends on a set of homologous, non-identical genes, so it can only be applied to families of smORFs. In particular, we applied RNAcode to smORFs encoded by at least 8 gene variants."
        ]
    ]


qualityTestsRight : List (Html Msg)
qualityTestsRight =
    [ feature "Presence in metatranscriptomes"
        [ Html.text "This test checks whether we can detect the smORF in a set of 221 publicly available metatranscriptomes, comprising human gut (142), peat (48), plant (13), and symbiont (17) ["
        , link "https://github.com/BigDataBiology/AMPSphereBackend/blob/main/data/qc/metaT_metadata.csv" "full list"
        , Html.text "]. Using "
        , link "http://bio-bwa.sourceforge.net/" "bwa"
        , Html.text ", the short reads from the metatranscriptomes were mapped against the smORF sequences. A smORF was considered present when at least one read was mapped in a minimum of two samples ("
        , link "https://ngless.embl.de/" "NGLess"
        , Html.text " was used to count the reads mapped to each smORF)."
        ]
    , feature "Presence in metaproteomes"
        [ Html.text "Following a rationale similar to the metatranscriptome test, we searched for smORFs in metaproteome data available in "
        , link "https://www.ebi.ac.uk/pride/" "PRIDE"
        , Html.text ". A total of 109 publicly available metaproteomes from 37 environments was used ["
        , link "https://github.com/BigDataBiology/AMPSphereBackend/blob/main/data/qc/metaP_PRIDE_list.csv" "full list"
        , Html.text "]. We used the test introduced by "
        , link "https://doi.org/10.1038/s41587-022-01226-0" "Ma et al., 2022"
        , Html.text ", whereby a peptide is considered present in a metaproteome if a k-mer covering at least half of the peptide sequence is found in the metaproteome (exact matches only)."
        ]
    , Html.h6 [ class "font-weight-bold mt-3" ] [ Html.text "References" ]
    , Html.ul []
        [ Html.li []
            [ link "https://doi.org/10.1093%2Fdatabase%2Fbas003" "Eberhardt RY, Haft DH, Punta M, Martin M, O'Donovan C, Bateman A (2012) AntiFam: a tool to help identify spurious ORFs in protein annotation. Database 2012:bas003." ]
        , Html.li []
            [ link "https://doi.org/10.1261/rna.2536111" "Washietl S, Findeiss S, Müller SA, Kalkhof S, von Bergen M, Hofacker IL, Stadler PF, Goldman N (2011) RNAcode: robust discrimination of coding and noncoding regions in comparative sequence data. RNA 17(4):578–594." ]
        , Html.li []
            [ link "https://doi.org/10.1038/s41587-022-01226-0" "Ma Y, Guo Z, Xia B, et al. (2022) Identification of antimicrobial peptides from the human gut microbiome using deep learning. Nat Biotechnol 40:921–931." ]
        , Html.li []
            [ link "https://doi.org/10.1016/j.cell.2024.05.013" "Santos-Júnior CD, Torres MDT, Duan Y, et al. (2024) Discovery of antimicrobial peptides in the global microbiome with machine learning. Cell 187:3761–3778." ]
        ]
    ]


privacyCard : Html Msg
privacyCard =
    aboutCard "Privacy"
        [ Html.p []
            [ Html.text "This website uses Google Analytics to collect anonymous, aggregated usage statistics (such as which pages are visited) that help us understand how AMPSphere is used and improve it. No personally identifying information is collected for our own purposes." ]
        , Html.p []
            [ Html.text "Searches submitted through the "
            , link "/sequence-search" "sequence-search tools"
            , Html.text " and the text search are processed on a cloud server hosted in Australia, which means the sequences and queries you enter are transmitted to and processed on that server."
            ]
        , Html.p [ class "mb-0" ]
            [ Html.text "If you would rather not send your sequences to our server, you can "
            , link "/downloads" "download the complete database"
            , Html.text " and perform all searches locally on your own machine."
            ]
        ]


citationCard : Html Msg
citationCard =
    aboutCard "Citation"
        [ Html.p [ class "mb-0" ]
            [ Html.text "Santos-Júnior, C.D., Torres, M.D.T., Duan, Y. "
            , Html.em [] [ Html.text "et al." ]
            , Html.text " Discovery of antimicrobial peptides in the global microbiome with machine learning. "
            , Html.em [] [ Html.text "Cell" ]
            , Html.text " 187, 3761–3778 (2024). "
            , link "https://doi.org/10.1016/j.cell.2024.05.013" "https://doi.org/10.1016/j.cell.2024.05.013"
            ]
        ]


contactCard : Html Msg
contactCard =
    aboutCard "Contact"
        [ Html.p []
            [ Html.text "AMPSphere is developed and maintained by the "
            , link "https://big-data-biology.org" "Big Data Biology Lab"
            , Html.text ", in collaboration with the "
            , link "https://delafuentelab.seas.upenn.edu/" "de la Fuente Lab"
            , Html.text " at the University of Pennsylvania."
            ]
        , Html.p []
            [ Html.text "For bug reports and feature requests, please open an issue on our "
            , link "https://github.com/BigDataBiology/AMPSphere" "GitHub repository"
            , Html.text ", or reach out via the "
            , link "https://groups.google.com/g/ampsphere-users" "users mailing list"
            , Html.text "."
            ]
        , Html.p [ class "mb-0" ]
            [ Html.text "For general inquiries, contact "
            , link "mailto:luis@luispedro.org" "luis@luispedro.org"
            , Html.text " or "
            , link "mailto:cfuente@upenn.edu" "cfuente@upenn.edu"
            , Html.text "."
            ]
        ]



-- HELPERS


aboutCard : String -> List (Html Msg) -> Html Msg
aboutCard title content =
    Card.config [ Card.attrs [ class "mb-3" ] ]
        |> Card.headerH5 [] [ Html.text title ]
        |> Card.block []
            [ Block.custom <| Html.div [] content ]
        |> Card.view


feature : String -> List (Html Msg) -> Html Msg
feature title content =
    Html.div []
        [ Html.h6 [ class "font-weight-bold mt-3" ] [ Html.text title ]
        , Html.p [] content
        ]


link : String -> String -> Html Msg
link url label =
    Html.a [ href url ] [ Html.text label ]
