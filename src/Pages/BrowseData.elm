module Pages.BrowseData exposing (Model, Msg, page)

import Api
import Api.AmpList exposing (AmpListResponse, AmpSummary)
import Api.AvailableOptions exposing (AvailableOptions, Range)
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
import Components.Pagination as Pagination
import Dict
import Effect exposing (Effect)
import Set exposing (Set)
import Html exposing (Html)
import Html.Attributes exposing (attribute, class, href, selected, style, value)
import Html.Events exposing (onClick, onInput)
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
    , showAdvancedFilters : Bool
    , visibleColumns : Set String
    , downloadStatus : DownloadStatus
    }


{-| Whether a "Download TSV" bulk fetch is currently in flight. The export hits
the API again (with the active filters and a large page size) so it can include
every matching AMP, not just the visible page.
-}
type DownloadStatus
    = DownloadIdle
    | DownloadPreparing DownloadFormat


{-| Which file format a bulk export should produce. TSV is the full table;
FASTA is just the accession + sequence of every matching AMP.
-}
type DownloadFormat
    = DownloadTsv
    | DownloadFasta


{-| Upper bound on rows pulled in a single CSV export. Without filters the
catalog is hundreds of thousands of AMPs, so we cap the request rather than
attempt to stream the whole database into the browser.
-}
maxExport : Int
maxExport =
    5000


init : Route () -> () -> ( Model, Effect Msg )
init route _ =
    let
        str key =
            Dict.get key route.query |> Maybe.withDefault ""

        nonEmpty key =
            Dict.get key route.query
                |> Maybe.andThen
                    (\v ->
                        if v == "" then
                            Nothing

                        else
                            Just v
                    )

        pg =
            Dict.get "page" route.query
                |> Maybe.andThen String.toInt
                |> Maybe.withDefault 0

        microbialSource =
            nonEmpty "microbial_source"

        ranges =
            [ str "pep_length_min", str "pep_length_max", str "mw_min", str "mw_max", str "pi_min", str "pi_max", str "charge_min", str "charge_max" ]

        model =
            { currentPage = pg
            , pageSize = 20
            , options = Api.Loading
            , ampsList = Api.Loading
            , filterHabitat = nonEmpty "habitat"
            , filterMicrobialSource = microbialSource
            , filterQuality = nonEmpty "quality"
            , filterFamily = str "family"
            , filterPepLengthMin = str "pep_length_min"
            , filterPepLengthMax = str "pep_length_max"
            , filterMwMin = str "mw_min"
            , filterMwMax = str "mw_max"
            , filterPiMin = str "pi_min"
            , filterPiMax = str "pi_max"
            , filterChargeMin = str "charge_min"
            , filterChargeMax = str "charge_max"

            -- Expand the advanced section when a deep link sets any of its filters.
            , showAdvancedFilters = microbialSource /= Nothing || List.any ((/=) "") ranges
            , visibleColumns = Set.fromList [ "accession", "family", "sequence", "length" ]
            , downloadStatus = DownloadIdle
            }
    in
    ( model
    , Effect.batch
        [ Api.AvailableOptions.get { onResponse = GotOptions }
        , Api.AmpList.get
            { filters = modelToFilters model pg
            , onResponse = GotAmpsList
            }
        ]
    )


