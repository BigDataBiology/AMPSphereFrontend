module Pages.Family.Accession_ exposing (Model, Msg, page)

import Api
import Api.AmpDistributions exposing (Distributions)
import Api.AmpList exposing (AmpListResponse, AmpSummary)
import Api.Family exposing (Family)
import Api.FamilyDownloads exposing (FamilyDownloads)
import Api.FamilyFeatures exposing (AmpFeatures, FamilyFeatures)
import Dict exposing (Dict)
import Effect exposing (Effect)
import Html exposing (Html)
import Html.Attributes exposing (attribute, class, href)
import Html.Events exposing (onClick)
import Http
import Json.Encode as Encode
import Layouts
import Page exposing (Page)
import Route exposing (Route)
import Route.Path
import Shared
import View exposing (View)


page : Shared.Model -> Route { accession : String } -> Page Model Msg
page shared route =
    Page.new
        { init = init route
        , update = update
        , subscriptions = subscriptions
        , view = view
        }
        |> Page.withLayout (always <| Layouts.Default {})



-- MODEL


type Tab
    = OverviewTab
    | FeaturesTab
    | DownloadsTab


type alias Model =
    { accession : String
    , activeTab : Tab
    , family : Api.Data Family
    , features : Api.Data FamilyFeatures
    , downloads : Api.Data FamilyDownloads
    , ampsPage : Int
    , ampsPageSize : Int
    , ampsList : Api.Data AmpListResponse
    }


init : Route { accession : String } -> () -> ( Model, Effect Msg )
init route _ =
    let
        accession =
            route.params.accession
    in
    ( { accession = accession
      , activeTab = OverviewTab
      , family = Api.Loading
      , features = Api.NotAsked
      , downloads = Api.NotAsked
      , ampsPage = 0
      , ampsPageSize = 20
      , ampsList = Api.Loading
      }
    , Effect.batch
        [ Api.Family.get { accession = accession, onResponse = GotFamily }
        , Api.AmpList.get
            { filters =
                { page = 0
                , pageSize = 20
                , family = Just accession
                , habitat = Nothing
                , microbialSource = Nothing
                , quality = Nothing
                , pepLengthMin = Nothing
                , pepLengthMax = Nothing
                , mwMin = Nothing
                , mwMax = Nothing
                , piMin = Nothing
                , piMax = Nothing
                , chargeMin = Nothing
                , chargeMax = Nothing
                }
            , onResponse = GotAmpsList
            }
        ]
    )



-- UPDATE


type Msg
    = GotFamily (Result Http.Error Family)
    | GotFeatures (Result Http.Error FamilyFeatures)
    | GotDownloads (Result Http.Error FamilyDownloads)
    | GotAmpsList (Result Http.Error AmpListResponse)
    | SwitchTab Tab
    | AmpsGoToPage Int


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        GotFamily (Ok fam) ->
            ( { model | family = Api.Success fam }
            , Effect.none
            )

        GotFamily (Err err) ->
            ( { model | family = Api.Failure err }, Effect.none )

        GotFeatures (Ok features) ->
            ( { model | features = Api.Success features }, Effect.none )

        GotFeatures (Err err) ->
            ( { model | features = Api.Failure err }, Effect.none )

        GotDownloads (Ok dl) ->
            ( { model | downloads = Api.Success dl }, Effect.none )

        GotDownloads (Err err) ->
            ( { model | downloads = Api.Failure err }, Effect.none )

        GotAmpsList (Ok amps) ->
            ( { model | ampsList = Api.Success amps }, Effect.none )

        GotAmpsList (Err err) ->
            ( { model | ampsList = Api.Failure err }, Effect.none )

        SwitchTab tab ->
            let
                effect =
                    case tab of
                        FeaturesTab ->
                            if model.features == Api.NotAsked then
                                Api.FamilyFeatures.get
                                    { accession = model.accession
                                    , onResponse = GotFeatures
                                    }

                            else
                                Effect.none

                        DownloadsTab ->
                            if model.downloads == Api.NotAsked then
                                Api.FamilyDownloads.get
                                    { accession = model.accession
                                    , onResponse = GotDownloads
                                    }

                            else
                                Effect.none

                        _ ->
                            Effect.none
            in
            ( { model
                | activeTab = tab
                , features =
                    if tab == FeaturesTab && model.features == Api.NotAsked then
                        Api.Loading

                    else
                        model.features
                , downloads =
                    if tab == DownloadsTab && model.downloads == Api.NotAsked then
                        Api.Loading

                    else
                        model.downloads
              }
            , effect
            )

        AmpsGoToPage pg ->
            ( { model | ampsPage = pg, ampsList = Api.Loading }
            , Api.AmpList.get
                { filters =
                    { page = pg
                    , pageSize = model.ampsPageSize
                    , family = Just model.accession
                    , habitat = Nothing
                    , microbialSource = Nothing
                    , quality = Nothing
                    , pepLengthMin = Nothing
                    , pepLengthMax = Nothing
                    , mwMin = Nothing
                    , mwMax = Nothing
                    , piMin = Nothing
                    , piMax = Nothing
                    , chargeMin = Nothing
                    , chargeMax = Nothing
                    }
                , onResponse = GotAmpsList
                }
            )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- VIEW


