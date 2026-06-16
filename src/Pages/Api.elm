module Pages.Api exposing (Model, Msg, page)

import Bootstrap.Card as Card
import Bootstrap.Card.Block as Block
import Bootstrap.Grid as Grid
import Bootstrap.Grid.Col as Col
import Effect exposing (Effect)
import Html exposing (Html)
import Html.Attributes exposing (class, href)
import Layouts
import Page exposing (Page)
import Route exposing (Route)
import Shared
import View exposing (View)


page : Shared.Model -> Route () -> Page Model Msg
page shared route =
    Page.new
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }
        |> Page.withLayout (always <| Layouts.Default {})



-- MODEL


type alias Model =
    {}


init : () -> ( Model, Effect Msg )
init _ =
    ( {}, Effect.none )



-- UPDATE


type Msg
    = NoOp


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    ( model, Effect.none )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- VIEW


baseUrl : String
baseUrl =
    "https://ampsphere-api.big-data-biology.org/v1"


view : Model -> View Msg
view model =
    { title = "API"
    , body =
        [ Grid.row []
            [ Grid.col [ Col.md8, Col.attrs [ class "mx-auto" ] ]
                [ Html.h1 [ class "mb-4" ] [ Html.text "AMPSphere API" ]
                , apiCard "Overview"
                    [ Html.p []
                        [ Html.text "All AMPSphere data is available through a public, read-only REST API. No authentication or API key is required. Responses are returned as JSON." ]
                    , Html.p [ class "mb-0" ]
                        [ Html.text "The base URL for all endpoints is:" ]
                    , Html.pre [ class "mt-2 mb-0" ]
                        [ Html.code [] [ Html.text baseUrl ] ]
                    ]
                , apiCard "Interactive Documentation"
                    [ Html.p [ class "mb-0" ]
                        [ Html.text "The API is built with FastAPI and ships with interactive, auto-generated documentation where you can explore and try out every endpoint. See the "
                        , Html.a [ href (baseUrl ++ "/docs") ] [ Html.text "Swagger UI" ]
                        , Html.text " or the "
                        , Html.a [ href (baseUrl ++ "/redoc") ] [ Html.text "ReDoc" ]
                        , Html.text " documentation. The raw OpenAPI schema is available at "
                        , Html.a [ href (baseUrl ++ "/openapi.json") ] [ Html.text "/openapi.json" ]
                        , Html.text "."
                        ]
                    ]
                , apiCard "Peptides"
                    [ endpointTable
                        [ ( "GET", "/amps", "List AMPs with pagination and optional filters (see below)." )
                        , ( "GET", "/amps/{accession}", "Metadata for a single AMP, e.g. /amps/AMP10.000_000." )
                        , ( "GET", "/amps/{accession}/features", "Computed sequence features for an AMP." )
                        , ( "GET", "/amps/{accession}/distributions", "Geographic, habitat and microbial-source distributions." )
                        , ( "GET", "/amps/{accession}/metadata", "Per-sample metadata (paginated with page/page_size)." )
                        , ( "GET", "/amps/{accession}/coprediction", "Co-predicted AMPs from other prediction tools." )
                        ]
                    , Html.p [ class "mb-1 mt-3" ]
                        [ Html.strong [] [ Html.text "Query parameters for /amps:" ] ]
                    , Html.p [ class "mb-0" ]
                        [ Html.text "Pagination via "
                        , Html.code [] [ Html.text "page" ]
                        , Html.text " (0-indexed) and "
                        , Html.code [] [ Html.text "page_size" ]
                        , Html.text ". Filters: "
                        , Html.code [] [ Html.text "family" ]
                        , Html.text ", "
                        , Html.code [] [ Html.text "habitat" ]
                        , Html.text ", "
                        , Html.code [] [ Html.text "microbial_source" ]
                        , Html.text ", "
                        , Html.code [] [ Html.text "quality" ]
                        , Html.text ", and range filters "
                        , Html.code [] [ Html.text "pep_length__gte/__lte" ]
                        , Html.text ", "
                        , Html.code [] [ Html.text "molecular_weight__gte/__lte" ]
                        , Html.text ", "
                        , Html.code [] [ Html.text "isoelectric_point__gte/__lte" ]
                        , Html.text " and "
                        , Html.code [] [ Html.text "charge__gte/__lte" ]
                        , Html.text "."
                        ]
                    ]
                , apiCard "Families"
                    [ endpointTable
                        [ ( "GET", "/families/{accession}", "Metadata for a SPHERE family, e.g. /families/SPHERE-III.000_000." )
                        , ( "GET", "/families/{accession}/features", "Per-AMP features for all members of the family." )
                        , ( "GET", "/families/{accession}/downloads", "Links to downloadable family artifacts (alignments, HMM, trees)." )
                        ]
                    ]
                , apiCard "Search"
                    [ endpointTable
                        [ ( "GET", "/search/text?query=...", "Full-text search across AMP and family metadata (paginated)." )
                        , ( "GET", "/search/mmseqs?query=...", "Sequence search against AMPSphere using MMseqs2." )
                        , ( "GET", "/search/hmmer?query=...", "Profile search against AMPSphere using HMMER." )
                        ]
                    ]
                , apiCard "Statistics & Options"
                    [ endpointTable
                        [ ( "GET", "/statistics", "Global database counts (number of AMPs, families, metagenomes, etc.)." )
                        , ( "GET", "/all_available_options", "All available filter values (habitats, microbial sources, qualities)." )
                        ]
                    ]
                , apiCard "Example"
                    [ Html.p [] [ Html.text "Fetch a single AMP with curl:" ]
                    , Html.pre [ class "mb-0" ]
                        [ Html.code [] [ Html.text ("curl " ++ baseUrl ++ "/amps/AMP10.000_000") ] ]
                    ]
                , apiCard "Citation"
                    [ Html.p [ class "mb-0" ]
                        [ Html.text "If you use the AMPSphere API in your research, please cite Santos-Júnior, Torres, Duan "
                        , Html.em [] [ Html.text "et al." ]
                        , Html.text ", "
                        , Html.em [] [ Html.text "Cell" ]
                        , Html.text " 187, 3761–3778 (2024), "
                        , Html.a [ href "https://doi.org/10.1016/j.cell.2024.05.013" ]
                            [ Html.text "https://doi.org/10.1016/j.cell.2024.05.013" ]
                        , Html.text "."
                        ]
                    ]
                ]
            ]
        ]
    }


apiCard : String -> List (Html Msg) -> Html Msg
apiCard title content =
    Card.config [ Card.attrs [ class "mb-3" ] ]
        |> Card.headerH5 [] [ Html.text title ]
        |> Card.block []
            [ Block.custom <| Html.div [] content ]
        |> Card.view


endpointTable : List ( String, String, String ) -> Html Msg
endpointTable rows =
    Html.table [ class "table table-sm mb-0" ]
        [ Html.thead []
            [ Html.tr []
                [ Html.th [] [ Html.text "Method" ]
                , Html.th [] [ Html.text "Endpoint" ]
                , Html.th [] [ Html.text "Description" ]
                ]
            ]
        , Html.tbody [] (List.map endpointRow rows)
        ]


endpointRow : ( String, String, String ) -> Html Msg
endpointRow ( method, endpoint, description ) =
    Html.tr []
        [ Html.td [] [ Html.code [] [ Html.text method ] ]
        , Html.td [] [ Html.code [] [ Html.text endpoint ] ]
        , Html.td [] [ Html.text description ]
        ]