modelToFilters : Model -> Int -> Api.AmpList.Filters
modelToFilters model pg =
    { page = pg
    , pageSize = model.pageSize
    , family =
        if model.filterFamily /= "" then
            Just model.filterFamily

        else
            Nothing
    , habitat = model.filterHabitat
    , microbialSource = model.filterMicrobialSource
    , quality = model.filterQuality
    , pepLengthMin = String.toInt model.filterPepLengthMin
    , pepLengthMax = String.toInt model.filterPepLengthMax
    , mwMin = String.toFloat model.filterMwMin
    , mwMax = String.toFloat model.filterMwMax
    , piMin = String.toFloat model.filterPiMin
    , piMax = String.toFloat model.filterPiMax
    , chargeMin = String.toFloat model.filterChargeMin
    , chargeMax = String.toFloat model.filterChargeMax
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
    | ToggleAdvancedFilters
    | ToggleColumn String
    | DownloadResults DownloadFormat Int
    | GotDownloadData DownloadFormat (Result Http.Error AmpListResponse)


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
            , applyRoute model 0
            )

        GoToPage pg ->
            ( { model | currentPage = pg, ampsList = Api.Loading }
            , applyRoute model pg
            )

        ToggleAdvancedFilters ->
            ( { model | showAdvancedFilters = not model.showAdvancedFilters }, Effect.none )

        ToggleColumn col ->
            ( { model
                | visibleColumns =
                    if Set.member col model.visibleColumns then
                        Set.remove col model.visibleColumns

                    else
                        Set.insert col model.visibleColumns
              }
            , Effect.none
            )

        DownloadResults format totalItem ->
            let
                filters =
                    modelToFilters model 0
            in
            ( { model | downloadStatus = DownloadPreparing format }
            , Api.AmpList.get
                { filters = { filters | pageSize = min totalItem maxExport }
                , onResponse = GotDownloadData format
                }
            )

        GotDownloadData format (Ok response) ->
            let
                download =
                    case format of
                        DownloadTsv ->
                            Export.downloadTsv "ampsphere-browse-data.tsv" (ampsTsv response.data)

                        DownloadFasta ->
                            Export.downloadFasta "ampsphere-browse-data.fasta" (ampsFasta response.data)
            in
            ( { model | downloadStatus = DownloadIdle }
            , Effect.sendCmd download
            )

        GotDownloadData _ (Err _) ->
            ( { model | downloadStatus = DownloadIdle }, Effect.none )


ampsTsv : List AmpSummary -> String
ampsTsv amps =
    Export.tsv
        [ "accession", "family", "sequence", "length", "molecular_weight", "isoelectric_point", "charge", "antifam", "rnacode", "coordinates", "num_genes" ]
        (List.map
            (\a ->
                [ a.accession
                , a.family
                , a.sequence
                , String.fromInt a.length
                , String.fromFloat a.molecularWeight
                , String.fromFloat a.isoelectricPoint
                , String.fromFloat a.charge
                , a.antifam
                , a.rnaCode
                , a.coordinates
                , a.numGenes |> Maybe.map String.fromInt |> Maybe.withDefault ""
                ]
            )
            amps
        )


ampsFasta : List AmpSummary -> String
ampsFasta amps =
    Export.fasta (List.map (\a -> ( a.accession, a.sequence )) amps)


fetchAmps : Model -> Int -> Effect Msg
fetchAmps model pg =
    Api.AmpList.get
        { filters = modelToFilters model pg
        , onResponse = GotAmpsList
        }


{-| Serialize the active filters + page into the URL query (so the view is
bookmarkable / shareable and back-forward works) and fetch the matching page.
Empty filters are omitted, and page 0 is left implicit, to keep URLs tidy.
-}
applyRoute : Model -> Int -> Effect Msg
applyRoute model pg =
    Effect.batch
        [ Effect.pushRoute
            { path = Route.Path.BrowseData
            , query = modelToQuery model pg
            , hash = Nothing
            }
        , fetchAmps model pg
        ]


