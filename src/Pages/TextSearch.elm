module Pages.TextSearch exposing (Model, Msg, page)

import Api
import Api.SearchText exposing (SearchResult, SearchResults)
import Dict
import Effect exposing (Effect)
import Html exposing (Html)
import Html.Attributes exposing (class, href)
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


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- VIEW


view : Model -> View Msg
view model =
    { title = "Text Search"
    , body =
        [ Html.div [ class "page-text-search" ]
            [ Html.h1 []
                [ Html.text "Text Search"
                , case model.query of
                    "" ->
                        Html.text ""

                    q ->
                        Html.span [ class "search-query-label" ]
                            [ Html.text (" for \"" ++ q ++ "\"") ]
                ]
            , viewResults model
            ]
        ]
    }


viewResults : Model -> Html Msg
viewResults model =
    case model.results of
        Api.NotAsked ->
            Html.p [] [ Html.text "Enter a search query using the header search bar." ]

        Api.Loading ->
            Html.div [ class "loading" ] [ Html.text "Searching..." ]

        Api.Failure _ ->
            Html.div [ class "error" ] [ Html.text "Search failed. Please try again." ]

        Api.Success results ->
            if List.isEmpty results.results then
                Html.p [] [ Html.text "No results found." ]

            else
                Html.div []
                    [ Html.p [ class "result-count" ]
                        [ Html.text (String.fromInt results.totalCount ++ " results found") ]
                    , Html.table [ class "data-table" ]
                        [ Html.thead []
                            [ Html.tr []
                                [ Html.th [] [ Html.text "Accession" ]
                                , Html.th [] [ Html.text "Family" ]
                                , Html.th [] [ Html.text "Sequence" ]
                                , Html.th [] [ Html.text "Genes" ]
                                , Html.th [] [ Html.text "Quality" ]
                                ]
                            ]
                        , Html.tbody []
                            (List.map viewResultRow results.results)
                        ]
                    , viewPagination model results.totalCount
                    ]


viewResultRow : SearchResult -> Html Msg
viewResultRow result =
    Html.tr []
        [ Html.td []
            [ Html.a [ Route.Path.href (Route.Path.Amp_Accession_ { accession = result.accession }) ]
                [ Html.text result.accession ]
            ]
        , Html.td []
            [ Html.a [ Route.Path.href (Route.Path.Family_Accession_ { accession = result.family }) ]
                [ Html.text result.family ]
            ]
        , Html.td [ class "sequence-cell" ]
            [ Html.text (truncateSequence 30 result.sequence) ]
        , Html.td [] [ Html.text (String.fromInt result.numGenes) ]
        , Html.td [] [ Html.span [ class ("quality-badge quality-" ++ String.toLower result.quality) ] [ Html.text result.quality ] ]
        ]


truncateSequence : Int -> String -> String
truncateSequence maxLen seq =
    if String.length seq > maxLen then
        String.left maxLen seq ++ "..."

    else
        seq


viewPagination : Model -> Int -> Html Msg
viewPagination model totalCount =
    let
        totalPages =
            ceiling (toFloat totalCount / toFloat model.pageSize)

        pages =
            List.range 1 (min totalPages 10)
    in
    if totalPages <= 1 then
        Html.text ""

    else
        Html.div [ class "pagination" ]
            (List.map
                (\pg ->
                    Html.button
                        [ class
                            (if pg == model.currentPage then
                                "page-btn active"

                             else
                                "page-btn"
                            )
                        , onClick (GoToPage pg)
                        ]
                        [ Html.text (String.fromInt pg) ]
                )
                pages
            )
