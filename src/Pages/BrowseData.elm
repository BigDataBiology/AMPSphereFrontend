module Pages.BrowseData exposing (Model, Msg, page)

import Api
import Api.AmpList exposing (AmpListResponse, AmpSummary)
import Api.AvailableOptions exposing (AvailableOptions)
import Dict
import Effect exposing (Effect)
import Html exposing (Html)
import Html.Attributes exposing (class, href, placeholder, selected, type_, value)
import Html.Events exposing (onClick, onInput)
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
        [ Html.div [ class "page-browse-data" ]
            [ Html.h1 [] [ Html.text "Browse Data" ]
            , Html.div [ class "browse-layout" ]
                [ viewSidebar model
                , viewMainContent model
                ]
            ]
        ]
    }


viewSidebar : Model -> Html Msg
viewSidebar model =
    Html.aside [ class "filter-sidebar" ]
        [ Html.h2 [] [ Html.text "Filters" ]
        , case model.options of
            Api.Success opts ->
                Html.div [ class "filters" ]
                    [ viewSelect "Habitat" "" (List.map (\h -> ( h, h )) opts.habitat) SetHabitat (Maybe.withDefault "" model.filterHabitat)
                    , viewSelect "Microbial Source" "" (List.take 50 (List.map (\m -> ( m, m )) opts.microbialSource)) SetMicrobialSource (Maybe.withDefault "" model.filterMicrobialSource)
                    , viewSelect "Quality" "" (List.map (\q -> ( q, q )) opts.quality) SetQuality (Maybe.withDefault "" model.filterQuality)
                    , viewTextFilter "Family" "e.g. SPHERE-III.001_493" model.filterFamily SetFamily
                    , viewRangeFilter "Peptide Length" model.filterPepLengthMin model.filterPepLengthMax SetPepLengthMin SetPepLengthMax
                    , viewRangeFilter "Molecular Weight" model.filterMwMin model.filterMwMax SetMwMin SetMwMax
                    , viewRangeFilter "Isoelectric Point" model.filterPiMin model.filterPiMax SetPiMin SetPiMax
                    , viewRangeFilter "Charge at pH 7" model.filterChargeMin model.filterChargeMax SetChargeMin SetChargeMax
                    , Html.button [ class "btn btn-primary", onClick ApplyFilters ] [ Html.text "Apply Filters" ]
                    ]

            Api.Loading ->
                Html.div [ class "loading" ] [ Html.text "Loading filters..." ]

            Api.Failure _ ->
                Html.div [ class "error" ] [ Html.text "Failed to load filter options." ]

            Api.NotAsked ->
                Html.text ""
        ]


viewSelect : String -> String -> List ( String, String ) -> (String -> Msg) -> String -> Html Msg
viewSelect label defaultLabel options toMsg currentValue =
    Html.div [ class "filter-group" ]
        [ Html.label [] [ Html.text label ]
        , Html.select [ onInput toMsg ]
            (Html.option [ value "" ] [ Html.text ("All " ++ label ++ "s") ]
                :: List.map
                    (\( val, lbl ) ->
                        Html.option [ value val, selected (val == currentValue) ] [ Html.text lbl ]
                    )
                    options
            )
        ]


viewTextFilter : String -> String -> String -> (String -> Msg) -> Html Msg
viewTextFilter label placeholderText val toMsg =
    Html.div [ class "filter-group" ]
        [ Html.label [] [ Html.text label ]
        , Html.input [ type_ "text", placeholder placeholderText, value val, onInput toMsg ] []
        ]


viewRangeFilter : String -> String -> String -> (String -> Msg) -> (String -> Msg) -> Html Msg
viewRangeFilter label minVal maxVal toMsgMin toMsgMax =
    Html.div [ class "filter-group" ]
        [ Html.label [] [ Html.text label ]
        , Html.div [ class "range-inputs" ]
            [ Html.input [ type_ "number", placeholder "Min", value minVal, onInput toMsgMin ] []
            , Html.span [ class "range-separator" ] [ Html.text "-" ]
            , Html.input [ type_ "number", placeholder "Max", value maxVal, onInput toMsgMax ] []
            ]
        ]


viewMainContent : Model -> Html Msg
viewMainContent model =
    Html.div [ class "browse-main" ]
        [ case model.ampsList of
            Api.Success response ->
                Html.div []
                    [ Html.p [ class "result-count" ]
                        [ Html.text (String.fromInt response.info.totalItem ++ " AMPs found") ]
                    , Html.table [ class "data-table browse-table" ]
                        [ Html.thead []
                            [ Html.tr []
                                [ Html.th [] [ Html.text "Accession" ]
                                , Html.th [] [ Html.text "Family" ]
                                , Html.th [] [ Html.text "Sequence" ]
                                , Html.th [] [ Html.text "Length" ]
                                , Html.th [] [ Html.text "MW" ]
                                , Html.th [] [ Html.text "pI" ]
                                , Html.th [] [ Html.text "Charge" ]
                                ]
                            ]
                        , Html.tbody []
                            (List.map viewAmpRow response.data)
                        ]
                    , viewPagination model response.info
                    ]

            Api.Loading ->
                Html.div [ class "loading" ] [ Html.text "Loading data..." ]

            Api.Failure _ ->
                Html.div [ class "error" ] [ Html.text "Failed to load data." ]

            Api.NotAsked ->
                Html.text ""
        ]


viewAmpRow : AmpSummary -> Html Msg
viewAmpRow amp =
    Html.tr []
        [ Html.td []
            [ Html.a [ Route.Path.href (Route.Path.Amp_Accession_ { accession = amp.accession }) ]
                [ Html.text amp.accession ]
            ]
        , Html.td []
            [ Html.a [ Route.Path.href (Route.Path.Family_Accession_ { accession = amp.family }) ]
                [ Html.text amp.family ]
            ]
        , Html.td [ class "sequence-cell" ]
            [ Html.text
                (if String.length amp.sequence > 25 then
                    String.left 25 amp.sequence ++ "..."

                 else
                    amp.sequence
                )
            ]
        , Html.td [] [ Html.text (String.fromInt amp.length) ]
        , Html.td [] [ Html.text (formatFloat 1 amp.molecularWeight) ]
        , Html.td [] [ Html.text (formatFloat 2 amp.isoelectricPoint) ]
        , Html.td [] [ Html.text (formatFloat 2 amp.charge) ]
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
        Html.div [ class "pagination" ]
            ([ if currentPage > 0 then
                Html.button [ class "page-btn", onClick (GoToPage (currentPage - 1)) ] [ Html.text "Prev" ]

               else
                Html.text ""
             ]
                ++ List.map
                    (\pg ->
                        Html.button
                            [ class
                                (if pg == currentPage then
                                    "page-btn active"

                                 else
                                    "page-btn"
                                )
                            , onClick (GoToPage pg)
                            ]
                            [ Html.text (String.fromInt (pg + 1)) ]
                    )
                    visiblePages
                ++ [ if currentPage < totalPages - 1 then
                        Html.button [ class "page-btn", onClick (GoToPage (currentPage + 1)) ] [ Html.text "Next" ]

                     else
                        Html.text ""
                   ]
            )



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
