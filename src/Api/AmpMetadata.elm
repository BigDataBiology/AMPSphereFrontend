module Api.AmpMetadata exposing (MetadataEntry, MetadataResponse, PageInfo, get)

import Effect exposing (Effect)
import Http
import Json.Decode as Decode exposing (Decoder)


type alias PageInfo =
    { currentPage : Int
    , pageSize : Int
    , totalPage : Int
    , totalItem : Int
    }


type alias MetadataEntry =
    { amp : String
    , gmscAccession : String
    , sample : String
    , specI : String
    , isMetagenomic : Bool
    , geographicLocation : String
    , generalEnvoName : String
    , microbialSourceD : String
    , microbialSourceP : String
    , microbialSourceC : String
    , microbialSourceO : String
    , microbialSourceF : String
    , microbialSourceG : String
    , microbialSourceS : String
    }


type alias MetadataResponse =
    { info : PageInfo
    , data : List MetadataEntry
    }


decoder : Decoder MetadataResponse
decoder =
    Decode.map2 MetadataResponse
        (Decode.field "info" pageInfoDecoder)
        (Decode.field "data" (Decode.list entryDecoder))


pageInfoDecoder : Decoder PageInfo
pageInfoDecoder =
    Decode.map4 PageInfo
        (Decode.field "currentPage" Decode.int)
        (Decode.field "pageSize" Decode.int)
        (Decode.field "totalPage" Decode.int)
        (Decode.field "totalItem" Decode.int)


entryDecoder : Decoder MetadataEntry
entryDecoder =
    Decode.succeed MetadataEntry
        |> decodeAndMap (Decode.field "AMP" Decode.string)
        |> decodeAndMap (Decode.field "GMSC_accession" Decode.string)
        |> decodeAndMap (Decode.field "sample" Decode.string)
        |> decodeAndMap (Decode.field "specI" Decode.string)
        |> decodeAndMap (Decode.field "is_metagenomic" Decode.bool)
        |> decodeAndMap (optionalString "geographic_location")
        |> decodeAndMap (optionalString "general_envo_name")
        |> decodeAndMap (optionalString "microbial_source_d")
        |> decodeAndMap (optionalString "microbial_source_p")
        |> decodeAndMap (optionalString "microbial_source_c")
        |> decodeAndMap (optionalString "microbial_source_o")
        |> decodeAndMap (optionalString "microbial_source_f")
        |> decodeAndMap (optionalString "microbial_source_g")
        |> decodeAndMap (optionalString "microbial_source_s")


decodeAndMap : Decoder a -> Decoder (a -> b) -> Decoder b
decodeAndMap =
    Decode.map2 (|>)


optionalString : String -> Decoder String
optionalString field =
    Decode.oneOf
        [ Decode.field field Decode.string
        , Decode.field field (Decode.null "")
        , Decode.succeed ""
        ]


get :
    { accession : String
    , page : Int
    , pageSize : Int
    , onResponse : Result Http.Error MetadataResponse -> msg
    }
    -> Effect msg
get options =
    Effect.apiGet
        { endpoint =
            "/amps/"
                ++ options.accession
                ++ "/metadata?page="
                ++ String.fromInt options.page
                ++ "&page_size="
                ++ String.fromInt options.pageSize
        , decoder = decoder
        , onResponse = options.onResponse
        }
