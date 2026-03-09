module Pages.TextSearch exposing (Model, Msg, page)

import Api
import Api.SearchText exposing (SearchResult, SearchResults)
import Bootstrap.Alert as Alert
import Bootstrap.Badge as Badge
import Bootstrap.Button as Button
import Bootstrap.Grid as Grid
import Bootstrap.Grid.Col as Col
import Bootstrap.Spinner as Spinner
import Bootstrap.Table as Table
import Dict
import Effect exposing (Effect)
import Html exposing (Html)
import Html.Attributes exposing (class, href)
import Html.Events exposing (onClick)
import Json.Decode
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
            Html.div [ class "text-center py-4" ]
                [ Spinner.spinner [ Spinner.grow ] []
                , Html.p [ class "text-muted mt-2" ] [ Html.text "Searching..." ]
                ]

        Api.Failure _ ->
            Alert.simpleDanger [] [ Html.text "Search failed. Please try again." ]

        Api.Success results ->
            if List.isEmpty results.results then
                Alert.simpleWarning [] [ Html.text "No results found." ]

            else
                Html.div []
                    [ Html.p [ class "text-muted mb-3" ]
                        [ Html.text (String.fromInt results.totalCount ++ " results found") ]
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
            [ Html.text (truncateSequence 30 result.sequence) ]
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


onClickPreventDefault : msg -> Html.Attribute msg
onClickPreventDefault msg =
    Html.Events.preventDefaultOn "click" (Json.Decode.succeed ( msg, True ))


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
        Html.nav [ class "mt-3" ]
            [ Html.ul [ class "pagination justify-content-center" ]
                (List.map
                    (\pg ->
                        Html.li
                            [ class
                                (if pg == model.currentPage then
                                    "page-item active"

                                 else
                                    "page-item"
                                )
                            ]
                            [ Html.a
                                [ class "page-link"
                                , href "#"
                                , onClickPreventDefault (GoToPage pg)
                                ]
                                [ Html.text (String.fromInt pg) ]
                            ]
                    )
                    pages
                )
            ]
