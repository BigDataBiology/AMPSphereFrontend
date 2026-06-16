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
            [ Grid.col [ Col.md8, Col.attrs [ class "mx-auto" ] ]
                [ Html.h1 [ class "mb-4" ] [ Html.text "About AMPSphere" ]
                , aboutCard "What is AMPSphere?"
                    [ Html.p []
                        [ Html.text "AMPSphere is a comprehensive catalog of antimicrobial peptides (AMPs) predicted from metagenomes and microbial genomes. It provides a resource for the discovery and study of novel AMPs from diverse environments." ]
                    ]
                , aboutCard "Quality Assessment"
                    [ Html.p []
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
                , aboutCard "Families"
                    [ Html.p []
                        [ Html.text "AMPs are clustered into families (SPHERE clusters) based on sequence similarity. Each family has a consensus sequence, HMM profile, and associated metadata." ]
                    ]
                , aboutCard "Citation"
                    [ Html.p []
                        [ Html.text "Santos-Júnior, C.D., Torres, M.D.T., Duan, Y. "
                        , Html.em [] [ Html.text "et al." ]
                        , Html.text " Discovery of antimicrobial peptides in the global microbiome with machine learning. "
                        , Html.em [] [ Html.text "Cell" ]
                        , Html.text " 187, 3761–3778 (2024). "
                        , Html.a [ href "https://doi.org/10.1016/j.cell.2024.05.013" ]
                            [ Html.text "https://doi.org/10.1016/j.cell.2024.05.013" ]
                        ]
                    ]
                , aboutCard "Contact"
                    [ Html.p []
                        [ Html.text "AMPSphere is developed and maintained by the "
                        , Html.a [ href "https://big-data-biology.org" ]
                            [ Html.text "Big Data Biology Lab" ]
                        , Html.text " at the Centre for Microbiome Research, Queensland University of Technology, in collaboration with the "
                        , Html.a [ href "https://delafuentelab.seas.upenn.edu/" ]
                            [ Html.text "de la Fuente Lab" ]
                        , Html.text " at the University of Pennsylvania."
                        ]
                    , Html.p []
                        [ Html.text "For bug reports and feature requests, please open an issue on our "
                        , Html.a [ href "https://github.com/BigDataBiology/AMPSphere" ]
                            [ Html.text "GitHub repository" ]
                        , Html.text "."
                        ]
                    , Html.p [ class "mb-0" ]
                        [ Html.text "For general inquiries, contact "
                        , Html.a [ href "mailto:luis@luispedro.org" ]
                            [ Html.text "luis@luispedro.org" ]
                        , Html.text " or "
                        , Html.a [ href "mailto:cfuente@upenn.edu" ]
                            [ Html.text "cfuente@upenn.edu" ]
                        , Html.text "."
                        ]
                    ]
                ]
            ]
        ]
    }


aboutCard : String -> List (Html Msg) -> Html Msg
aboutCard title content =
    Card.config [ Card.attrs [ class "mb-3" ] ]
        |> Card.headerH5 [] [ Html.text title ]
        |> Card.block []
            [ Block.custom <| Html.div [] content ]
        |> Card.view
