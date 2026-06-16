module Api.AmpCoprediction exposing (CopredictionScore, get)

import Api.Endpoint as Endpoint
import Effect exposing (Effect)
import Http
import Json.Decode as Decode exposing (Decoder)


type alias CopredictionScore =
    { predictor : String
    , value : Float
    }


decoder : Decoder (List CopredictionScore)
decoder =
    Decode.list scoreDecoder


scoreDecoder : Decoder CopredictionScore
scoreDecoder =
    Decode.map2 CopredictionScore
        (Decode.field "predictor" Decode.string)
        (Decode.field "value" Decode.float)


get : { accession : String, onResponse : Result Http.Error (List CopredictionScore) -> msg } -> Effect msg
get options =
    Effect.apiGet
        { endpoint = Endpoint.url [ "amps", options.accession, "coprediction" ] []
        , decoder = decoder
        , onResponse = options.onResponse
        }