view : Model -> View Msg
view model =
    { title = model.accession
    , body =
        [ Html.div [ class "page-family-card" ]
            [ Html.h1 [] [ Html.text model.accession ]
            , viewTabs model.activeTab
            , case model.activeTab of
                OverviewTab ->
                    viewOverview model

                FeaturesTab ->
                    viewFeatures model

                DownloadsTab ->
                    viewDownloads model
            ]
        ]
    }


viewTabs : Tab -> Html Msg
viewTabs activeTab =
    let
        tabBtn tab label =
            Html.button
                [ class
                    (if activeTab == tab then
                        "tab-btn active"

                     else
                        "tab-btn"
                    )
                , onClick (SwitchTab tab)
                ]
                [ Html.text label ]
    in
    Html.div [ class "tab-bar" ]
        [ tabBtn OverviewTab "Overview"
        , tabBtn FeaturesTab "Features"
        , tabBtn DownloadsTab "Downloads"
        ]



-- OVERVIEW


viewOverview : Model -> Html Msg
viewOverview model =
    Html.div [ class "tab-content" ]
        [ case model.family of
            Api.Success fam ->
                Html.div []
                    [ viewFamilyInfo fam
                    , viewConsensusSequence fam.consensusSequence
                    , viewDistributionCharts fam.distributions
                    , viewAssociatedAmps model
                    ]

            Api.Loading ->
                Html.div [ class "loading" ] [ Html.text "Loading family data..." ]

            Api.Failure _ ->
                Html.div [ class "error" ] [ Html.text "Failed to load family data." ]

            Api.NotAsked ->
                Html.text ""
        ]


viewFamilyInfo : Family -> Html Msg
viewFamilyInfo fam =
    Html.div [ class "family-info" ]
        [ Html.table [ class "data-table info-table" ]
            [ Html.tbody []
                [ Html.tr []
                    [ Html.td [ class "info-label" ] [ Html.text "Number of AMPs" ]
                    , Html.td [ class "info-value" ] [ Html.text (String.fromInt fam.numAmps) ]
                    ]
                , Html.tr []
                    [ Html.td [ class "info-label" ] [ Html.text "Consensus Sequence Length" ]
                    , Html.td [ class "info-value" ] [ Html.text (String.fromInt (String.length fam.consensusSequence) ++ " aa") ]
                    ]
                ]
            ]
        ]


viewConsensusSequence : String -> Html Msg
viewConsensusSequence sequence =
    Html.div [ class "sequence-display" ]
        [ Html.h3 [] [ Html.text "Consensus Sequence" ]
        , Html.div [ class "sequence-box" ]
            (List.map
                (\ch ->
                    Html.span [ class ("aa aa-" ++ String.fromChar ch) ]
                        [ Html.text (String.fromChar ch) ]
                )
                (String.toList sequence)
            )
        ]


viewDistributionCharts : Distributions -> Html Msg
viewDistributionCharts dist =
    Html.div [ class "distributions-section" ]
        [ Html.h3 [] [ Html.text "Distributions" ]
        , Html.div [ class "charts-grid" ]
            [ viewGeoChart dist.geo
            , viewBarChart "Habitat" dist.habitat
            , viewBarChart "Microbial Source" dist.microbialSource
            ]
        ]