modelToQuery : Model -> Int -> Dict.Dict String String
modelToQuery model pg =
    [ ( "page"
      , if pg == 0 then
            ""

        else
            String.fromInt pg
      )
    , ( "habitat", Maybe.withDefault "" model.filterHabitat )
    , ( "microbial_source", Maybe.withDefault "" model.filterMicrobialSource )
    , ( "quality", Maybe.withDefault "" model.filterQuality )
    , ( "family", model.filterFamily )
    , ( "pep_length_min", model.filterPepLengthMin )
    , ( "pep_length_max", model.filterPepLengthMax )
    , ( "mw_min", model.filterMwMin )
    , ( "mw_max", model.filterMwMax )
    , ( "pi_min", model.filterPiMin )
    , ( "pi_max", model.filterPiMax )
    , ( "charge_min", model.filterChargeMin )
    , ( "charge_max", model.filterChargeMax )
    ]
        |> List.filter (\( _, v ) -> v /= "")
        |> Dict.fromList


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
                Api.view
                    { loading =
                        Html.div [ class "text-center py-3" ]
                            [ Spinner.spinner [] []
                            , Html.p [ class "text-muted mt-2 small" ] [ Html.text "Loading filters..." ]
                            ]
                    , failure = \_ -> UH.errorAlert "Failed to load filter options."
                    }
                    (\opts ->
                        Html.div []
                            [ viewSelectFilter "Habitat" (List.map (\h -> ( h, h )) opts.habitat) SetHabitat (Maybe.withDefault "" model.filterHabitat)
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
                            , Html.a
                                [ href "#"
                                , class "d-block mb-3 small"
                                , onClick ToggleAdvancedFilters
                                ]
                                [ Html.text
                                    (if model.showAdvancedFilters then
                                        "Hide advanced filters \u{25B4}"

                                     else
                                        "Show advanced filters \u{25BE}"
                                    )
                                ]
                            , if model.showAdvancedFilters then
                                Html.div []
                                    [ viewSelectFilter "Microbial Source" (List.take 50 (List.map (\m -> ( m, m )) opts.microbialSource)) SetMicrobialSource (Maybe.withDefault "" model.filterMicrobialSource)
                                    , viewRangeSlider "Peptide Length" opts.pepLength 0 model.filterPepLengthMin model.filterPepLengthMax SetPepLengthMin SetPepLengthMax
                                    , viewRangeSlider "Molecular Weight" opts.molecularWeight 1 model.filterMwMin model.filterMwMax SetMwMin SetMwMax
                                    , viewRangeSlider "Isoelectric Point" opts.isoelectricPoint 2 model.filterPiMin model.filterPiMax SetPiMin SetPiMax
                                    , viewRangeSlider "Charge at pH 7" opts.chargeAtPH7 2 model.filterChargeMin model.filterChargeMax SetChargeMin SetChargeMax
                                    ]

                              else
                                Html.text ""
                            , Button.button
                                [ Button.primary, Button.block, Button.attrs [ onClick ApplyFilters ] ]
                                [ Html.text "Apply Filters" ]
                            ]
                    )
                    model.options
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
            (Select.item [ value "" ] [ Html.text (if label == "Quality"
                                                    then "All Quality Categories"
                                                    else "All " ++ label ++ "s") ]
                :: List.map
                    (\( val, lbl ) ->
                        Select.item [ value val, selected (val == currentValue) ] [ Html.text lbl ]
                    )
                    options
            )
        ]


viewRangeSlider : String -> Range -> Int -> String -> String -> (String -> Msg) -> (String -> Msg) -> Html Msg
viewRangeSlider label range decimals minVal maxVal toMsgMin toMsgMax =
    let
        currentMin =
            String.toFloat minVal
                |> Maybe.withDefault range.min

        currentMax =
            String.toFloat maxVal
                |> Maybe.withDefault range.max

        stepStr =
            if decimals == 0 then
                "1"

            else
                String.fromFloat (1 / toFloat (10 ^ decimals))

        displayVal v =
            if decimals == 0 then
                String.fromInt (round v)

            else
                Format.float decimals v

        rangeMin =
            String.fromFloat range.min

        rangeMax =
            String.fromFloat range.max
    in
    Form.group []
        [ Form.label [] [ Html.text label ]
        , Html.div [ class "dual-range" ]
            [ Html.div [ class "dual-range-track" ] []
            , Html.input
                [ attribute "type" "range"
                , attribute "min" rangeMin
                , attribute "max" rangeMax
                , attribute "step" stepStr
                , value (String.fromFloat currentMin)
                , onInput toMsgMin
                ]
                []
            , Html.input
                [ attribute "type" "range"
                , attribute "min" rangeMin
                , attribute "max" rangeMax
                , attribute "step" stepStr
                , value (String.fromFloat currentMax)
                , onInput toMsgMax
                ]
                []
            ]
        , Html.div [ class "d-flex justify-content-between" ]
            [ Html.span [ class "small text-muted" ] [ Html.text (displayVal currentMin) ]
            , Html.span [ class "small text-muted" ] [ Html.text (displayVal currentMax) ]
            ]
        ]


allColumns : List ( String, String )
allColumns =
    [ ( "accession", "Accession" )
    , ( "family", "Family" )
    , ( "sequence", "Sequence" )
    , ( "length", "Length" )
    , ( "mw", "MW" )
    , ( "pi", "pI" )
    , ( "charge", "Charge" )
    , ( "antifam", "Antifam" )
    , ( "rnaCode", "RNAcode" )
    , ( "coordinates", "Coordinates" )
    , ( "numGenes", "# Genes" )
    ]


