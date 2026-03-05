module Pages.SequenceSearch exposing (Model, Msg, page)

import Api
import Api.SearchHmmer
import Api.SearchMmseqs
import Dict
import Effect exposing (Effect)
import Html exposing (Html)
import Html.Attributes exposing (class, colspan, href)
import Html.Events exposing (onClick)
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
        { init = init route
        , update = update
        , subscriptions = subscriptions
        , view = view
        }
        |> Page.withLayout (always <| Layouts.Default {})



-- MODEL


type SearchMethod
    = MMseqs
    | HMMER


type alias Model =
    { method : SearchMethod
    , query : String
    , mmseqsResults : Api.Data Api.SearchMmseqs.SearchResults
    , hmmerResults : Api.Data Api.SearchHmmer.SearchResults
    , expandedRows : List Int
    }


init : Route () -> () -> ( Model, Effect Msg )
init route _ =
    let
        methodStr =
            Dict.get "method" route.query |> Maybe.withDefault "mmseqs"

        method =
            if methodStr == "hmmer" then
                HMMER

            else
                MMseqs

        query =
            Dict.get "query" route.query |> Maybe.withDefault ""
    in
    ( { method = method
      , query = query
      , mmseqsResults =
            if method == MMseqs && query /= "" then
                Api.Loading

            else
                Api.NotAsked
      , hmmerResults =
            if method == HMMER && query /= "" then
                Api.Loading

            else
                Api.NotAsked
      , expandedRows = []
      }
    , if query /= "" then
        case method of
            MMseqs ->
                Api.SearchMmseqs.get
                    { query = query
                    , onResponse = GotMmseqsResults
                    }

            HMMER ->
                Api.SearchHmmer.get
                    { query = query
                    , onResponse = GotHmmerResults
                    }

      else
        Effect.none
    )



-- UPDATE


type Msg
    = GotMmseqsResults (Result Http.Error Api.SearchMmseqs.SearchResults)
    | GotHmmerResults (Result Http.Error Api.SearchHmmer.SearchResults)
    | ToggleRow Int


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        GotMmseqsResults (Ok results) ->
            ( { model | mmseqsResults = Api.Success results }
            , Effect.none
            )

        GotMmseqsResults (Err err) ->
            ( { model | mmseqsResults = Api.Failure err }
            , Effect.none
            )

        GotHmmerResults (Ok results) ->
            ( { model | hmmerResults = Api.Success results }
            , Effect.none
            )

        GotHmmerResults (Err err) ->
            ( { model | hmmerResults = Api.Failure err }
            , Effect.none
            )

        ToggleRow idx ->
            let
                expanded =
                    if List.member idx model.expandedRows then
                        List.filter (\i -> i /= idx) model.expandedRows

                    else
                        idx :: model.expandedRows
            in
            ( { model | expandedRows = expanded }
            , Effect.none
            )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- VIEW


view : Model -> View Msg
view model =
    { title = "Sequence Search"
    , body =
        [ Html.div [ class "page-sequence-search" ]
            [ Html.h1 []
                [ Html.text
                    (case model.method of
                        MMseqs ->
                            "MMseqs2 Search Results"

                        HMMER ->
                            "HMMER Search Results"
                    )
                ]
            , case model.method of
                MMseqs ->
                    viewMmseqsResults model

                HMMER ->
                    viewHmmerResults model
            ]
        ]
    }


viewMmseqsResults : Model -> Html Msg
viewMmseqsResults model =
    case model.mmseqsResults of
        Api.NotAsked ->
            Html.p [] [ Html.text "No search query provided." ]

        Api.Loading ->
            Html.div [ class "loading" ] [ Html.text "Running MMseqs2 search... This may take a moment." ]

        Api.Failure _ ->
            Html.div [ class "error" ] [ Html.text "Search failed. Please check your sequence and try again." ]

        Api.Success hits ->
            if List.isEmpty hits then
                Html.p [] [ Html.text "No hits found." ]

            else
                Html.div []
                    [ Html.p [ class "result-count" ]
                        [ Html.text (String.fromInt (List.length hits) ++ " hits found") ]
                    , Html.table [ class "data-table" ]
                        [ Html.thead []
                            [ Html.tr []
                                [ Html.th [] [ Html.text "" ]
                                , Html.th [] [ Html.text "Target" ]
                                , Html.th [] [ Html.text "Identity" ]
                                , Html.th [] [ Html.text "Aln. Length" ]
                                , Html.th [] [ Html.text "E-value" ]
                                , Html.th [] [ Html.text "Bit Score" ]
                                ]
                            ]
                        , Html.tbody []
                            (List.indexedMap (viewMmseqsRow model.expandedRows) hits)
                        ]
                    ]


