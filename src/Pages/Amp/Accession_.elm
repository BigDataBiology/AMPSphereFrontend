module Pages.Amp.Accession_ exposing (Model, Msg, page)

import Api
import Api.Amp exposing (Amp)
import Api.AmpCoprediction exposing (CopredictionScore)
import Api.AmpDistributions exposing (Distributions)
import Api.AmpMetadata exposing (MetadataEntry, MetadataResponse)
import Api.FamilyFeatures exposing (FamilyFeatures)
import Components.SequenceLegend
import Bootstrap.Alert as Alert
import Bootstrap.Badge as Badge
import Bootstrap.Card as Card
import Bootstrap.Card.Block as Block
import Bootstrap.Grid as Grid
import Bootstrap.Grid.Col as Col
import Bootstrap.Spinner as Spinner
import Bootstrap.Tab as Tab
import Bootstrap.Table as Table
import Dict exposing (Dict)
import Effect exposing (Effect)
import Html exposing (Html)
import Html.Attributes exposing (attribute, class, href)
import Html.Events exposing (onClick)
import Json.Decode
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


type alias Model =
    { accession : String
    , tabState : Tab.State
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
      , tabState = Tab.initialState
      , amp = Api.Loading
      , distributions = Api.Loading
      , coprediction = Api.Loading
      , metadata = Api.Loading
      , familyFeatures = Api.NotAsked
      , metadataPage = 0
      , metadataPageSize = 50
      }
    , Effect.batch
        [ Api.Amp.get { accession = accession, onResponse = GotAmp }
        , Api.AmpDistributions.get { accession = accession, onResponse = GotDistributions }
        , Api.AmpCoprediction.get { accession = accession, onResponse = GotCoprediction }
        , Api.AmpMetadata.get
            { accession = accession
            , page = 0
            , pageSize = 50
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
    | TabMsg Tab.State
    | MetadataGoToPage Int


update : Route { accession : String } -> Msg -> Model -> ( Model, Effect Msg )
update route msg model =
    case msg of
        GotAmp (Ok amp) ->
            ( { model | amp = Api.Success amp }
            , if model.familyFeatures == Api.NotAsked then
                Api.FamilyFeatures.get
                    { accession = amp.family
                    , onResponse = GotFamilyFeatures
                    }

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

        TabMsg state ->
            ( { model | tabState = state }, Effect.none )

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
        [ Html.h1 [ class "mb-3" ] [ Html.text model.accession ]
        , Tab.config TabMsg
            |> Tab.items
                [ Tab.item
                    { id = "overview"
                    , link = Tab.link [] [ Html.text "Overview" ]
                    , pane = Tab.pane [ class "pt-3" ] [ viewOverview model ]
                    }
                , Tab.item
                    { id = "features"
                    , link = Tab.link [] [ Html.text "Features" ]
                    , pane = Tab.pane [ class "pt-3" ] [ viewFeatures model ]
                    }
                ]
            |> Tab.view model.tabState
        ]
    }



-- OVERVIEW TAB


viewOverview : Model -> Html Msg
viewOverview model =
    case model.amp of
        Api.Loading ->
            Html.div [ class "text-center py-4" ]
                [ Spinner.spinner [ Spinner.grow ] []
                , Html.p [ class "text-muted mt-2" ] [ Html.text "Loading AMP data..." ]
                ]

        Api.Failure _ ->
            Alert.simpleDanger [] [ Html.text "Failed to load AMP data." ]

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


viewAmpInfo : Amp -> Html Msg
viewAmpInfo amp =
    Card.config [ Card.attrs [ class "mb-3" ] ]
        |> Card.headerH5 [] [ Html.text "Properties" ]
        |> Card.block []
            [ Block.custom <|
                Table.table
                    { options = [ Table.bordered, Table.small ]
                    , thead = Table.thead [] []
                    , tbody =
                        Table.tbody []
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
                    }
            ]
        |> Card.view


infoRow : String -> List (Html msg) -> Table.Row msg
infoRow label content =
    Table.tr []
        [ Table.th [ Table.cellAttr (class "w-25") ] [ Html.text label ]
        , Table.td [] content
        ]


viewQualityBadges : Amp -> Html Msg
viewQualityBadges amp =
    let
        badge label status =
            if status == "Passed" then
                Badge.badgeSuccess [ class "mr-2 mb-1 p-2" ] [ Html.text (label ++ ": " ++ status) ]

            else
                Badge.badgeDanger [ class "mr-2 mb-1 p-2" ] [ Html.text (label ++ ": " ++ status) ]
    in
    Html.div [ class "mb-3" ]
        [ badge "Antifam" amp.antifam
        , badge "RNAcode" amp.rnaCode
        , badge "Metaproteomes" amp.metaproteomes
        , badge "Metatranscriptomes" amp.metatranscriptomes
        , badge "Coordinates" amp.coordinates
        ]


viewSequence : String -> Html Msg
viewSequence sequence =
    Card.config [ Card.attrs [ class "mb-3" ] ]
        |> Card.headerH5 [] [ Html.text "Peptide Sequence" ]
        |> Card.block []
            [ Block.custom <|
                Html.div []
                    [ Html.div [ class "sequence-box p-3 bg-light text-monospace" ]
                        (List.map
                            (\ch ->
                                Html.span [ class ("aa aa-" ++ String.fromChar ch) ]
                                    [ Html.text (String.fromChar ch) ]
                            )
                            (String.toList sequence)
                        )
                    , Components.SequenceLegend.view
                    ]
            ]
        |> Card.view


viewCoprediction : Api.Data (List CopredictionScore) -> Html Msg
viewCoprediction data =
    Card.config [ Card.attrs [ class "mb-3" ] ]
        |> Card.headerH5 [] [ Html.text "Co-prediction Scores" ]
        |> Card.block []
            [ Block.custom <|
                case data of
                    Api.Success scores ->
                        Table.table
                            { options = [ Table.striped, Table.small ]
                            , thead =
                                Table.simpleThead
                                    [ Table.th [] [ Html.text "Predictor" ]
                                    , Table.th [] [ Html.text "Score" ]
                                    ]
                            , tbody =
                                Table.tbody []
                                    (List.map
                                        (\score ->
                                            Table.tr []
                                                [ Table.td [] [ Html.text score.predictor ]
                                                , Table.td []
                                                    [ Html.div [ class "d-flex align-items-center" ]
                                                        [ Html.div [ class "progress flex-grow-1 mr-2", Html.Attributes.style "height" "20px" ]
                                                            [ Html.div
                                                                [ class "progress-bar"
                                                                , Html.Attributes.style "width" (String.fromFloat (score.value * 100) ++ "%")
                                                                ]
                                                                []
                                                            ]
                                                        , Html.span [ class "text-monospace small" ] [ Html.text (formatFloat 4 score.value) ]
                                                        ]
                                                    ]
                                                ]
                                        )
                                        scores
                                    )
                            }

                    Api.Loading ->
                        Html.div [ class "text-center py-3" ]
                            [ Spinner.spinner [] [] ]

                    Api.Failure _ ->
                        Alert.simpleDanger [] [ Html.text "Failed to load co-prediction data." ]

                    Api.NotAsked ->
                        Html.text ""
            ]
        |> Card.view


viewDistributionCharts : Api.Data Distributions -> Html Msg
viewDistributionCharts data =
    Card.config [ Card.attrs [ class "mb-3" ] ]
        |> Card.headerH5 [] [ Html.text "Distributions" ]
        |> Card.block []
            [ Block.custom <|
                case data of
                    Api.Success dist ->
                        Grid.row []
                            [ Grid.col [ Col.md12 ] [ viewGeoChart dist.geo ]
                            , Grid.col [ Col.md6 ] [ viewBarChart "Habitat" dist.habitat ]
                            , Grid.col [ Col.md6 ] [ viewBarChart "Microbial Source" dist.microbialSource ]
                            ]

                    Api.Loading ->
                        Html.div [ class "text-center py-3" ]
                            [ Spinner.spinner [] [] ]

                    Api.Failure _ ->
                        Alert.simpleDanger [] [ Html.text "Failed to load distribution data." ]

                    Api.NotAsked ->
                        Html.text ""
            ]
        |> Card.view


viewGeoChart : Api.AmpDistributions.GeoData -> Html Msg
viewGeoChart geo =
    let
        maxSize =
            geo.size |> List.maximum |> Maybe.withDefault 1.0

        sizeRef =
            if maxSize > 0 then
                2.0 * maxSize / (40.0 ^ 2)

            else
                1.0

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
                                    , ( "sizemode", Encode.string "area" )
                                    , ( "sizeref", Encode.float sizeRef )
                                    , ( "sizemin", Encode.float 4.0 )
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
    Html.node "plotly-chart"
        [ attribute "data-chart" (Encode.encode 0 chartConfig) ]
        []


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
    Html.node "plotly-chart"
        [ attribute "data-chart" (Encode.encode 0 chartConfig) ]
        []


viewMetadata : Model -> Html Msg
viewMetadata model =
    Card.config [ Card.attrs [ class "mb-3" ] ]
        |> Card.headerH5 [] [ Html.text "Associated smORF Genes" ]
        |> Card.block []
            [ Block.custom <|
                case model.metadata of
                    Api.Success meta ->
                        Html.div []
                            [ Html.p [ class "text-muted small" ]
                                [ Html.text (String.fromInt meta.info.totalItem ++ " genes") ]
                            , Table.table
                                { options = [ Table.striped, Table.hover, Table.small, Table.responsive ]
                                , thead =
                                    Table.simpleThead
                                        [ Table.th [] [ Html.text "GMSC Accession" ]
                                        , Table.th [] [ Html.text "Sample" ]
                                        , Table.th [] [ Html.text "Source" ]
                                        , Table.th [] [ Html.text "Habitat" ]
                                        , Table.th [] [ Html.text "Taxonomy" ]
                                        ]
                                , tbody =
                                    Table.tbody []
                                        (List.map viewMetadataRow meta.data)
                                }
                            , viewMetadataPagination model meta.info
                            ]

                    Api.Loading ->
                        Html.div [ class "text-center py-3" ]
                            [ Spinner.spinner [] [] ]

                    Api.Failure _ ->
                        Alert.simpleDanger [] [ Html.text "Failed to load metadata." ]

                    Api.NotAsked ->
                        Html.text ""
            ]
        |> Card.view


viewMetadataRow : MetadataEntry -> Table.Row Msg
viewMetadataRow entry =
    Table.tr []
        [ Table.td [ Table.cellAttr (class "text-monospace small") ] [ Html.text entry.gmscAccession ]
        , Table.td [] [ Html.text entry.sample ]
        , Table.td []
            [ if entry.isMetagenomic then
                Badge.badgeInfo [] [ Html.text "Metagenomic" ]

              else
                Badge.badgeSecondary [] [ Html.text "Genomic" ]
            ]
        , Table.td [] [ Html.text entry.generalEnvoName ]
        , Table.td [ Table.cellAttr (class "small") ] [ Html.text entry.microbialSourceS ]
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
        Html.nav [ class "mt-2" ]
            [ Html.ul [ class "pagination pagination-sm justify-content-center" ]
                ([ if currentPage > 0 then
                    Html.li [ class "page-item" ]
                        [ Html.a [ class "page-link", href "#", onClickPreventDefault (MetadataGoToPage (currentPage - 1)) ]
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
                                    , onClickPreventDefault (MetadataGoToPage pg)
                                    ]
                                    [ Html.text (String.fromInt (pg + 1)) ]
                                ]
                        )
                        visiblePages
                    ++ [ if currentPage < totalPages - 1 then
                            Html.li [ class "page-item" ]
                                [ Html.a [ class "page-link", href "#", onClickPreventDefault (MetadataGoToPage (currentPage + 1)) ]
                                    [ Html.text "Next" ]
                                ]

                         else
                            Html.li [ class "page-item disabled" ]
                                [ Html.span [ class "page-link" ] [ Html.text "Next" ] ]
                       ]
                )
            ]



-- FEATURES TAB


viewFeatures : Model -> Html Msg
viewFeatures model =
    case model.amp of
        Api.Success amp ->
            Html.div []
                [ viewHelicalWheel amp.sequence
                , viewSecondaryStructureChart amp
                , viewViolinPlots model amp
                ]

        _ ->
            Html.div [ class "text-center py-4" ]
                [ Spinner.spinner [ Spinner.grow ] [] ]


viewHelicalWheel : String -> Html Msg
viewHelicalWheel sequence =
    Card.config [ Card.attrs [ class "mb-3" ] ]
        |> Card.headerH5 [] [ Html.text "Helical Wheel Projection" ]
        |> Card.block []
            [ Block.custom <|
                Html.node "helical-wheel"
                    [ attribute "data-sequence" sequence ]
                    []
            ]
        |> Card.view


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
    Card.config [ Card.attrs [ class "mb-3" ] ]
        |> Card.headerH5 [] [ Html.text "Secondary Structure" ]
        |> Card.block []
            [ Block.custom <|
                Html.node "plotly-chart"
                    [ attribute "data-chart" (Encode.encode 0 chartConfig) ]
                    []
            ]
        |> Card.view


viewViolinPlots : Model -> Amp -> Html Msg
viewViolinPlots model amp =
    Card.config [ Card.attrs [ class "mb-3" ] ]
        |> Card.headerH5 [] [ Html.text "Biochemical Properties (in Family Context)" ]
        |> Card.block []
            [ Block.custom <|
                case model.familyFeatures of
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
                        Grid.row []
                            (List.map
                                (\( name, accessor, currentVal ) ->
                                    Grid.col [ Col.md6, Col.attrs [ class "mb-3" ] ]
                                        [ viewViolinPlot name (List.map accessor featureValues) currentVal ]
                                )
                                properties
                            )

                    Api.Loading ->
                        Html.div [ class "text-center py-3" ]
                            [ Spinner.spinner [] []
                            , Html.p [ class "text-muted mt-2 small" ] [ Html.text "Loading family features..." ]
                            ]

                    Api.Failure _ ->
                        Alert.simpleDanger [] [ Html.text "Failed to load family features." ]

                    Api.NotAsked ->
                        Html.text ""
            ]
        |> Card.view


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
    Html.node "plotly-chart"
        [ attribute "data-chart" (Encode.encode 0 chartConfig) ]
        []



-- HELPERS


onClickPreventDefault : msg -> Html.Attribute msg
onClickPreventDefault msg =
    Html.Events.preventDefaultOn "click" (Json.Decode.succeed ( msg, True ))


formatFloat : Int -> Float -> String
formatFloat decimals val =
    let
        factor =
            toFloat (10 ^ decimals)

        rounded =
            toFloat (round (val * factor)) / factor
    in
    String.fromFloat rounded