viewGeoChart : Api.AmpDistributions.GeoData -> Html Msg
viewGeoChart geo =
    let
        chartConfig =
            Encode.object
                [ ( "data"
                  , Encode.list identity
                        [ Encode.object
                            [ ( "type", Encode.string "scattergeo" )
                            , ( "lat", Encode.list Encode.float geo.lat )
                            , ( "lon", Encode.list Encode.float geo.lon )
                            , ( "marker"
                              , Encode.object
                                    [ ( "size", Encode.list Encode.float geo.size )
                                    , ( "color", Encode.list Encode.string geo.colors )
                                    ]
                              )
                            , ( "mode", Encode.string "markers" )
                            ]
                        ]
                  )
                , ( "layout"
                  , Encode.object
                        [ ( "title", Encode.string "Geographic Distribution" )
                        , ( "geo"
                          , Encode.object
                                [ ( "projection", Encode.object [ ( "type", Encode.string "natural earth" ) ] )
                                , ( "showland", Encode.bool True )
                                , ( "landcolor", Encode.string "#e5e5e5" )
                                ]
                          )
                        , ( "height", Encode.int 400 )
                        ]
                  )
                ]
    in
    Html.div [ class "chart-container" ]
        [ Html.node "plotly-chart"
            [ attribute "data-chart" (Encode.encode 0 chartConfig) ]
            []
        ]


viewBarChart : String -> Api.AmpDistributions.LabeledData -> Html Msg
viewBarChart title data =
    let
        chartConfig =
            Encode.object
                [ ( "data"
                  , Encode.list identity
                        [ Encode.object
                            [ ( "type", Encode.string "bar" )
                            , ( "x", Encode.list Encode.string data.labels )
                            , ( "y", Encode.list Encode.float data.values )
                            , ( "marker", Encode.object [ ( "color", Encode.string "#1f77b4" ) ] )
                            ]
                        ]
                  )
                , ( "layout"
                  , Encode.object
                        [ ( "title", Encode.string title )
                        , ( "height", Encode.int 350 )
                        , ( "xaxis", Encode.object [ ( "tickangle", Encode.int -45 ) ] )
                        ]
                  )
                ]
    in
    Html.div [ class "chart-container" ]
        [ Html.node "plotly-chart"
            [ attribute "data-chart" (Encode.encode 0 chartConfig) ]
            []
        ]


viewAssociatedAmps : Model -> Html Msg
viewAssociatedAmps model =
    Html.div [ class "associated-amps-section" ]
        [ Html.h3 [] [ Html.text "Associated AMPs" ]
        , case model.ampsList of
            Api.Success response ->
                Html.div []
                    [ Html.p [ class "result-count" ]
                        [ Html.text (String.fromInt response.info.totalItem ++ " AMPs") ]
                    , Html.table [ class "data-table" ]
                        [ Html.thead []
                            [ Html.tr []
                                [ Html.th [] [ Html.text "Accession" ]
                                , Html.th [] [ Html.text "Sequence" ]
                                , Html.th [] [ Html.text "Length" ]
                                , Html.th [] [ Html.text "MW" ]
                                , Html.th [] [ Html.text "pI" ]
                                ]
                            ]
                        , Html.tbody []
                            (List.map viewAmpRow response.data)
                        ]
                    , viewAmpsPagination model response.info
                    ]

            Api.Loading ->
                Html.div [ class "loading" ] [ Html.text "Loading AMPs..." ]

            Api.Failure _ ->
                Html.div [ class "error" ] [ Html.text "Failed to load AMPs." ]

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
        , Html.td [ class "sequence-cell" ]
            [ Html.text
                (if String.length amp.sequence > 30 then
                    String.left 30 amp.sequence ++ "..."

                 else
                    amp.sequence
                )
            ]
        , Html.td [] [ Html.text (String.fromInt amp.length) ]
        , Html.td [] [ Html.text (formatFloat 1 amp.molecularWeight) ]
        , Html.td [] [ Html.text (formatFloat 2 amp.isoelectricPoint) ]
        ]


