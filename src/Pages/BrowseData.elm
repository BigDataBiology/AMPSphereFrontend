module Pages.BrowseData exposing (Model, Msg, page)

import Api
import Api.AmpList exposing (AmpListResponse, AmpSummary)
import Api.AvailableOptions exposing (AvailableOptions)
import Bootstrap.Alert as Alert
import Bootstrap.Button as Button
import Bootstrap.Card as Card
import Bootstrap.Card.Block as Block
import Bootstrap.Form as Form
import Bootstrap.Form.Input as Input
import Bootstrap.Form.Select as Select
import Bootstrap.Grid as Grid
import Bootstrap.Grid.Col as Col
import Bootstrap.Spinner as Spinner
import Bootstrap.Table as Table
import Dict
import Effect exposing (Effect)
import Html exposing (Html)
import Html.Attributes exposing (class, href, selected, value)
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
        , update = update
        , subscriptions = subscriptions
        , view = view
        }
        |> Page.withLayout (always <| Layouts.Default {})



-- MODEL


type alias Model =
    { currentPage : Int
    , pageSize : Int
    , options : Api.Data AvailableOptions
    , ampsList : Api.Data AmpListResponse
    , filterHabitat : Maybe String
    , filterMicrobialSource : Maybe String
    , filterQuality : Maybe String
    , filterFamily : String
    , filterPepLengthMin : String
    , filterPepLengthMax : String
    , filterMwMin : String
    , filterMwMax : String
    , filterPiMin : String
    , filterPiMax : String
    , filterChargeMin : String
    , filterChargeMax : String
    }


init : Route () -> () -> ( Model, Effect Msg )
init route _ =
    let
        pg =
            Dict.get "page" route.query
                |> Maybe.andThen String.toInt
                |> Maybe.withDefault 0

        habitat =
            Dict.get "habitat" route.query

        family =
            Dict.get "family" route.query |> Maybe.withDefault ""
    in
    ( { currentPage = pg
      , pageSize = 20
      , options = Api.Loading
      , ampsList = Api.Loading
      , filterHabitat = habitat
      , filterMicrobialSource = Nothing
      , filterQuality = Nothing
      , filterFamily = family
      , filterPepLengthMin = ""
      , filterPepLengthMax = ""
      , filterMwMin = ""
      , filterMwMax = ""
      , filterPiMin = ""
      , filterPiMax = ""
      , filterChargeMin = ""
      , filterChargeMax = ""
      }
    , Effect.batch
        [ Api.AvailableOptions.get { onResponse = GotOptions }
        , Api.AmpList.get
            { filters = buildFilters pg 20 habitat Nothing Nothing family "" "" "" "" "" "" "" ""
            , onResponse = GotAmpsList
            }
        ]
    )


buildFilters :
    Int
    -> Int
    -> Maybe String
    -> Maybe String
    -> Maybe String
    -> String
    -> String
    -> String
    -> String
    -> String
    -> String
    -> String
    -> String
    -> String
    -> Api.AmpList.Filters
buildFilters pg pageSize habitat microbialSource quality family plMin plMax mwMin mwMax piMin piMax chargeMin chargeMax =
    { page = pg
    , pageSize = pageSize
    , family =
        if family /= "" then
            Just family

        else
            Nothing
    , habitat = habitat
    , microbialSource = microbialSource
    , quality = quality
    , pepLengthMin = String.toInt plMin
    , pepLengthMax = String.toInt plMax
    , mwMin = String.toFloat mwMin
    , mwMax = String.toFloat mwMax
    , piMin = String.toFloat piMin
    , piMax = String.toFloat piMax
    , chargeMin = String.toFloat chargeMin
    , chargeMax = String.toFloat chargeMax
    }



-- UPDATE


type Msg
    = GotOptions (Result Http.Error AvailableOptions)
    | GotAmpsList (Result Http.Error AmpListResponse)
    | SetHabitat String
    | SetMicrobialSource String
    | SetQuality String
    | SetFamily String
    | SetPepLengthMin String
    | SetPepLengthMax String
    | SetMwMin String
    | SetMwMax String
    | SetPiMin String
    | SetPiMax String
    | SetChargeMin String
    | SetChargeMax String
    | ApplyFilters
    | GoToPage Int


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        GotOptions (Ok opts) ->
            ( { model | options = Api.Success opts }, Effect.none )

        GotOptions (Err err) ->
            ( { model | options = Api.Failure err }, Effect.none )

        GotAmpsList (Ok amps) ->
            ( { model | ampsList = Api.Success amps }, Effect.none )

        GotAmpsList (Err err) ->
            ( { model | ampsList = Api.Failure err }, Effect.none )

        SetHabitat val ->
            ( { model
                | filterHabitat =
                    if val == "" then
                        Nothing

                    else
                        Just val
              }
            , Effect.none
            )

        SetMicrobialSource val ->
            ( { model
                | filterMicrobialSource =
                    if val == "" then
                        Nothing

                    else
                        Just val
              }
            , Effect.none
            )

        SetQuality val ->
            ( { model
                | filterQuality =
                    if val == "" then
                        Nothing

                    else
                        Just val
              }
            , Effect.none
            )

        SetFamily val ->
            ( { model | filterFamily = val }, Effect.none )

        SetPepLengthMin val ->
            ( { model | filterPepLengthMin = val }, Effect.none )

        SetPepLengthMax val ->
            ( { model | filterPepLengthMax = val }, Effect.none )

        SetMwMin val ->
            ( { model | filterMwMin = val }, Effect.none )

        SetMwMax val ->
            ( { model | filterMwMax = val }, Effect.none )

        SetPiMin val ->
            ( { model | filterPiMin = val }, Effect.none )

        SetPiMax val ->
            ( { model | filterPiMax = val }, Effect.none )

        SetChargeMin val ->
            ( { model | filterChargeMin = val }, Effect.none )

        SetChargeMax val ->
            ( { model | filterChargeMax = val }, Effect.none )

        ApplyFilters ->
            ( { model | currentPage = 0, ampsList = Api.Loading }
            , fetchAmps model 0
            )

        GoToPage pg ->
            ( { model | currentPage = pg, ampsList = Api.Loading }
            , fetchAmps model pg
            )


