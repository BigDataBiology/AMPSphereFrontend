module Pages.Home_ exposing (Model, Msg, page)

import Api
import Api.Statistics exposing (Statistics)
import Dict
import Effect exposing (Effect)
import Html exposing (Html)
import Html.Attributes exposing (class, cols, placeholder, rows, type_, value)
import Html.Events exposing (onClick, onInput, onSubmit)
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
        [ Html.div [ class "page-home" ]
            [ Html.section [ class "hero" ]
                [ Html.h1 [] [ Html.text "AMPSphere" ]
                , Html.p [ class "hero-subtitle" ]
                    [ Html.text "A comprehensive catalog of antimicrobial peptides from metagenomes and microbial genomes" ]
                ]
            , viewStatistics model.statistics
            , viewSequenceSearch model
            ]
        ]
    }


viewStatistics : Api.Data Statistics -> Html Msg
viewStatistics data =
    Html.section [ class "statistics-section" ]
        [ Html.h2 [] [ Html.text "Database Statistics" ]
        , case data of
            Api.NotAsked ->
                Html.text ""

            Api.Loading ->
                Html.div [ class "loading" ] [ Html.text "Loading statistics..." ]

            Api.Failure _ ->
                Html.div [ class "error" ] [ Html.text "Failed to load statistics." ]

            Api.Success stats ->
                Html.table [ class "data-table statistics-table" ]
                    [ Html.tbody []
                        [ statRow "Antimicrobial peptides" (formatNumber stats.numAmps)
                        , statRow "AMP families" (formatNumber stats.numFamilies)
                        , statRow "Metagenomes / genomes" (formatNumber stats.numGenomes)
                        , statRow "smORF genes" (formatNumber stats.numGenes)
                        , statRow "Habitats" (formatNumber stats.numHabitats)
                        , statRow "Metagenomes" (formatNumber stats.numMetagenomes)
                        ]
                    ]
        ]


statRow : String -> String -> Html msg
statRow label val =
    Html.tr []
        [ Html.td [ class "stat-label" ] [ Html.text label ]
        , Html.td [ class "stat-value" ] [ Html.text val ]
        ]


viewSequenceSearch : Model -> Html Msg
viewSequenceSearch model =
    Html.section [ class "search-section" ]
        [ Html.h2 [] [ Html.text "Sequence Search" ]
        , Html.form [ class "sequence-search-form", onSubmit SequenceSearchSubmitted ]
            [ Html.div [ class "search-method-toggle" ]
                [ Html.label [ class "method-option" ]
                    [ Html.input
                        [ type_ "radio"
                        , Html.Attributes.name "method"
                        , Html.Attributes.checked (model.searchMethod == MMseqs)
                        , onClick (SearchMethodChanged MMseqs)
                        ]
                        []
                    , Html.text " MMseqs2 (search AMPs)"
                    ]
                , Html.label [ class "method-option" ]
                    [ Html.input
                        [ type_ "radio"
                        , Html.Attributes.name "method"
                        , Html.Attributes.checked (model.searchMethod == HMMER)
                        , onClick (SearchMethodChanged HMMER)
                        ]
                        []
                    , Html.text " HMMER (search families)"
                    ]
                ]
            , Html.textarea
                [ class "sequence-input"
                , placeholder "Enter amino acid sequence(s) in FASTA format..."
                , rows 6
                , cols 60
                , value model.sequenceQuery
                , onInput SequenceQueryChanged
                ]
                []
            , Html.button [ type_ "submit", class "btn btn-primary" ]
                [ Html.text "Search" ]
            ]
        ]


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
