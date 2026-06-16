module Api.AmpList exposing (AmpSummary, AmpListResponse, Filters, PageInfo, get)

import Api.Endpoint as Endpoint
import Effect exposing (Effect)
import Http
import Json.Decode as Decode exposing (Decoder)
import Url.Builder


type alias PageInfo =
    { currentPage : Int
    , pageSize : Int
    , totalPage : Int
    , totalItem : Int
    }


type alias AmpSummary =
    { accession : String
    , sequence : String
    , family : String
    , length : Int
    , molecularWeight : Float
    , isoelectricPoint : Float
    , charge : Float
    , antifam : String
    , rnaCode : String
    , coordinates : String
    , numGenes : Maybe Int
    }


type alias AmpListResponse =
    { info : PageInfo
    , data : List AmpSummary
    }


decoder : Decoder AmpListResponse
decoder =
    Decode.map2 AmpListResponse
        (Decode.field "info" pageInfoDecoder)
        (Decode.field "data" (Decode.list ampSummaryDecoder))


pageInfoDecoder : Decoder PageInfo
pageInfoDecoder =
    Decode.map4 PageInfo
        (Decode.field "currentPage" Decode.int)
        (Decode.field "pageSize" Decode.int)
        (Decode.field "totalPage" Decode.int)
        (Decode.field "totalItem" Decode.int)


ampSummaryDecoder : Decoder AmpSummary
ampSummaryDecoder =
    Decode.succeed AmpSummary
        |> decodeAndMap (Decode.field "accession" Decode.string)
        |> decodeAndMap (Decode.field "sequence" Decode.string)
        |> decodeAndMap (Decode.field "family" Decode.string)
        |> decodeAndMap (Decode.field "length" Decode.int)
        |> decodeAndMap (Decode.field "molecular_weight" Decode.float)
        |> decodeAndMap (Decode.field "isoelectric_point" Decode.float)
        |> decodeAndMap (Decode.field "charge" Decode.float)
        |> decodeAndMap (Decode.field "Antifam" Decode.string)
        |> decodeAndMap (Decode.field "RNAcode" Decode.string)
        |> decodeAndMap (Decode.field "coordinates" Decode.string)
        |> decodeAndMap (Decode.field "num_genes" (Decode.nullable Decode.int))


decodeAndMap : Decoder a -> Decoder (a -> b) -> Decoder b
decodeAndMap =
    Decode.map2 (|>)


type alias Filters =
    { page : Int
    , pageSize : Int
    , family : Maybe String
    , habitat : Maybe String
    , microbialSource : Maybe String
    , quality : Maybe String
    , pepLengthMin : Maybe Int
    , pepLengthMax : Maybe Int
    , mwMin : Maybe Float
    , mwMax : Maybe Float
    , piMin : Maybe Float
    , piMax : Maybe Float
    , chargeMin : Maybe Float
    , chargeMax : Maybe Float
    }


get : { filters : Filters, onResponse : Result Http.Error AmpListResponse -> msg } -> Effect msg
get options =
    let
        f =
            options.filters

        requiredParams =
            [ Url.Builder.int "page" f.page
            , Url.Builder.int "page_size" f.pageSize
            ]

        optionalParams =
            List.filterMap identity
                [ Maybe.map (Url.Builder.string "family") f.family
                , Maybe.map (Url.Builder.string "habitat") f.habitat
                , Maybe.map (Url.Builder.string "microbial_source") f.microbialSource
                , Maybe.map (Url.Builder.string "quality") f.quality
                , Maybe.map (Url.Builder.int "pep_length__gte") f.pepLengthMin
                , Maybe.map (Url.Builder.int "pep_length__lte") f.pepLengthMax
                , Maybe.map (Url.Builder.string "molecular_weight__gte" << String.fromFloat) f.mwMin
                , Maybe.map (Url.Builder.string "molecular_weight__lte" << String.fromFloat) f.mwMax
                , Maybe.map (Url.Builder.string "isoelectric_point__gte" << String.fromFloat) f.piMin
                , Maybe.map (Url.Builder.string "isoelectric_point__lte" << String.fromFloat) f.piMax
                , Maybe.map (Url.Builder.string "charge__gte" << String.fromFloat) f.chargeMin
                , Maybe.map (Url.Builder.string "charge__lte" << String.fromFloat) f.chargeMax
                ]

        allParams =
            requiredParams ++ optionalParams
    in
    Effect.apiGet
        { endpoint = Endpoint.url [ "amps" ] allParams
        , decoder = decoder
        , onResponse = options.onResponse
        }
