module Pages.Amp.Accession_ exposing (Model, Msg, page)

import Api
import Api.Amp exposing (Amp)
import Api.AmpCoprediction exposing (CopredictionScore)
import Api.AmpDistributions exposing (Distributions)
import Api.AmpMetadata exposing (MetadataEntry, MetadataResponse)
import Api.FamilyFeatures exposing (FamilyFeatures)
import Dict exposing (Dict)
import Effect exposing (Effect)
import Html exposing (Html)
import Html.Attributes exposing (attribute, class, colspan, href)
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
        , update = update route
        , subscriptions = subscriptions
        , view = view
        }
        |> Page.withLayout (always <| Layouts.Default {})



-- MODEL


type Tab
    = OverviewTab
    | FeaturesTab


type alias Model =
    { accession : String
    , activeTab : Tab
    , amp : Api.Data Amp
    , distributions : Api.Data Distributions
    , coprediction : Api.Data (List CopredictionScore)
    , metadata : Api.Data MetadataResponse
    , familyFeatures : Api.Data FamilyFeatures
    , metadataPage : Int
    , metadataPageSize : Int
    }


init : Route { accession : String } -> () -> ( Model, Effect Msg )
init route _ =
    let
        accession =
            route.params.accession
    in
    ( { accession = accession
      , activeTab = OverviewTab
      , amp = Api.Loading
      , distributions = Api.Loading
      , coprediction = Api.Loading
      , metadata = Api.Loading
      , familyFeatures = Api.NotAsked
      , metadataPage = 0
      , metadataPageSize = 10
      }
    , Effect.batch
        [ Api.Amp.get { accession = accession, onResponse = GotAmp }
        , Api.AmpDistributions.get { accession = accession, onResponse = GotDistributions }
        , Api.AmpCoprediction.get { accession = accession, onResponse = GotCoprediction }
        , Api.AmpMetadata.get
            { accession = accession
            , page = 0
            , pageSize = 10
            , onResponse = GotMetadata
            }
        ]
    )



-- UPDATE


type Msg
    = GotAmp (Result Http.Error Amp)
    | GotDistributions (Result Http.Error Distributions)
    | GotCoprediction (Result Http.Error (List CopredictionScore))
    | GotMetadata (Result Http.Error MetadataResponse)
    | GotFamilyFeatures (Result Http.Error FamilyFeatures)
    | SwitchTab Tab
    | MetadataGoToPage Int


