module Pages.TextSearch exposing (Model, Msg, page)

import Api
import Api.SearchText exposing (SearchResult, SearchResults)
import Bootstrap.Alert as Alert
import Bootstrap.Badge as Badge
import Bootstrap.Button as Button
import Bootstrap.Grid as Grid
import Bootstrap.Grid.Col as Col
import Bootstrap.Table as Table
import Bootstrap.Button as Button
import Components.Pagination as Pagination
import Dict
import Effect exposing (Effect)
import Html exposing (Html)
import Html.Attributes exposing (class)
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
        , update = update route
        , subscriptions = subscriptions
        , view = view
        }
        |> Page.withLayout (always <| Layouts.Default {})



-- MODEL


type alias Model =
    { query : String
    , currentPage : Int
    , pageSize : Int
    , results : Api.Data SearchResults
    }


init : Route () -> () -> ( Model, Effect Msg )
init route _ =
    let
        query =
            Dict.get "query" route.query |> Maybe.withDefault ""

        pg =
            Dict.get "page" route.query
                |> Maybe.andThen String.toInt
                |> Maybe.withDefault 1
    in
    ( { query = query
      , currentPage = pg
      , pageSize = 20
      , results =
            if query /= "" then
                Api.Loading

            else
                Api.NotAsked
      }
    , if query /= "" then
        Api.SearchText.get
            { query = query
            , page = pg
            , pageSize = 20
            , onResponse = GotResults
            }

      else
        Effect.none
    )



-- UPDATE


type Msg
    = GotResults (Result Http.Error SearchResults)
    | GoToPage Int
    | DownloadResults (List SearchResult)


update : Route () -> Msg -> Model -> ( Model, Effect Msg )
update route msg model =
    case msg of
        GotResults (Ok results) ->
            ( { model | results = Api.Success results }
            , Effect.none
            )

        GotResults (Err err) ->
            ( { model | results = Api.Failure err }
            , Effect.none
            )

        GoToPage pg ->
            ( { model | currentPage = pg, results = Api.Loading }
            , Effect.batch
                [ Effect.pushRoute
                    { path = Route.Path.TextSearch
                    , query =
                        Dict.fromList
                            [ ( "query", model.query )
                            , ( "page", String.fromInt pg )
                            ]
                    , hash = Nothing
                    }
                , Api.SearchText.get
                    { query = model.query
                    , page = pg
                    , pageSize = model.pageSize
                    , onResponse = GotResults
                    }
                ]
            )

        DownloadResults results ->
            ( model
            , Effect.sendCmd (Export.downloadTsv "ampsphere-text-search.tsv" (resultsTsv results))
            )


resultsTsv : List SearchResult -> String
resultsTsv results =
    Export.tsv
        [ "accession", "family", "sequence", "num_genes", "quality" ]
        (List.map
            (\r ->
                [ r.accession
                , r.family
                , r.sequence
                , String.fromInt r.numGenes
                , r.quality
                ]
            )
            results
        )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- VIEW


view : Model -> View Msg
view model =
    { title = "Text Search"
    , body =
        [ Grid.row []
            [ Grid.col [ Col.md10, Col.attrs [ class "mx-auto" ] ]
                [ Html.h1 [ class "mb-3" ]
                    [ Html.text "Text Search"
                    , case model.query of
                        "" ->
                            Html.text ""

                        q ->
                            Html.small [ class "text-muted ml-2" ]
                                [ Html.text (" for \"" ++ q ++ "\"") ]
                    ]
                , viewResults model
                ]
            ]
        ]
    }


viewResults : Model -> Html Msg
viewResults model =
    case model.results of
        Api.NotAsked ->
            Alert.simpleInfo [] [ Html.text "Enter a search query using the header search bar." ]

        Api.Loading ->
            UH.spinner "Searching..."

        Api.Failure _ ->
            UH.errorAlert "Search failed. Please try again."

        Api.Success results ->
            if List.isEmpty results.results then
                Alert.simpleWarning [] [ Html.text "No results found." ]

            else
                Html.div []
                    [ Html.div [ class "d-flex justify-content-between align-items-center mb-3" ]
                        [ Html.p [ class "text-muted mb-0" ]
                            [ Html.text (String.fromInt results.totalCount ++ " results found") ]
                        , Button.button
                            [ Button.outlineSecondary
                            , Button.small
                            , Button.attrs [ onClick (DownloadResults results.results) ]
                            ]
                            [ Html.text "Download page (TSV)" ]
                        ]
                    , Table.table
                        { options = [ Table.striped, Table.hover, Table.responsive ]
                        , thead =
                            Table.simpleThead
                                [ Table.th [] [ Html.text "Accession" ]
                                , Table.th [] [ Html.text "Family" ]
                                , Table.th [] [ Html.text "Sequence" ]
                                , Table.th [] [ Html.text "Genes" ]
                                , Table.th [] [ Html.text "Quality" ]
                                ]
                        , tbody =
                            Table.tbody []
                                (List.map viewResultRow results.results)
                        }
                    , viewPagination model results.totalCount
                    ]


viewResultRow : SearchResult -> Table.Row Msg
viewResultRow result =
    Table.tr []
        [ Table.td []
            [ Html.a [ Route.Path.href (Route.Path.Amp_Accession_ { accession = result.accession }) ]
                [ Html.text result.accession ]
            ]
        , Table.td []
            [ Html.a [ Route.Path.href (Route.Path.Family_Accession_ { accession = result.family }) ]
                [ Html.text result.family ]
            ]
        , Table.td [ Table.cellAttr (class "text-monospace small") ]
            [ Html.text (Format.truncate 30 result.sequence) ]
        , Table.td [] [ Html.text (String.fromInt result.numGenes) ]
        , Table.td [] [ qualityBadge result.quality ]
        ]


qualityBadge : String -> Html msg
qualityBadge quality =
    case String.toLower quality of
        "high" ->
            Badge.badgeSuccess [] [ Html.text quality ]

        "low" ->
            Badge.badgeWarning [] [ Html.text quality ]

        _ ->
            Badge.badgeSecondary [] [ Html.text quality ]


viewPagination : Model -> Int -> Html Msg
viewPagination model totalCount =
    let
        totalPages =
            ceiling (toFloat totalCount / toFloat model.pageSize)
    in
    -- The model/API use 1-indexed pages; the shared control is 0-indexed.
    Pagination.view
        { current = model.currentPage - 1
        , total = totalPages
        , toMsg = \pg -> GoToPage (pg + 1)
        }
