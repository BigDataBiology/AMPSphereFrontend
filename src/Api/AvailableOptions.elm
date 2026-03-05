module Api.AvailableOptions exposing (AvailableOptions, Range, get)

import Effect exposing (Effect)
import Http
import Json.Decode as Decode exposing (Decoder)


type alias Range =
    { min : Float
    , max : Float
    }


type alias AvailableOptions =
    { quality : List String
    , habitat : List String
    , microbialSource : List String
    , pepLength : Range
    , molecularWeight : Range
    , isoelectricPoint : Range
    , chargeAtPH7 : Range
    }


decoder : Decoder AvailableOptions
decoder =
    Decode.map7 AvailableOptions
        (Decode.field "quality" (Decode.list Decode.string))
        (Decode.field "habitat" (Decode.list Decode.string))
        (Decode.field "microbial_source" (Decode.list Decode.string))
        (Decode.field "pep_length" rangeDecoder)
        (Decode.field "molecular_weight" rangeDecoder)
        (Decode.field "isoelectric_point" rangeDecoder)
        (Decode.field "charge_at_pH_7" rangeDecoder)


rangeDecoder : Decoder Range
rangeDecoder =
    Decode.map2 Range
        (Decode.field "min" Decode.float)
        (Decode.field "max" Decode.float)


get : { onResponse : Result Http.Error AvailableOptions -> msg } -> Effect msg
get options =
    Effect.apiGet
        { endpoint = "/all_available_options"
        , decoder = decoder
        , onResponse = options.onResponse
        }