viewAmpsPagination : Model -> Api.AmpList.PageInfo -> Html Msg
viewAmpsPagination model info =
    let
        totalPages =
            info.totalPage

        currentPage =
            model.ampsPage

        visiblePages =
            List.range (max 0 (currentPage - 3)) (min (totalPages - 1) (currentPage + 3))
    in
    if totalPages <= 1 then
        Html.text ""

    else
        Html.div [ class "pagination" ]
            ([ if currentPage > 0 then
                Html.button [ class "page-btn", onClick (AmpsGoToPage (currentPage - 1)) ] [ Html.text "Prev" ]

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
                            , onClick (AmpsGoToPage pg)
                            ]
                            [ Html.text (String.fromInt (pg + 1)) ]
                    )
                    visiblePages
                ++ [ if currentPage < totalPages - 1 then
                        Html.button [ class "page-btn", onClick (AmpsGoToPage (currentPage + 1)) ] [ Html.text "Next" ]

                     else
                        Html.text ""
                   ]
            )



-- FEATURES TAB


viewFeatures : Model -> Html Msg
viewFeatures model =
    Html.div [ class "tab-content" ]
        [ case model.features of
            Api.Success features ->
                let
                    featureValues =
                        Dict.values features

                    properties =
                        [ ( "Molecular Weight", .mw )
                        , ( "Isoelectric Point", .isoelectricPoint )
                        , ( "Charge at pH 7", .chargeAtPH7 )
                        , ( "Aromaticity", .aromaticity )
                        , ( "Instability Index", .instabilityIndex )
                        , ( "GRAVY", .gravy )
                        ]
                in
                Html.div [ class "charts-grid" ]
                    (List.map
                        (\( name, accessor ) ->
                            viewBoxPlot name (List.map accessor featureValues)
                        )
                        properties
                    )

            Api.Loading ->
                Html.div [ class "loading" ] [ Html.text "Loading features..." ]

            Api.Failure _ ->
                Html.div [ class "error" ] [ Html.text "Failed to load features." ]

            Api.NotAsked ->
                Html.text ""
        ]


viewBoxPlot : String -> List Float -> Html Msg
viewBoxPlot title values =
    let
        chartConfig =
            Encode.object
                [ ( "data"
                  , Encode.list identity
                        [ Encode.object
                            [ ( "type", Encode.string "box" )
                            , ( "y", Encode.list Encode.float values )
                            , ( "name", Encode.string title )
                            , ( "boxpoints", Encode.string "all" )
                            , ( "jitter", Encode.float 0.3 )
                            ]
                        ]
                  )
                , ( "layout"
                  , Encode.object
                        [ ( "title", Encode.string title )
                        , ( "height", Encode.int 300 )
                        ]
                  )
                ]
    in
    Html.div [ class "chart-container" ]
        [ Html.node "plotly-chart"
            [ attribute "data-chart" (Encode.encode 0 chartConfig) ]
            []
        ]



-- DOWNLOADS TAB


viewDownloads : Model -> Html Msg
viewDownloads model =
    Html.div [ class "tab-content" ]
        [ case model.downloads of
            Api.Success dl ->
                Html.table [ class "data-table downloads-table" ]
                    [ Html.thead []
                        [ Html.tr []
                            [ Html.th [] [ Html.text "File" ]
                            , Html.th [] [ Html.text "Description" ]
                            ]
                        ]
                    , Html.tbody []
                        [ dlRow dl.alignment "Multiple Sequence Alignment" ".aln"
                        , dlRow dl.sequences "Amino Acid Sequences" ".faa"
                        , dlRow dl.hmmProfile "HMM Profile" ".hmm"
                        , dlRow dl.treeFigure "Phylogenetic Tree (ASCII)" ".ascii"
                        , dlRow dl.treeNwk "Phylogenetic Tree (Newick)" ".nwk"
                        ]
                    ]

            Api.Loading ->
                Html.div [ class "loading" ] [ Html.text "Loading downloads..." ]

            Api.Failure _ ->
                Html.div [ class "error" ] [ Html.text "Failed to load downloads." ]

            Api.NotAsked ->
                Html.text ""
        ]


dlRow : String -> String -> String -> Html msg
dlRow url description ext =
    Html.tr []
        [ Html.td []
            [ Html.a [ href url ] [ Html.text (description ++ " (" ++ ext ++ ")") ] ]
        , Html.td [] [ Html.text description ]
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