fetchAmps : Model -> Int -> Effect Msg
fetchAmps model pg =
    Api.AmpList.get
        { filters =
            buildFilters pg
                model.pageSize
                model.filterHabitat
                model.filterMicrobialSource
                model.filterQuality
                model.filterFamily
                model.filterPepLengthMin
                model.filterPepLengthMax
                model.filterMwMin
                model.filterMwMax
                model.filterPiMin
                model.filterPiMax
                model.filterChargeMin
                model.filterChargeMax
        , onResponse = GotAmpsList
        }


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- VIEW


view : Model -> View Msg
view model =
    { title = "Browse Data"
    , body =
        [ Html.h1 [ class "mb-3" ] [ Html.text "Browse Data" ]
        , Grid.row []
            [ Grid.col [ Col.md3 ]
                [ viewSidebar model ]
            , Grid.col [ Col.md9 ]
                [ viewMainContent model ]
            ]
        ]
    }


viewSidebar : Model -> Html Msg
viewSidebar model =
    Card.config [ Card.attrs [ class "mb-3" ] ]
        |> Card.headerH5 [] [ Html.text "Filters" ]
        |> Card.block []
            [ Block.custom <|
                case model.options of
                    Api.Success opts ->
                        Html.div []
                            [ viewSelectFilter "Habitat" (List.map (\h -> ( h, h )) opts.habitat) SetHabitat (Maybe.withDefault "" model.filterHabitat)
                            , viewSelectFilter "Microbial Source" (List.take 50 (List.map (\m -> ( m, m )) opts.microbialSource)) SetMicrobialSource (Maybe.withDefault "" model.filterMicrobialSource)
                            , viewSelectFilter "Quality" (List.map (\q -> ( q, q )) opts.quality) SetQuality (Maybe.withDefault "" model.filterQuality)
                            , Form.group []
                                [ Form.label [] [ Html.text "Family" ]
                                , Input.text
                                    [ Input.placeholder "e.g. SPHERE-III.001_493"
                                    , Input.value model.filterFamily
                                    , Input.onInput SetFamily
                                    , Input.small
                                    ]
                                ]
                            , viewRangeFilter "Peptide Length" model.filterPepLengthMin model.filterPepLengthMax SetPepLengthMin SetPepLengthMax
                            , viewRangeFilter "Molecular Weight" model.filterMwMin model.filterMwMax SetMwMin SetMwMax
                            , viewRangeFilter "Isoelectric Point" model.filterPiMin model.filterPiMax SetPiMin SetPiMax
                            , viewRangeFilter "Charge at pH 7" model.filterChargeMin model.filterChargeMax SetChargeMin SetChargeMax
                            , Button.button
                                [ Button.primary, Button.block, Button.attrs [ onClick ApplyFilters ] ]
                                [ Html.text "Apply Filters" ]
                            ]

                    Api.Loading ->
                        Html.div [ class "text-center py-3" ]
                            [ Spinner.spinner [] []
                            , Html.p [ class "text-muted mt-2 small" ] [ Html.text "Loading filters..." ]
                            ]

                    Api.Failure _ ->
                        Alert.simpleDanger [] [ Html.text "Failed to load filter options." ]

                    Api.NotAsked ->
                        Html.text ""
            ]
        |> Card.view


viewSelectFilter : String -> List ( String, String ) -> (String -> Msg) -> String -> Html Msg
viewSelectFilter label options toMsg currentValue =
    Form.group []
        [ Form.label [] [ Html.text label ]
        , Select.select
            [ Select.small
            , Select.onChange toMsg
            ]
            (Select.item [ value "" ] [ Html.text ("All " ++ label ++ "s") ]
                :: List.map
                    (\( val, lbl ) ->
                        Select.item [ value val, selected (val == currentValue) ] [ Html.text lbl ]
                    )
                    options
            )
        ]


