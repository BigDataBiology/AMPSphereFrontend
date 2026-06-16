module Api.Amp exposing (Amp, SecondaryStructure, get)

import Api.Endpoint as Endpoint
import Effect exposing (Effect)
import Http
import Json.Decode as Decode exposing (Decoder)


type alias SecondaryStructure =
    { helix : Float
    , turn : Float
    , sheet : Float
    }


type alias Amp =
    { accession : String
    , sequence : String
    , family : String
    , length : Int
    , molecularWeight : Float
    , isoelectricPoint : Float
    , charge : Float
    , aromaticity : Float
    , instabilityIndex : Float
    , gravy : Float
    , antifam : String
    , rnaCode : String
    , metaproteomes : String
    , metatranscriptomes : String
    , coordinates : String
    , numGenes : Maybe Int
    , secondaryStructure : SecondaryStructure
    }


decoder : Decoder Amp
decoder =
    Decode.succeed Amp
        |> decodeAndMap (Decode.field "accession" Decode.string)
        |> decodeAndMap (Decode.field "sequence" Decode.string)
        |> decodeAndMap (Decode.field "family" Decode.string)
        |> decodeAndMap (Decode.field "length" Decode.int)
        |> decodeAndMap (Decode.field "molecular_weight" Decode.float)
        |> decodeAndMap (Decode.field "isoelectric_point" Decode.float)
        |> decodeAndMap (Decode.field "charge" Decode.float)
        |> decodeAndMap (Decode.field "aromaticity" Decode.float)
        |> decodeAndMap (Decode.field "instability_index" Decode.float)
        |> decodeAndMap (Decode.field "gravy" Decode.float)
        |> decodeAndMap (Decode.field "Antifam" Decode.string)
        |> decodeAndMap (Decode.field "RNAcode" Decode.string)
        |> decodeAndMap (Decode.field "metaproteomes" Decode.string)
        |> decodeAndMap (Decode.field "metatranscriptomes" Decode.string)
        |> decodeAndMap (Decode.field "coordinates" Decode.string)
        |> decodeAndMap (Decode.field "num_genes" (Decode.nullable Decode.int))
        |> decodeAndMap (Decode.field "secondary_structure" secondaryStructureDecoder)


secondaryStructureDecoder : Decoder SecondaryStructure
secondaryStructureDecoder =
    Decode.map3 SecondaryStructure
        (Decode.field "helix" Decode.float)
        (Decode.field "turn" Decode.float)
        (Decode.field "sheet" Decode.float)


decodeAndMap : Decoder a -> Decoder (a -> b) -> Decoder b
decodeAndMap =
    Decode.map2 (|>)


get : { accession : String, onResponse : Result Http.Error Amp -> msg } -> Effect msg
get options =
    Effect.apiGet
        { endpoint = Endpoint.url [ "amps", options.accession ] []
        , decoder = decoder
        , onResponse = options.onResponse
        }
