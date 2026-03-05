module Pages.About exposing (Model, Msg, page)

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
        [ Html.div [ class "page-about" ]
            [ Html.h1 [] [ Html.text "About AMPSphere" ]
            , Html.section [ class "about-section" ]
                [ Html.h2 [] [ Html.text "What is AMPSphere?" ]
                , Html.p []
                    [ Html.text "AMPSphere is a comprehensive catalog of antimicrobial peptides (AMPs) predicted from metagenomes and microbial genomes. It provides a resource for the discovery and study of novel AMPs from diverse environments." ]
                ]
            , Html.section [ class "about-section" ]
                [ Html.h2 [] [ Html.text "Quality Assessment" ]
                , Html.p []
                    [ Html.text "AMPs in AMPSphere undergo quality assessment including:" ]
                , Html.ul []
                    [ Html.li [] [ Html.text "Coordinates check: verifying that the smORF is correctly identified in the genome" ]
                    , Html.li [] [ Html.text "RNAcode: statistical analysis of coding potential" ]
                    , Html.li [] [ Html.text "Antifam: screening against known non-AMP protein families" ]
                    , Html.li [] [ Html.text "Terminal placement: checking if the smORF is at a contig terminus" ]
                    ]
                , Html.p []
                    [ Html.text "Peptides passing all quality tests are marked as "
                    , Html.strong [] [ Html.text "high quality" ]
                    , Html.text ". Peptides with experimental evidence of antimicrobial activity are additionally marked."
                    ]
                ]
            , Html.section [ class "about-section" ]
                [ Html.h2 [] [ Html.text "Families" ]
                , Html.p []
                    [ Html.text "AMPs are clustered into families (SPHERE clusters) based on sequence similarity. Each family has a consensus sequence, HMM profile, and associated metadata." ]
                ]
            , Html.section [ class "about-section" ]
                [ Html.h2 [] [ Html.text "Citation" ]
                , Html.p []
                    [ Html.text "Santos-Junior, C.D., Pan, S., Zhao, XM. "
                    , Html.em [] [ Html.text "et al." ]
                    , Html.text " Discovery of antimicrobial peptides in the global microbiome with machine learning. "
                    , Html.em [] [ Html.text "Cell" ]
                    , Html.text " (2024). "
                    , Html.a [ href "https://doi.org/10.1016/j.cell.2024.05.013" ]
                        [ Html.text "https://doi.org/10.1016/j.cell.2024.05.013" ]
                    ]
                ]
            ]
        ]
    }