update : Route { accession : String } -> Msg -> Model -> ( Model, Effect Msg )
update route msg model =
    case msg of
        GotAmp (Ok amp) ->
            ( { model | amp = Api.Success amp }
            , if model.familyFeatures == Api.NotAsked then
                Effect.batch
                    [ Api.FamilyFeatures.get
                        { accession = amp.family
                        , onResponse = GotFamilyFeatures
                        }
                    ]

              else
                Effect.none
            )

        GotAmp (Err err) ->
            ( { model | amp = Api.Failure err }, Effect.none )

        GotDistributions (Ok dist) ->
            ( { model | distributions = Api.Success dist }, Effect.none )

        GotDistributions (Err err) ->
            ( { model | distributions = Api.Failure err }, Effect.none )

        GotCoprediction (Ok scores) ->
            ( { model | coprediction = Api.Success scores }, Effect.none )

        GotCoprediction (Err err) ->
            ( { model | coprediction = Api.Failure err }, Effect.none )

        GotMetadata (Ok meta) ->
            ( { model | metadata = Api.Success meta }, Effect.none )

        GotMetadata (Err err) ->
            ( { model | metadata = Api.Failure err }, Effect.none )

        GotFamilyFeatures (Ok features) ->
            ( { model | familyFeatures = Api.Success features }, Effect.none )

        GotFamilyFeatures (Err err) ->
            ( { model | familyFeatures = Api.Failure err }, Effect.none )

        SwitchTab tab ->
            ( { model | activeTab = tab }, Effect.none )

        MetadataGoToPage pg ->
            ( { model | metadataPage = pg, metadata = Api.Loading }
            , Api.AmpMetadata.get
                { accession = model.accession
                , page = pg
                , pageSize = model.metadataPageSize
                , onResponse = GotMetadata
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
        [ Html.div [ class "page-amp-card" ]
            [ Html.h1 [] [ Html.text model.accession ]
            , viewTabs model.activeTab
            , case model.activeTab of
                OverviewTab ->
                    viewOverview model

                FeaturesTab ->
                    viewFeatures model
            ]
        ]
    }


viewTabs : Tab -> Html Msg
viewTabs activeTab =
    Html.div [ class "tab-bar" ]
        [ Html.button
            [ class
                (if activeTab == OverviewTab then
                    "tab-btn active"

                 else
                    "tab-btn"
                )
            , onClick (SwitchTab OverviewTab)
            ]
            [ Html.text "Overview" ]
        , Html.button
            [ class
                (if activeTab == FeaturesTab then
                    "tab-btn active"

                 else
                    "tab-btn"
                )
            , onClick (SwitchTab FeaturesTab)
            ]
            [ Html.text "Features" ]
        ]



-- OVERVIEW TAB


viewOverview : Model -> Html Msg
viewOverview model =
    Html.div [ class "tab-content" ]
        [ case model.amp of
            Api.Loading ->
                Html.div [ class "loading" ] [ Html.text "Loading AMP data..." ]

            Api.Failure _ ->
                Html.div [ class "error" ] [ Html.text "Failed to load AMP data." ]

            Api.Success amp ->
                Html.div []
                    [ viewAmpInfo amp
                    , viewQualityBadges amp
                    , viewSequence amp.sequence
                    , viewCoprediction model.coprediction
                    , viewDistributionCharts model.distributions
                    , viewMetadata model
                    ]

            Api.NotAsked ->
                Html.text ""
        ]


viewAmpInfo : Amp -> Html Msg
viewAmpInfo amp =
    Html.div [ class "amp-info" ]
        [ Html.table [ class "data-table info-table" ]
            [ Html.tbody []
                [ infoRow "Family"
                    [ Html.a [ Route.Path.href (Route.Path.Family_Accession_ { accession = amp.family }) ]
                        [ Html.text amp.family ]
                    ]
                , infoRow "Length" [ Html.text (String.fromInt amp.length ++ " aa") ]
                , infoRow "Molecular Weight" [ Html.text (formatFloat 2 amp.molecularWeight ++ " Da") ]
                , infoRow "Isoelectric Point" [ Html.text (formatFloat 2 amp.isoelectricPoint) ]
                , infoRow "Charge at pH 7" [ Html.text (formatFloat 2 amp.charge) ]
                , infoRow "Genes"
                    [ Html.text
                        (case amp.numGenes of
                            Just n ->
                                String.fromInt n

                            Nothing ->
                                "N/A"
                        )
                    ]
                ]
            ]
        ]


infoRow : String -> List (Html msg) -> Html msg
infoRow label content =
    Html.tr []
        [ Html.td [ class "info-label" ] [ Html.text label ]
        , Html.td [ class "info-value" ] content
        ]


viewQualityBadges : Amp -> Html Msg
viewQualityBadges amp =
    let
        badge label status =
            Html.span
                [ class
                    ("quality-badge quality-"
                        ++ (if status == "Passed" then
                                "passed"

                            else
                                "failed"
                           )
                    )
                ]
                [ Html.text (label ++ ": " ++ status) ]
    in
    Html.div [ class "quality-badges" ]
        [ badge "Antifam" amp.antifam
        , badge "RNAcode" amp.rnaCode
        , badge "Metaproteomes" amp.metaproteomes
        , badge "Metatranscriptomes" amp.metatranscriptomes
        , badge "Coordinates" amp.coordinates
        ]


viewSequence : String -> Html Msg
viewSequence sequence =
    Html.div [ class "sequence-display" ]
        [ Html.h3 [] [ Html.text "Peptide Sequence" ]
        , Html.div [ class "sequence-box" ]
            (List.map
                (\ch ->
                    Html.span [ class ("aa aa-" ++ String.fromChar ch) ]
                        [ Html.text (String.fromChar ch) ]
                )
                (String.toList sequence)
            )
        ]


viewCoprediction : Api.Data (List CopredictionScore) -> Html Msg
viewCoprediction data =
    Html.div [ class "coprediction-section" ]
        [ Html.h3 [] [ Html.text "Co-prediction Scores" ]
        , case data of
            Api.Success scores ->
                Html.table [ class "data-table" ]
                    [ Html.thead []
                        [ Html.tr []
                            [ Html.th [] [ Html.text "Predictor" ]
                            , Html.th [] [ Html.text "Score" ]
                            ]
                        ]
                    , Html.tbody []
                        (List.map
                            (\score ->
                                Html.tr []
                                    [ Html.td [] [ Html.text score.predictor ]
                                    , Html.td []
                                        [ Html.div [ class "score-bar-container" ]
                                            [ Html.div
                                                [ class "score-bar"
                                                , Html.Attributes.style "width" (String.fromFloat (score.value * 100) ++ "%")
                                                ]
                                                []
                                            , Html.span [ class "score-value" ] [ Html.text (formatFloat 4 score.value) ]
                                            ]
                                        ]
                                    ]
                            )
                            scores
                        )
                    ]

            Api.Loading ->
                Html.div [ class "loading" ] [ Html.text "Loading..." ]

            Api.Failure _ ->
                Html.div [ class "error" ] [ Html.text "Failed to load co-prediction data." ]

            Api.NotAsked ->
                Html.text ""
        ]


viewDistributionCharts : Api.Data Distributions -> Html Msg
viewDistributionCharts data =
    Html.div [ class "distributions-section" ]
        [ Html.h3 [] [ Html.text "Distributions" ]
        , case data of
            Api.Success dist ->
                Html.div [ class "charts-grid" ]
                    [ viewGeoChart dist.geo
                    , viewBarChart "Habitat" dist.habitat
                    , viewBarChart "Microbial Source" dist.microbialSource
                    ]

            Api.Loading ->
                Html.div [ class "loading" ] [ Html.text "Loading charts..." ]

            Api.Failure _ ->
                Html.div [ class "error" ] [ Html.text "Failed to load distribution data." ]

            Api.NotAsked ->
                Html.text ""
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


viewMetadata : Model -> Html Msg
viewMetadata model =
    Html.div [ class "metadata-section" ]
        [ Html.h3 [] [ Html.text "Associated smORF Genes" ]
        , case model.metadata of
            Api.Success meta ->
                Html.div []
                    [ Html.p [ class "result-count" ]
                        [ Html.text (String.fromInt meta.info.totalItem ++ " genes") ]
                    , Html.table [ class "data-table metadata-table" ]
                        [ Html.thead []
                            [ Html.tr []
                                [ Html.th [] [ Html.text "GMSC Accession" ]
                                , Html.th [] [ Html.text "Sample" ]
                                , Html.th [] [ Html.text "Source" ]
                                , Html.th [] [ Html.text "Habitat" ]
                                , Html.th [] [ Html.text "Taxonomy" ]
                                ]
                            ]
                        , Html.tbody []
                            (List.map viewMetadataRow meta.data)
                        ]
                    , viewMetadataPagination model meta.info
                    ]

            Api.Loading ->
                Html.div [ class "loading" ] [ Html.text "Loading metadata..." ]

            Api.Failure _ ->
                Html.div [ class "error" ] [ Html.text "Failed to load metadata." ]

            Api.NotAsked ->
                Html.text ""
        ]


viewMetadataRow : MetadataEntry -> Html Msg
viewMetadataRow entry =
    Html.tr []
        [ Html.td [] [ Html.text entry.gmscAccession ]
        , Html.td [] [ Html.text entry.sample ]
        , Html.td []
            [ Html.text
                (if entry.isMetagenomic then
                    "Metagenomic"

                 else
                    "Genomic"
                )
            ]
        , Html.td [] [ Html.text entry.generalEnvoName ]
        , Html.td [] [ Html.text entry.microbialSourceS ]
        ]


viewMetadataPagination : Model -> Api.AmpMetadata.PageInfo -> Html Msg
viewMetadataPagination model info =
    let
        totalPages =
            info.totalPage

        currentPage =
            model.metadataPage

        visiblePages =
            List.range (max 0 (currentPage - 3)) (min (totalPages - 1) (currentPage + 3))
    in
    if totalPages <= 1 then
        Html.text ""

    else
        Html.div [ class "pagination" ]
            ([ if currentPage > 0 then
                Html.button [ class "page-btn", onClick (MetadataGoToPage (currentPage - 1)) ]
                    [ Html.text "Prev" ]

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
                            , onClick (MetadataGoToPage pg)
                            ]
                            [ Html.text (String.fromInt (pg + 1)) ]
                    )
                    visiblePages
                ++ [ if currentPage < totalPages - 1 then
                        Html.button [ class "page-btn", onClick (MetadataGoToPage (currentPage + 1)) ]
                            [ Html.text "Next" ]

                     else
                        Html.text ""
                   ]
            )



-- FEATURES TAB


viewFeatures : Model -> Html Msg
viewFeatures model =
    Html.div [ class "tab-content" ]
        [ case model.amp of
            Api.Success amp ->
                Html.div []
                    [ viewHelicalWheel amp.sequence
                    , viewSecondaryStructureChart amp
                    , viewViolinPlots model amp
                    ]

            _ ->
                Html.div [ class "loading" ] [ Html.text "Loading..." ]
        ]


viewHelicalWheel : String -> Html Msg
viewHelicalWheel sequence =
    let
        n =
            String.length sequence

        angleStep =
            100.0

        radius =
            120.0

        centerX =
            160.0

        centerY =
            160.0

        residues =
            String.toList sequence
                |> List.indexedMap
                    (\i ch ->
                        let
                            angle =
                                degrees (toFloat i * angleStep)
                        in
                        { ch = ch
                        , x = centerX + radius * cos angle
                        , y = centerY + radius * sin angle
                        }
                    )
    in
    Html.div [ class "helical-wheel-section" ]
        [ Html.h3 [] [ Html.text "Helical Wheel Projection" ]
        , Html.node "svg"
            [ attribute "viewBox" "0 0 320 320"
            , attribute "width" "320"
            , attribute "height" "320"
            , class "helical-wheel"
            ]
            (Html.node "circle"
                [ attribute "cx" (String.fromFloat centerX)
                , attribute "cy" (String.fromFloat centerY)
                , attribute "r" (String.fromFloat radius)
                , attribute "fill" "none"
                , attribute "stroke" "#ccc"
                , attribute "stroke-dasharray" "4,4"
                ]
                []
                :: List.concatMap
                    (\r ->
                        [ Html.node "circle"
                            [ attribute "cx" (String.fromFloat r.x)
                            , attribute "cy" (String.fromFloat r.y)
                            , attribute "r" "14"
                            , attribute "fill" (aaColor r.ch)
                            , attribute "stroke" "#333"
                            , attribute "stroke-width" "1"
                            ]
                            []
                        , Html.node "text"
                            [ attribute "x" (String.fromFloat r.x)
                            , attribute "y" (String.fromFloat (r.y + 4))
                            , attribute "text-anchor" "middle"
                            , attribute "font-size" "12"
                            , attribute "font-weight" "bold"
                            , attribute "fill" "#000"
                            ]
                            [ Html.text (String.fromChar r.ch) ]
                        ]
                    )
                    residues
            )
        ]


aaColor : Char -> String
aaColor ch =
    case ch of
        'K' -> "#1465AC"
        'R' -> "#1465AC"
        'H' -> "#1465AC"
        'D' -> "#DC143C"
        'E' -> "#DC143C"
        'A' -> "#F0E68C"
        'V' -> "#F0E68C"
        'I' -> "#F0E68C"
        'L' -> "#F0E68C"
        'M' -> "#F0E68C"
        'F' -> "#FF8C00"
        'Y' -> "#FF8C00"
        'W' -> "#FF8C00"
        'S' -> "#32CD32"
        'T' -> "#32CD32"
        'N' -> "#32CD32"
        'Q' -> "#32CD32"
        'G' -> "#808080"
        'P' -> "#808080"
        'C' -> "#FFD700"
        _ -> "#CCCCCC"


viewSecondaryStructureChart : Amp -> Html Msg
viewSecondaryStructureChart amp =
    let
        ss =
            amp.secondaryStructure

        chartConfig =
            Encode.object
                [ ( "data"
                  , Encode.list identity
                        [ Encode.object
                            [ ( "type", Encode.string "bar" )
                            , ( "x", Encode.list Encode.string [ "Helix", "Turn", "Sheet" ] )
                            , ( "y", Encode.list Encode.float [ ss.helix, ss.turn, ss.sheet ] )
                            , ( "marker"
                              , Encode.object
                                    [ ( "color", Encode.list Encode.string [ "#e74c3c", "#2ecc71", "#3498db" ] ) ]
                              )
                            ]
                        ]
                  )
                , ( "layout"
                  , Encode.object
                        [ ( "title", Encode.string "Secondary Structure" )
                        , ( "yaxis", Encode.object [ ( "title", Encode.string "Fraction" ), ( "range", Encode.list Encode.float [ 0, 1 ] ) ] )
                        , ( "height", Encode.int 300 )
                        ]
                  )
                ]
    in
    Html.div [ class "secondary-structure-section" ]
        [ Html.h3 [] [ Html.text "Secondary Structure" ]
        , Html.div [ class "chart-container" ]
            [ Html.node "plotly-chart"
                [ attribute "data-chart" (Encode.encode 0 chartConfig) ]
                []
            ]
        ]


viewViolinPlots : Model -> Amp -> Html Msg
viewViolinPlots model amp =
    Html.div [ class "violin-plots-section" ]
        [ Html.h3 [] [ Html.text "Biochemical Properties (in Family Context)" ]
        , case model.familyFeatures of
            Api.Success features ->
                let
                    featureValues =
                        Dict.values features

                    properties =
                        [ ( "Molecular Weight", .mw, amp.molecularWeight )
                        , ( "Isoelectric Point", .isoelectricPoint, amp.isoelectricPoint )
                        , ( "Charge at pH 7", .chargeAtPH7, amp.charge )
                        , ( "Aromaticity", .aromaticity, amp.aromaticity )
                        , ( "Instability Index", .instabilityIndex, amp.instabilityIndex )
                        , ( "GRAVY", .gravy, amp.gravy )
                        ]
                in
                Html.div [ class "charts-grid" ]
                    (List.map
                        (\( name, accessor, currentVal ) ->
                            viewViolinPlot name (List.map accessor featureValues) currentVal
                        )
                        properties
                    )

            Api.Loading ->
                Html.div [ class "loading" ] [ Html.text "Loading family features..." ]

            Api.Failure _ ->
                Html.div [ class "error" ] [ Html.text "Failed to load family features." ]

            Api.NotAsked ->
                Html.text ""
        ]


viewViolinPlot : String -> List Float -> Float -> Html Msg
viewViolinPlot title familyValues currentValue =
    let
        chartConfig =
            Encode.object
                [ ( "data"
                  , Encode.list identity
                        [ Encode.object
                            [ ( "type", Encode.string "violin" )
                            , ( "y", Encode.list Encode.float familyValues )
                            , ( "box", Encode.object [ ( "visible", Encode.bool True ) ] )
                            , ( "meanline", Encode.object [ ( "visible", Encode.bool True ) ] )
                            , ( "name", Encode.string "Family" )
                            ]
                        , Encode.object
                            [ ( "type", Encode.string "scatter" )
                            , ( "y", Encode.list Encode.float [ currentValue ] )
                            , ( "x", Encode.list Encode.string [ "Family" ] )
                            , ( "mode", Encode.string "markers" )
                            , ( "marker"
                              , Encode.object
                                    [ ( "size", Encode.int 12 )
                                    , ( "color", Encode.string "#e74c3c" )
                                    , ( "symbol", Encode.string "diamond" )
                                    ]
                              )
                            , ( "name", Encode.string "This AMP" )
                            ]
                        ]
                  )
                , ( "layout"
                  , Encode.object
                        [ ( "title", Encode.string title )
                        , ( "height", Encode.int 300 )
                        , ( "showlegend", Encode.bool False )
                        ]
                  )
                ]
    in
    Html.div [ class "chart-container" ]
        [ Html.node "plotly-chart"
            [ attribute "data-chart" (Encode.encode 0 chartConfig) ]
            []
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