viewRangeFilter : String -> String -> String -> (String -> Msg) -> (String -> Msg) -> Html Msg
viewRangeFilter label minVal maxVal toMsgMin toMsgMax =
    Form.group []
        [ Form.label [] [ Html.text label ]
        , Grid.row []
            [ Grid.col [ Col.xs5 ]
                [ Input.number
                    [ Input.placeholder "Min"
                    , Input.value minVal
                    , Input.onInput toMsgMin
                    , Input.small
                    ]
                ]
            , Grid.col [ Col.xs2, Col.attrs [ class "text-center pt-1" ] ]
                [ Html.text "-" ]
            , Grid.col [ Col.xs5 ]
                [ Input.number
                    [ Input.placeholder "Max"
                    , Input.value maxVal
                    , Input.onInput toMsgMax
                    , Input.small
                    ]
                ]
            ]
        ]


viewMainContent : Model -> Html Msg
viewMainContent model =
    case model.ampsList of
        Api.Success response ->
            Html.div []
                [ Html.p [ class "text-muted mb-3" ]
                    [ Html.text (String.fromInt response.info.totalItem ++ " AMPs found") ]
                , Table.table
                    { options = [ Table.striped, Table.hover, Table.responsive, Table.small ]
                    , thead =
                        Table.simpleThead
                            [ Table.th [] [ Html.text "Accession" ]
                            , Table.th [] [ Html.text "Family" ]
                            , Table.th [] [ Html.text "Sequence" ]
                            , Table.th [] [ Html.text "Length" ]
                            , Table.th [] [ Html.text "MW" ]
                            , Table.th [] [ Html.text "pI" ]
                            , Table.th [] [ Html.text "Charge" ]
                            ]
                    , tbody =
                        Table.tbody []
                            (List.map viewAmpRow response.data)
                    }
                , viewPagination model response.info
                ]

        Api.Loading ->
            Html.div [ class "text-center py-4" ]
                [ Spinner.spinner [ Spinner.grow ] []
                , Html.p [ class "text-muted mt-2" ] [ Html.text "Loading data..." ]
                ]

        Api.Failure _ ->
            Alert.simpleDanger [] [ Html.text "Failed to load data." ]

        Api.NotAsked ->
            Html.text ""


viewAmpRow : AmpSummary -> Table.Row Msg
viewAmpRow amp =
    Table.tr []
        [ Table.td []
            [ Html.a [ Route.Path.href (Route.Path.Amp_Accession_ { accession = amp.accession }) ]
                [ Html.text amp.accession ]
            ]
        , Table.td []
            [ Html.a [ Route.Path.href (Route.Path.Family_Accession_ { accession = amp.family }) ]
                [ Html.text amp.family ]
            ]
        , Table.td [ Table.cellAttr (class "text-monospace small") ]
            [ Html.text
                (if String.length amp.sequence > 25 then
                    String.left 25 amp.sequence ++ "..."

                 else
                    amp.sequence
                )
            ]
        , Table.td [] [ Html.text (String.fromInt amp.length) ]
        , Table.td [] [ Html.text (formatFloat 1 amp.molecularWeight) ]
        , Table.td [] [ Html.text (formatFloat 2 amp.isoelectricPoint) ]
        , Table.td [] [ Html.text (formatFloat 2 amp.charge) ]
        ]


viewPagination : Model -> Api.AmpList.PageInfo -> Html Msg
viewPagination model info =
    let
        totalPages =
            info.totalPage

        currentPage =
            model.currentPage

        visiblePages =
            List.range (max 0 (currentPage - 3)) (min (totalPages - 1) (currentPage + 3))
    in
    if totalPages <= 1 then
        Html.text ""

    else
        Html.nav [ class "mt-3" ]
            [ Html.ul [ class "pagination justify-content-center" ]
                ([ if currentPage > 0 then
                    Html.li [ class "page-item" ]
                        [ Html.a [ class "page-link", href "#", onClick (GoToPage (currentPage - 1)) ]
                            [ Html.text "Prev" ]
                        ]

                   else
                    Html.li [ class "page-item disabled" ]
                        [ Html.span [ class "page-link" ] [ Html.text "Prev" ] ]
                 ]
                    ++ List.map
                        (\pg ->
                            Html.li
                                [ class
                                    (if pg == currentPage then
                                        "page-item active"

                                     else
                                        "page-item"
                                    )
                                ]
                                [ Html.a
                                    [ class "page-link"
                                    , href "#"
                                    , onClick (GoToPage pg)
                                    ]
                                    [ Html.text (String.fromInt (pg + 1)) ]
                                ]
                        )
                        visiblePages
                    ++ [ if currentPage < totalPages - 1 then
                            Html.li [ class "page-item" ]
                                [ Html.a [ class "page-link", href "#", onClick (GoToPage (currentPage + 1)) ]
                                    [ Html.text "Next" ]
                                ]

                         else
                            Html.li [ class "page-item disabled" ]
                                [ Html.span [ class "page-link" ] [ Html.text "Next" ] ]
                       ]
                )
            ]



-- HELPERS




formatFloat : Int -> Float -> String
formatFloat decimals val =
    let
        factor =
            toFloat (10 ^ decimals)

        rounded =
            toFloat (round (val * factor)) / factor
    in
    String.fromFloat rounded
