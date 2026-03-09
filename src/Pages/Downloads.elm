module Pages.Downloads exposing (Model, Msg, page)

import Bootstrap.Grid as Grid
import Bootstrap.Grid.Col as Col
import Bootstrap.Table as Table
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
        [ Grid.row []
            [ Grid.col [ Col.md10, Col.attrs [ class "mx-auto" ] ]
                [ Html.h1 [ class "mb-3" ] [ Html.text "Downloads" ]
                , Html.p [ class "text-muted mb-4" ]
                    [ Html.text "Download AMPSphere data for offline analysis. All files are freely available under a CC-BY 4.0 license." ]
                , Table.table
                    { options = [ Table.striped, Table.hover, Table.bordered ]
                    , thead =
                        Table.simpleThead
                            [ Table.th [] [ Html.text "File" ]
                            , Table.th [] [ Html.text "Description" ]
                            , Table.th [] [ Html.text "Format" ]
                            ]
                    , tbody =
                        Table.tbody []
                            [ downloadRow baseUrl "/downloads/AMPSphere_latest.sqlite" "AMPSphere Database" "Complete SQLite database with all AMP data" "SQLite"
                            , downloadRow baseUrl "/downloads/AMPSphere_latest.tsv" "AMP Table" "All AMPs with sequences, families, and quality flags" "TSV"
                            , downloadRow baseUrl "/downloads/AMPSphere_latest.faa" "AMP Sequences" "All AMP amino acid sequences" "FASTA"
                            , downloadRow baseUrl "/downloads/SPHERE_latest.tsv" "Family Table" "All families with consensus sequences and statistics" "TSV"
                            , downloadRow baseUrl "/downloads/AMPSphere_latest.mmseqsdb" "MMseqs2 Database" "Pre-built MMseqs2 database for sequence searching" "MMseqs2 DB"
                            , downloadRow baseUrl "/downloads/AMPSphere_latest.hmm" "HMM Profiles" "HMM profiles for all AMP families" "HMM"
                            ]
                    }
                ]
            ]
        ]
    }


downloadRow : String -> String -> String -> String -> String -> Table.Row msg
downloadRow baseUrl path name description format =
    Table.tr []
        [ Table.td []
            [ Html.a [ href (baseUrl ++ path) ] [ Html.text name ] ]
        , Table.td [] [ Html.text description ]
        , Table.td [] [ Html.text format ]
        ]