viewMmseqsRow : List Int -> Int -> Api.SearchMmseqs.Hit -> Html Msg
viewMmseqsRow expandedRows idx hit =
    let
        isExpanded =
            List.member idx expandedRows

        mainRow =
            Html.tr [ class "clickable-row", onClick (ToggleRow idx) ]
                [ Html.td [ class "expand-toggle" ]
                    [ Html.text
                        (if isExpanded then
                            "-"

                         else
                            "+"
                        )
                    ]
                , Html.td []
                    [ Html.a [ Route.Path.href (Route.Path.Amp_Accession_ { accession = hit.targetId }) ]
                        [ Html.text hit.targetId ]
                    ]
                , Html.td [] [ Html.text (formatPercent hit.seqIdentity) ]
                , Html.td [] [ Html.text (String.fromInt hit.alnLength) ]
                , Html.td [] [ Html.text (formatEValue hit.eValue) ]
                , Html.td [] [ Html.text (String.fromFloat hit.bitScore) ]
                ]

        alignmentRow =
            if isExpanded then
                [ Html.tr [ class "alignment-row" ]
                    [ Html.td [ colspan 6 ]
                        [ Html.div [ class "alignment" ]
                            [ Html.div [ class "alignment-line" ]
                                [ Html.span [ class "alignment-label" ] [ Html.text "Query:  " ]
                                , Html.code [] [ Html.text hit.querySequenceAligned ]
                                ]
                            , Html.div [ class "alignment-line" ]
                                [ Html.span [ class "alignment-label" ] [ Html.text "Target: " ]
                                , Html.code [] [ Html.text hit.targetSequenceAligned ]
                                ]
                            ]
                        ]
                    ]
                ]

            else
                []
    in
    Html.node "tbody" [] (mainRow :: alignmentRow)


viewHmmerResults : Model -> Html Msg
viewHmmerResults model =
    case model.hmmerResults of
        Api.NotAsked ->
            Html.p [] [ Html.text "No search query provided." ]

        Api.Loading ->
            Html.div [ class "loading" ] [ Html.text "Running HMMER search... This may take a moment." ]

        Api.Failure _ ->
            Html.div [ class "error" ] [ Html.text "Search failed. Please check your sequence and try again." ]

        Api.Success hits ->
            if List.isEmpty hits then
                Html.p [] [ Html.text "No hits found." ]

            else
                Html.div []
                    [ Html.p [ class "result-count" ]
                        [ Html.text (String.fromInt (List.length hits) ++ " hits found") ]
                    , Html.table [ class "data-table" ]
                        [ Html.thead []
                            [ Html.tr []
                                [ Html.th [] [ Html.text "Family" ]
                                , Html.th [] [ Html.text "Accession" ]
                                , Html.th [] [ Html.text "E-value" ]
                                , Html.th [] [ Html.text "Score" ]
                                , Html.th [] [ Html.text "Bias" ]
                                , Html.th [] [ Html.text "Description" ]
                                ]
                            ]
                        , Html.tbody []
                            (List.map viewHmmerRow hits)
                        ]
                    ]


viewHmmerRow : Api.SearchHmmer.Hit -> Html Msg
viewHmmerRow hit =
    Html.tr []
        [ Html.td []
            [ Html.a [ Route.Path.href (Route.Path.Family_Accession_ { accession = hit.targetName }) ]
                [ Html.text hit.targetName ]
            ]
        , Html.td [] [ Html.text hit.accession ]
        , Html.td [] [ Html.text (formatEValue hit.eValue) ]
        , Html.td [] [ Html.text (String.fromFloat hit.score) ]
        , Html.td [] [ Html.text (String.fromFloat hit.bias) ]
        , Html.td [] [ Html.text hit.description ]
        ]


formatPercent : Float -> String
formatPercent val =
    String.fromFloat (toFloat (round (val * 1000)) / 10) ++ "%"


formatEValue : Float -> String
formatEValue val =
    if val < 0.001 then
        let
            exp =
                logBase 10 val |> floor

            mantissa =
                val / (10 ^ toFloat exp)
        in
        String.fromFloat (toFloat (round (mantissa * 10)) / 10) ++ "e" ++ String.fromInt exp

    else
        String.fromFloat (toFloat (round (val * 1000)) / 1000)
