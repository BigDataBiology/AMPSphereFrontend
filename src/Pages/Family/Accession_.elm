module Pages.Family.Accession_ exposing (Model, Msg, page)

import Api
import Api.AmpDistributions exposing (Distributions)
import Api.AmpList exposing (AmpListResponse, AmpSummary)
import Api.Family exposing (Family)
import Api.FamilyDownloads exposing (FamilyDownloads)
import Api.FamilyFeatures exposing (AmpFeatures, FamilyFeatures)
import Components.SeqLogo
import Components.SequenceLegend
import Bootstrap.Alert as Alert
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
import Html.Events
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
        , update = update
        , subscriptions = subscriptions
        , view = view
        }
        |> Page.withLayout (always <| Layouts.Default {})



-- MODEL



type alias Model =
    { accession : String
    , tabState : Tab.State
    , family : Api.Data Family
    , features : Api.Data FamilyFeatures
    , downloads : Api.Data FamilyDownloads
    , ampsPage : Int
    , ampsPageSize : Int
    , ampsList : Api.Data AmpListResponse
    , alignment : Api.Data String
    }


init : Route { accession : String } -> () -> ( Model, Effect Msg )
init route _ =
    let
        accession =
            route.params.accession
    in
    ( { accession = accession
      , tabState = Tab.initialState
      , family = Api.Loading
      , features = Api.NotAsked
      , downloads = Api.NotAsked
      , ampsPage = 0
      , ampsPageSize = 20
      , ampsList = Api.Loading
      , alignment = Api.NotAsked
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
    | TabMsg Tab.State
    | GotAlignment (Result Http.Error String)
    | AmpsGoToPage Int


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        GotFamily (Ok fam) ->
            ( { model | family = Api.Success fam, alignment = Api.Loading }
            , Effect.sendCmd
                (Http.get
                    { url = fam.downloads.alignment
                    , expect = Http.expectString GotAlignment
                    }
                )
            )

        GotFamily (Err err) ->
            ( { model | family = Api.Failure err }, Effect.none )

        GotAlignment (Ok text) ->
            ( { model | alignment = Api.Success text }, Effect.none )

        GotAlignment (Err err) ->
            ( { model | alignment = Api.Failure err }, Effect.none )

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

        TabMsg state ->
            let
                needsFeatures =
                    state == Tab.customInitialState "features" && model.features == Api.NotAsked

                needsDownloads =
                    state == Tab.customInitialState "downloads" && model.downloads == Api.NotAsked

                effect =
                    if needsFeatures then
                        Api.FamilyFeatures.get { accession = model.accession, onResponse = GotFeatures }

                    else if needsDownloads then
                        Api.FamilyDownloads.get { accession = model.accession, onResponse = GotDownloads }

                    else
                        Effect.none
            in
            ( { model
                | tabState = state
                , features =
                    if needsFeatures then
                        Api.Loading

                    else
                        model.features
                , downloads =
                    if needsDownloads then
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
                , Tab.item
                    { id = "downloads"
                    , link = Tab.link [] [ Html.text "Downloads" ]
                    , pane = Tab.pane [ class "pt-3" ] [ viewDownloads model ]
                    }
                ]
            |> Tab.view model.tabState
        ]
    }



-- OVERVIEW


viewOverview : Model -> Html Msg
viewOverview model =
    case model.family of
        Api.Success fam ->
            Html.div []
                [ viewFamilyInfo fam
                , viewConsensusSequence fam.consensusSequence
                , viewSeqLogo model.alignment
                , viewDistributionCharts fam.distributions
                , viewAssociatedAmps model
                ]

        Api.Loading ->
            Html.div [ class "text-center py-4" ]
                [ Spinner.spinner [ Spinner.grow ] []
                , Html.p [ class "text-muted mt-2" ] [ Html.text "Loading family data..." ]
                ]

        Api.Failure _ ->
            Alert.simpleDanger [] [ Html.text "Failed to load family data." ]

        Api.NotAsked ->
            Html.text ""


viewFamilyInfo : Family -> Html Msg
viewFamilyInfo fam =
    Card.config [ Card.attrs [ class "mb-3" ] ]
        |> Card.headerH5 [] [ Html.text "Properties" ]
        |> Card.block []
            [ Block.custom <|
                Table.table
                    { options = [ Table.bordered, Table.small ]
                    , thead = Table.thead [] []
                    , tbody =
                        Table.tbody []
                            [ Table.tr []
                                [ Table.th [ Table.cellAttr (class "w-25") ] [ Html.text "Number of AMPs" ]
                                , Table.td [] [ Html.text (String.fromInt fam.numAmps) ]
                                ]
                            , Table.tr []
                                [ Table.th [ Table.cellAttr (class "w-25") ] [ Html.text "Consensus Sequence Length" ]
                                , Table.td [] [ Html.text (String.fromInt (String.length fam.consensusSequence) ++ " aa") ]
                                ]
                            ]
                    }
            ]
        |> Card.view


viewConsensusSequence : String -> Html Msg
viewConsensusSequence sequence =
    Card.config [ Card.attrs [ class "mb-3" ] ]
        |> Card.headerH5 [] [ Html.text "Consensus Sequence" ]
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


viewSeqLogo : Api.Data String -> Html Msg
viewSeqLogo alignmentData =
    case alignmentData of
        Api.Success text ->
            Card.config [ Card.attrs [ class "mb-3" ] ]
                |> Card.headerH5 [] [ Html.text "Sequence Logo" ]
                |> Card.block []
                    [ Block.custom <|
                        Components.SeqLogo.view text
                    ]
                |> Card.view

        Api.Loading ->
            Card.config [ Card.attrs [ class "mb-3" ] ]
                |> Card.headerH5 [] [ Html.text "Sequence Logo" ]
                |> Card.block []
                    [ Block.custom <|
                        Html.div [ class "text-center py-3" ]
                            [ Spinner.spinner [] [] ]
                    ]
                |> Card.view

        Api.Failure _ ->
            Html.text ""

        Api.NotAsked ->
            Html.text ""


viewDistributionCharts : Distributions -> Html Msg
viewDistributionCharts dist =
    Card.config [ Card.attrs [ class "mb-3" ] ]
        |> Card.headerH5 [] [ Html.text "Distributions" ]
        |> Card.block []
            [ Block.custom <|
                Grid.row []
                    [ Grid.col [ Col.md12 ] [ viewGeoChart dist.geo ]
                    , Grid.col [ Col.md6 ] [ viewBarChart "Habitat" dist.habitat ]
                    , Grid.col [ Col.md6 ] [ viewBarChart "Microbial Source" dist.microbialSource ]
                    ]
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


viewAssociatedAmps : Model -> Html Msg
viewAssociatedAmps model =
    Card.config [ Card.attrs [ class "mb-3" ] ]
        |> Card.headerH5 [] [ Html.text "Associated AMPs" ]
        |> Card.block []
            [ Block.custom <|
                case model.ampsList of
                    Api.Success response ->
                        Html.div []
                            [ Html.p [ class "text-muted small" ]
                                [ Html.text (String.fromInt response.info.totalItem ++ " AMPs") ]
                            , Table.table
                                { options = [ Table.striped, Table.hover, Table.small, Table.responsive ]
                                , thead =
                                    Table.simpleThead
                                        [ Table.th [] [ Html.text "Accession" ]
                                        , Table.th [] [ Html.text "Sequence" ]
                                        , Table.th [] [ Html.text "Length" ]
                                        , Table.th [] [ Html.text "MW" ]
                                        , Table.th [] [ Html.text "pI" ]
                                        ]
                                , tbody =
                                    Table.tbody []
                                        (List.map viewAmpRow response.data)
                                }
                            , viewAmpsPagination model response.info
                            ]

                    Api.Loading ->
                        Html.div [ class "text-center py-3" ]
                            [ Spinner.spinner [] [] ]

                    Api.Failure _ ->
                        Alert.simpleDanger [] [ Html.text "Failed to load AMPs." ]

                    Api.NotAsked ->
                        Html.text ""
            ]
        |> Card.view


viewAmpRow : AmpSummary -> Table.Row Msg
viewAmpRow amp =
    Table.tr []
        [ Table.td []
            [ Html.a [ Route.Path.href (Route.Path.Amp_Accession_ { accession = amp.accession }) ]
                [ Html.text amp.accession ]
            ]
        , Table.td [ Table.cellAttr (class "text-monospace small") ]
            [ Html.text
                (if String.length amp.sequence > 30 then
                    String.left 30 amp.sequence ++ "..."

                 else
                    amp.sequence
                )
            ]
        , Table.td [] [ Html.text (String.fromInt amp.length) ]
        , Table.td [] [ Html.text (formatFloat 1 amp.molecularWeight) ]
        , Table.td [] [ Html.text (formatFloat 2 amp.isoelectricPoint) ]
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
        Html.nav [ class "mt-2" ]
            [ Html.ul [ class "pagination pagination-sm justify-content-center" ]
                ([ if currentPage > 0 then
                    Html.li [ class "page-item" ]
                        [ Html.a [ class "page-link", href "#", onClickPreventDefault (AmpsGoToPage (currentPage - 1)) ]
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
                                    , onClickPreventDefault (AmpsGoToPage pg)
                                    ]
                                    [ Html.text (String.fromInt (pg + 1)) ]
                                ]
                        )
                        visiblePages
                    ++ [ if currentPage < totalPages - 1 then
                            Html.li [ class "page-item" ]
                                [ Html.a [ class "page-link", href "#", onClickPreventDefault (AmpsGoToPage (currentPage + 1)) ]
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
    case model.features of
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
            Grid.row []
                (List.map
                    (\( name, accessor ) ->
                        Grid.col [ Col.md6, Col.attrs [ class "mb-3" ] ]
                            [ viewBoxPlot name (List.map accessor featureValues) ]
                    )
                    properties
                )

        Api.Loading ->
            Html.div [ class "text-center py-4" ]
                [ Spinner.spinner [ Spinner.grow ] []
                , Html.p [ class "text-muted mt-2" ] [ Html.text "Loading features..." ]
                ]

        Api.Failure _ ->
            Alert.simpleDanger [] [ Html.text "Failed to load features." ]

        Api.NotAsked ->
            Html.text ""


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
    Card.config []
        |> Card.block []
            [ Block.custom <|
                Html.node "plotly-chart"
                    [ attribute "data-chart" (Encode.encode 0 chartConfig) ]
                    []
            ]
        |> Card.view



-- DOWNLOADS TAB


viewDownloads : Model -> Html Msg
viewDownloads model =
    case model.downloads of
        Api.Success dl ->
            Table.table
                { options = [ Table.striped, Table.hover, Table.bordered ]
                , thead =
                    Table.simpleThead
                        [ Table.th [] [ Html.text "File" ]
                        , Table.th [] [ Html.text "Description" ]
                        ]
                , tbody =
                    Table.tbody []
                        [ dlRow dl.alignment "Multiple Sequence Alignment" ".aln"
                        , dlRow dl.sequences "Amino Acid Sequences" ".faa"
                        , dlRow dl.hmmProfile "HMM Profile" ".hmm"
                        , dlRow dl.treeFigure "Phylogenetic Tree (ASCII)" ".ascii"
                        , dlRow dl.treeNwk "Phylogenetic Tree (Newick)" ".nwk"
                        ]
                }

        Api.Loading ->
            Html.div [ class "text-center py-4" ]
                [ Spinner.spinner [ Spinner.grow ] []
                , Html.p [ class "text-muted mt-2" ] [ Html.text "Loading downloads..." ]
                ]

        Api.Failure _ ->
            Alert.simpleDanger [] [ Html.text "Failed to load downloads." ]

        Api.NotAsked ->
            Html.text ""


dlRow : String -> String -> String -> Table.Row msg
dlRow url description ext =
    Table.tr []
        [ Table.td []
            [ Html.a [ href url ] [ Html.text (description ++ " (" ++ ext ++ ")") ] ]
        , Table.td [] [ Html.text description ]
        ]



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
