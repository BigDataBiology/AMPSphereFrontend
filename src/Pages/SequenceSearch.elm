module Pages.SequenceSearch exposing (Model, Msg, page)

import Api
import Api.SearchHmmer
import Api.SearchMmseqs
import Bootstrap.Alert as Alert
import Bootstrap.Button as Button
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
import Util.Export as Export
import Util.Format as Format
import Util.Html as UH
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
    | DownloadMmseqs (List Api.SearchMmseqs.Hit)
    | DownloadHmmer (List Api.SearchHmmer.Hit)


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

        DownloadMmseqs hits ->
            ( model
            , Effect.sendCmd (Export.downloadTsv "ampsphere-mmseqs-results.tsv" (mmseqsTsv hits))
            )

        DownloadHmmer hits ->
            ( model
            , Effect.sendCmd (Export.downloadTsv "ampsphere-hmmer-results.tsv" (hmmerTsv hits))
            )


mmseqsTsv : List Api.SearchMmseqs.Hit -> String
mmseqsTsv hits =
    Export.tsv
        [ "query", "target", "seq_identity", "aln_length", "mismatches", "gap_openings", "query_start", "query_end", "target_start", "target_end", "e_value", "bit_score", "query_aligned", "target_aligned", "match_pattern" ]
        (List.map
            (\h ->
                [ h.queryId
                , h.targetId
                , String.fromFloat h.seqIdentity
                , String.fromInt h.alnLength
                , String.fromInt h.numMismatches
                , String.fromInt h.numGapOpenings
                , String.fromInt h.queryStart
                , String.fromInt h.queryEnd
                , String.fromInt h.targetStart
                , String.fromInt h.targetEnd
                , String.fromFloat h.eValue
                , String.fromFloat h.bitScore
                , h.queryAligned
                , h.targetAligned
                , h.matchPattern
                ]
            )
            hits
        )


hmmerTsv : List Api.SearchHmmer.Hit -> String
hmmerTsv hits =
    Export.tsv
        [ "family", "accession", "e_value", "score", "bias", "description" ]
        (List.map
            (\h ->
                [ h.targetName
                , h.accession
                , String.fromFloat h.eValue
                , String.fromFloat h.score
                , String.fromFloat h.bias
                , h.description
                ]
            )
            hits
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
            UH.spinner "Running MMseqs2 search... This may take a moment."

        Api.Failure _ ->
            UH.errorAlert "Search failed. Please check your sequence and try again."

        Api.Success hits ->
            if List.isEmpty hits then
                Alert.simpleWarning [] [ Html.text "No hits found." ]

            else
                Html.div []
                    [ viewResultsHeader (List.length hits) (DownloadMmseqs hits)
                    , Table.table
                        { options = [ Table.striped, Table.hover, Table.responsive ]
                        , thead =
                            Table.simpleThead
                                [ Table.th [] [ Html.text "Query" ]
                                , Table.th [] [ Html.text "" ]
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
                [ Table.td [] [ Html.text hit.queryId ]
                , Table.td []
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
                , Table.td [] [ Html.text (Format.percent hit.seqIdentity) ]
                , Table.td [] [ Html.text (String.fromInt hit.alnLength) ]
                , Table.td [] [ Html.text (Format.eValue hit.eValue) ]
                , Table.td [] [ Html.text (String.fromFloat hit.bitScore) ]
                ]

        alignmentRow =
            if isExpanded then
                [ Table.tr []
                    [ Table.td [ Table.cellAttr (colspan 7) ]
                        [ Html.div [ class "p-3 bg-light" ]
                            [ Html.div []
                                [ Html.strong [] [ Html.text "Query:  " ]
                                , Html.code [] (coloredAlignment hit.queryAligned hit.matchPattern)
                                ]
                            , Html.div []
                                [ Html.strong [] [ Html.text "Target: " ]
                                , Html.code [] (coloredAlignment hit.targetAligned hit.matchPattern)
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
            UH.spinner "Running HMMER search... This may take a moment."

        Api.Failure _ ->
            UH.errorAlert "Search failed. Please check your sequence and try again."

        Api.Success hits ->
            if List.isEmpty hits then
                Alert.simpleWarning [] [ Html.text "No hits found." ]

            else
                Html.div []
                    [ viewResultsHeader (List.length hits) (DownloadHmmer hits)
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
        , Table.td [] [ Html.text (Format.eValue hit.eValue) ]
        , Table.td [] [ Html.text (String.fromFloat hit.score) ]
        , Table.td [] [ Html.text (String.fromFloat hit.bias) ]
        , Table.td [] [ Html.text hit.description ]
        ]


viewResultsHeader : Int -> Msg -> Html Msg
viewResultsHeader count downloadMsg =
    Html.div [ class "d-flex justify-content-between align-items-center mb-3" ]
        [ Html.p [ class "text-muted mb-0" ]
            [ Html.text (String.fromInt count ++ " hits found") ]
        , Button.button
            [ Button.outlineSecondary
            , Button.small
            , Button.attrs [ onClick downloadMsg ]
            ]
            [ Html.text "Download TSV" ]
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