viewDownloadButton : DownloadStatus -> Int -> Html Msg
viewDownloadButton status totalItem =
    let
        preparing =
            status /= DownloadIdle

        note =
            if totalItem > maxExport then
                Html.span [ class "text-muted small mt-1" ]
                    [ Html.text ("first " ++ String.fromInt maxExport ++ " of " ++ String.fromInt totalItem) ]

            else
                Html.text ""

        formatButton format label =
            Button.button
                [ Button.outlineSecondary
                , Button.small
                , Button.disabled (preparing || totalItem == 0)
                , Button.attrs [ class "ml-2", onClick (DownloadResults format totalItem) ]
                ]
                [ Html.text
                    (if status == DownloadPreparing format then
                        "Preparing…"

                     else
                        label
                    )
                ]
    in
    Html.div [ class "text-right" ]
        [ formatButton DownloadTsv "Download TSV"
        , formatButton DownloadFasta "Download FASTA"
        , Html.div [] [ note ]
        ]


viewColumnToggles : Set String -> Html Msg
viewColumnToggles visibleColumns =
    Html.div [ class "mb-3 d-flex flex-wrap align-items-center" ]
        (Html.span [ class "text-muted small mr-2" ] [ Html.text "Columns:" ]
            :: List.map
                (\( key, label ) ->
                    Html.button
                        [ class
                            (if Set.member key visibleColumns then
                                "btn btn-sm btn-outline-primary active mr-1 mb-1"

                             else
                                "btn btn-sm btn-outline-secondary mr-1 mb-1"
                            )
                        , onClick (ToggleColumn key)
                        ]
                        [ Html.text label ]
                )
                allColumns
        )


viewMainContent : Model -> Html Msg
viewMainContent model =
    Api.view
        { loading = UH.spinner "Loading data..."
        , failure = \_ -> UH.errorAlert "Failed to load data."
        }
        (\response ->
            let
                active =
                    allColumns
                        |> List.filter (\( key, _ ) -> Set.member key model.visibleColumns)
            in
            Html.div []
                [ Html.div [ class "d-flex justify-content-between align-items-start mb-3" ]
                    [ Html.p [ class "text-muted mb-0" ]
                        [ Html.text (String.fromInt response.info.totalItem ++ " AMPs found") ]
                    , viewDownloadButton model.downloadStatus response.info.totalItem
                    ]
                , viewColumnToggles model.visibleColumns
                , Table.table
                    { options = [ Table.striped, Table.hover, Table.responsive, Table.small ]
                    , thead =
                        Table.simpleThead
                            (List.map (\( _, label ) -> Table.th [] [ Html.text label ]) active)
                    , tbody =
                        Table.tbody []
                            (List.map (viewAmpRow active) response.data)
                    }
                , viewPagination model response.info
                ]
        )
        model.ampsList


viewAmpRow : List ( String, String ) -> AmpSummary -> Table.Row Msg
viewAmpRow activeColumns amp =
    Table.tr []
        (List.map (\( key, _ ) -> ampCell key amp) activeColumns)


ampCell : String -> AmpSummary -> Table.Cell Msg
ampCell key amp =
    case key of
        "accession" ->
            Table.td []
                [ Html.a [ Route.Path.href (Route.Path.Amp_Accession_ { accession = amp.accession }) ]
                    [ Html.text amp.accession ]
                ]

        "family" ->
            Table.td []
                [ Html.a [ Route.Path.href (Route.Path.Family_Accession_ { accession = amp.family }) ]
                    [ Html.text amp.family ]
                ]

        "sequence" ->
            Table.td [ Table.cellAttr (class "text-monospace small"), Table.cellAttr (style "word-break" "break-all") ]
                [ Html.text amp.sequence ]

        "length" ->
            Table.td [] [ Html.text (String.fromInt amp.length) ]

        "mw" ->
            Table.td [] [ Html.text (Format.float 1 amp.molecularWeight) ]

        "pi" ->
            Table.td [] [ Html.text (Format.float 2 amp.isoelectricPoint) ]

        "charge" ->
            Table.td [] [ Html.text (Format.float 2 amp.charge) ]

        "antifam" ->
            Table.td [] [ Html.text amp.antifam ]

        "rnaCode" ->
            Table.td [] [ Html.text amp.rnaCode ]

        "coordinates" ->
            Table.td [] [ Html.text amp.coordinates ]

        "numGenes" ->
            Table.td []
                [ Html.text
                    (amp.numGenes
                        |> Maybe.map String.fromInt
                        |> Maybe.withDefault "-"
                    )
                ]

        _ ->
            Table.td [] []


viewPagination : Model -> Api.AmpList.PageInfo -> Html Msg
viewPagination model info =
    Pagination.view
        { current = model.currentPage
        , total = info.totalPage
        , toMsg = GoToPage
        }
