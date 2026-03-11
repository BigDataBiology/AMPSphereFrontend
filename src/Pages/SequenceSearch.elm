module Pages.SequenceSearch exposing (Model, Msg, page)

import Api
import Api.SearchHmmer
import Api.SearchMmseqs
import Bootstrap.Alert as Alert
import Bootstrap.Spinner as Spinner
import Bootstrap.Table as Table
import Dict
import Effect exposing (Effect)
import Html exposing (Html)
import Html.Attributes exposing (class, colspan, href, style)
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
        [ Html.h1 [ class "mb-3" ]
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
    }


viewMmseqsResults : Model -> Html Msg
viewMmseqsResults model =
    case model.mmseqsResults of
        Api.NotAsked ->
            Alert.simpleInfo [] [ Html.text "No search query provided." ]

        Api.Loading ->
            Html.div [ class "text-center py-4" ]
                [ Spinner.spinner [ Spinner.grow ] []
                , Html.p [ class "text-muted mt-2" ] [ Html.text "Running MMseqs2 search... This may take a moment." ]
                ]

        Api.Failure _ ->
            Alert.simpleDanger [] [ Html.text "Search failed. Please check your sequence and try again." ]

        Api.Success hits ->
            if List.isEmpty hits then
                Alert.simpleWarning [] [ Html.text "No hits found." ]

            else
                Html.div []
                    [ Html.p [ class "text-muted mb-3" ]
                        [ Html.text (String.fromInt (List.length hits) ++ " hits found") ]
                    , Table.table
                        { options = [ Table.striped, Table.hover, Table.responsive ]
                        , thead =
                            Table.simpleThead
                                [ Table.th [] [ Html.text "" ]
                                , Table.th [] [ Html.text "Target" ]
                                , Table.th [] [ Html.text "Identity" ]
                                , Table.th [] [ Html.text "Aln. Length" ]
                                , Table.th [] [ Html.text "E-value" ]
                                , Table.th [] [ Html.text "Bit Score" ]
                                ]
                        , tbody =
                            Table.tbody []
                                (List.concatMap identity (List.indexedMap (viewMmseqsRow model.expandedRows) hits))
                        }
                    ]


viewMmseqsRow : List Int -> Int -> Api.SearchMmseqs.Hit -> List (Table.Row Msg)
viewMmseqsRow expandedRows idx hit =
    let
        isExpanded =
            List.member idx expandedRows

        mainRow =
            Table.tr [ Table.rowAttr (class "cursor-pointer"), Table.rowAttr (onClick (ToggleRow idx)) ]
                [ Table.td []
                    [ Html.text
                        (if isExpanded then
                            "-"

                         else
                            "+"
                        )
                    ]
                , Table.td []
                    [ Html.a [ Route.Path.href (Route.Path.Amp_Accession_ { accession = hit.targetId }) ]
                        [ Html.text hit.targetId ]
                    ]
                , Table.td [] [ Html.text (formatPercent hit.seqIdentity) ]
                , Table.td [] [ Html.text (String.fromInt hit.alnLength) ]
                , Table.td [] [ Html.text (formatEValue hit.eValue) ]
                , Table.td [] [ Html.text (String.fromFloat hit.bitScore) ]
                ]

        alignmentRow =
            if isExpanded then
                [ Table.tr []
                    [ Table.td [ Table.cellAttr (colspan 6) ]
                        [ Html.div [ class "p-3 bg-light" ]
                            [ Html.div []
                                [ Html.strong [] [ Html.text "Query:  " ]
                                , Html.code [] (coloredAlignment hit.querySequenceAligned hit.matchPattern)
                                ]
                            , Html.div []
                                [ Html.strong [] [ Html.text "Target: " ]
                                , Html.code [] (coloredAlignment hit.targetSequenceAligned hit.matchPattern)
                                ]
                            ]
                        ]
                    ]
                ]

            else
                []
    in
    mainRow :: alignmentRow


viewHmmerResults : Model -> Html Msg
viewHmmerResults model =
    case model.hmmerResults of
        Api.NotAsked ->
            Alert.simpleInfo [] [ Html.text "No search query provided." ]

        Api.Loading ->
            Html.div [ class "text-center py-4" ]
                [ Spinner.spinner [ Spinner.grow ] []
                , Html.p [ class "text-muted mt-2" ] [ Html.text "Running HMMER search... This may take a moment." ]
                ]

        Api.Failure _ ->
            Alert.simpleDanger [] [ Html.text "Search failed. Please check your sequence and try again." ]

        Api.Success hits ->
            if List.isEmpty hits then
                Alert.simpleWarning [] [ Html.text "No hits found." ]

            else
                Html.div []
                    [ Html.p [ class "text-muted mb-3" ]
                        [ Html.text (String.fromInt (List.length hits) ++ " hits found") ]
                    , Table.table
                        { options = [ Table.striped, Table.hover, Table.responsive ]
                        , thead =
                            Table.simpleThead
                                [ Table.th [] [ Html.text "Family" ]
                                , Table.th [] [ Html.text "Accession" ]
                                , Table.th [] [ Html.text "E-value" ]
                                , Table.th [] [ Html.text "Score" ]
                                , Table.th [] [ Html.text "Bias" ]
                                , Table.th [] [ Html.text "Description" ]
                                ]
                        , tbody =
                            Table.tbody []
                                (List.map viewHmmerRow hits)
                        }
                    ]


viewHmmerRow : Api.SearchHmmer.Hit -> Table.Row Msg
viewHmmerRow hit =
    Table.tr []
        [ Table.td []
            [ Html.a [ Route.Path.href (Route.Path.Family_Accession_ { accession = hit.targetName }) ]
                [ Html.text hit.targetName ]
            ]
        , Table.td [] [ Html.text hit.accession ]
        , Table.td [] [ Html.text (formatEValue hit.eValue) ]
        , Table.td [] [ Html.text (String.fromFloat hit.score) ]
        , Table.td [] [ Html.text (String.fromFloat hit.bias) ]
        , Table.td [] [ Html.text hit.description ]
        ]


coloredAlignment : String -> String -> List (Html msg)
coloredAlignment sequence matchPattern =
    List.map2
        (\residue match ->
            let
                color =
                    case match of
                        '|' ->
                            "#2e7d32"

                        '.' ->
                            "#e65100"

                        _ ->
                            "#c62828"
            in
            Html.span [ style "color" color ] [ Html.text (String.fromChar residue) ]
        )
        (String.toList sequence)
        (String.toList matchPattern)


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
