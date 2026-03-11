module Pages.Home_ exposing (Model, Msg, page)

import Api
import Api.Statistics exposing (Statistics)
import Bootstrap.Alert as Alert
import Bootstrap.Button as Button
import Bootstrap.Card as Card
import Bootstrap.Card.Block as Block
import Bootstrap.Form as Form
import Bootstrap.Form.Radio as Radio
import Bootstrap.Form.Textarea as Textarea
import Bootstrap.Grid as Grid
import Bootstrap.Grid.Col as Col
import Bootstrap.Spinner as Spinner
import Bootstrap.Table as Table
import Bootstrap.Text
import Dict
import Effect exposing (Effect)
import Html exposing (Html)
import Html.Attributes exposing (class, href)
import Html.Events exposing (onClick, onSubmit, preventDefaultOn)
import Json.Decode as Decode
import Http
import Layouts
import Page exposing (Page)
import Route exposing (Route)
import Route.Path
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
    { statistics : Api.Data Statistics
    , sequenceQuery : String
    , searchMethod : SearchMethod
    }


type SearchMethod
    = MMseqs
    | HMMER


init : () -> ( Model, Effect Msg )
init _ =
    ( { statistics = Api.Loading
      , sequenceQuery = ""
      , searchMethod = MMseqs
      }
    , Api.Statistics.get { onResponse = GotStatistics }
    )



-- UPDATE


type Msg
    = GotStatistics (Result Http.Error Statistics)
    | SequenceQueryChanged String
    | SearchMethodChanged SearchMethod
    | SequenceSearchSubmitted
    | SetExampleQuery


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        GotStatistics (Ok stats) ->
            ( { model | statistics = Api.Success stats }
            , Effect.none
            )

        GotStatistics (Err err) ->
            ( { model | statistics = Api.Failure err }
            , Effect.none
            )

        SequenceQueryChanged query ->
            ( { model | sequenceQuery = query }
            , Effect.none
            )

        SearchMethodChanged method ->
            ( { model | searchMethod = method }
            , Effect.none
            )

        SetExampleQuery ->
            ( { model | sequenceQuery = ">Query1\nKRVKSFFKGYMRAIEINAALMYGYRPK\n>Query2\nGRVIGKQGRIAKAIRVVMRAAAVRVDEKVLVEID" }
            , Effect.none
            )

        SequenceSearchSubmitted ->
            let
                methodStr =
                    case model.searchMethod of
                        MMseqs ->
                            "mmseqs"

                        HMMER ->
                            "hmmer"
            in
            if String.trim model.sequenceQuery /= "" then
                ( model
                , Effect.pushRoute
                    { path = Route.Path.SequenceSearch
                    , query =
                        Dict.fromList
                            [ ( "method", methodStr )
                            , ( "query", String.trim model.sequenceQuery )
                            ]
                    , hash = Nothing
                    }
                )

            else
                ( model, Effect.none )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- VIEW


view : Model -> View Msg
view model =
    { title = "Home"
    , body =
        [ Html.div [ class "text-center py-5" ]
            [ Html.h1 [ class "display-4" ] [ Html.text "AMPSphere" ]
            , Html.p [ class "lead text-muted" ]
                [ Html.text "A comprehensive catalog of antimicrobial peptides from metagenomes and microbial genomes" ]
            ]
        , Grid.row []
            [ Grid.col [ Col.md6, Col.attrs [ class "mx-auto" ] ]
                [ viewStatistics model.statistics ]
            ]
        , Grid.row [ ]
            [ Grid.col [ Col.md8, Col.attrs [ class "mx-auto mt-4" ] ]
                [ viewSequenceSearch model ]
            ]
        ]
    }


