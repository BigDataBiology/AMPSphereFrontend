module Pages.Downloads exposing (Model, Msg, page)

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
        , view = view shared
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


view : Shared.Model -> Model -> View Msg
view shared model =
    let
        baseUrl =
            shared.apiBaseUrl
    in
    { title = "Downloads"
    , body =
        [ Html.div [ class "page-downloads" ]
            [ Html.h1 [] [ Html.text "Downloads" ]
            , Html.p []
                [ Html.text "Download AMPSphere data for offline analysis. All files are freely available under a CC-BY 4.0 license." ]
            , Html.table [ class "data-table downloads-table" ]
                [ Html.thead []
                    [ Html.tr []
                        [ Html.th [] [ Html.text "File" ]
                        , Html.th [] [ Html.text "Description" ]
                        , Html.th [] [ Html.text "Format" ]
                        ]
                    ]
                , Html.tbody []
                    [ downloadRow baseUrl
                        "/downloads/AMPSphere_latest.sqlite"
                        "AMPSphere Database"
                        "Complete SQLite database with all AMP data"
                        "SQLite"
                    , downloadRow baseUrl
                        "/downloads/AMPSphere_latest.tsv"
                        "AMP Table"
                        "All AMPs with sequences, families, and quality flags"
                        "TSV"
                    , downloadRow baseUrl
                        "/downloads/AMPSphere_latest.faa"
                        "AMP Sequences"
                        "All AMP amino acid sequences"
                        "FASTA"
                    , downloadRow baseUrl
                        "/downloads/SPHERE_latest.tsv"
                        "Family Table"
                        "All families with consensus sequences and statistics"
                        "TSV"
                    , downloadRow baseUrl
                        "/downloads/AMPSphere_latest.mmseqsdb"
                        "MMseqs2 Database"
                        "Pre-built MMseqs2 database for sequence searching"
                        "MMseqs2 DB"
                    , downloadRow baseUrl
                        "/downloads/AMPSphere_latest.hmm"
                        "HMM Profiles"
                        "HMM profiles for all AMP families"
                        "HMM"
                    ]
                ]
            ]
        ]
    }


downloadRow : String -> String -> String -> String -> String -> Html msg
downloadRow baseUrl path name description format =
    Html.tr []
        [ Html.td []
            [ Html.a [ href (baseUrl ++ path) ]
                [ Html.text name ]
            ]
        , Html.td [] [ Html.text description ]
        , Html.td [] [ Html.text format ]
        ]