viewStatistics : Api.Data Statistics -> Html Msg
viewStatistics data =
    Card.config [ Card.attrs [ class "mb-4" ] ]
        |> Card.headerH5 [] [ Html.text "Database Statistics" ]
        |> Card.block []
            [ Block.custom <|
                case data of
                    Api.NotAsked ->
                        Html.text ""

                    Api.Loading ->
                        Html.div [ class "text-center py-3" ]
                            [ Spinner.spinner [ Spinner.color spinnerColor ] []
                            , Html.p [ class "text-muted mt-2" ] [ Html.text "Loading statistics..." ]
                            ]

                    Api.Failure _ ->
                        Alert.simpleDanger [] [ Html.text "Failed to load statistics." ]

                    Api.Success stats ->
                        Table.table
                            { options = [ Table.hover ]
                            , thead = Table.thead [] []
                            , tbody =
                                Table.tbody []
                                    [ statRow "Antimicrobial peptides" (formatNumber stats.numAmps)
                                    , statRow "AMP families" (formatNumber stats.numFamilies)
                                    , statRow "Metagenomes / genomes" (formatNumber stats.numGenomes)
                                    , statRow "smORF genes" (formatNumber stats.numGenes)
                                    , statRow "Habitats" (formatNumber stats.numHabitats)
                                    , statRow "Metagenomes" (formatNumber stats.numMetagenomes)
                                    ]
                            }
            ]
        |> Card.view


statRow : String -> String -> Table.Row msg
statRow label val =
    Table.tr []
        [ Table.td [] [ Html.text label ]
        , Table.td [ Table.cellAttr (class "text-right font-weight-bold") ] [ Html.text val ]
        ]


viewSequenceSearch : Model -> Html Msg
viewSequenceSearch model =
    Card.config [ Card.attrs [ class "mb-4" ] ]
        |> Card.headerH5 [] [ Html.text "Sequence Search" ]
        |> Card.block []
            [ Block.custom <|
                Form.form [ onSubmit SequenceSearchSubmitted ]
                    [ Form.group []
                        [ Html.div [ class "mb-3" ]
                            (Radio.radioList "search-method"
                                [ Radio.create
                                    [ Radio.id "method-mmseqs"
                                    , Radio.inline
                                    , Radio.checked (model.searchMethod == MMseqs)
                                    , Radio.onClick (SearchMethodChanged MMseqs)
                                    ]
                                    "MMseqs2 (search AMPs)"
                                , Radio.create
                                    [ Radio.id "method-hmmer"
                                    , Radio.inline
                                    , Radio.checked (model.searchMethod == HMMER)
                                    , Radio.onClick (SearchMethodChanged HMMER)
                                    ]
                                    "HMMER (search families)"
                                ]
                            )
                        ]
                    , Form.group []
                        [ Textarea.textarea
                            [ Textarea.rows 6
                            , Textarea.value model.sequenceQuery
                            , Textarea.onInput SequenceQueryChanged
                            , Textarea.attrs [ Html.Attributes.placeholder "Enter amino acid sequence(s) in FASTA format..." ]
                            ]
                        , Html.small [ class "text-muted" ]
                            [ Html.text "or "
                            , Html.a
                                [ href "#"
                                , preventDefaultOn "click" (Decode.succeed ( SetExampleQuery, True ))
                                ]
                                [ Html.text "use example sequences" ]
                            ]
                        ]
                    , Button.button
                        [ Button.primary, Button.attrs [ Html.Attributes.type_ "submit" ] ]
                        [ Html.text "Search" ]
                    ]
            ]
        |> Card.view


spinnerColor : Bootstrap.Text.Color
spinnerColor =
    Bootstrap.Text.primary


formatNumber : Int -> String
formatNumber n =
    let
        reversed =
            List.reverse (String.toList (String.fromInt n))

        grouped =
            groupBy3 reversed []
    in
    String.join "," (List.map String.fromList (List.reverse (List.map List.reverse grouped)))


groupBy3 : List Char -> List (List Char) -> List (List Char)
groupBy3 chars acc =
    case chars of
        [] ->
            acc

        _ ->
            groupBy3 (List.drop 3 chars) (List.take 3 chars :: acc)
