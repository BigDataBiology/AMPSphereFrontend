module Api.AmpDistributions exposing (Distributions, GeoData, LabeledData, distributionsDecoder, get)

import Api.Endpoint as Endpoint
import Effect exposing (Effect)
import Http
import Json.Decode as Decode exposing (Decoder)


type alias GeoData =
    { lat : List Float
    , lon : List Float
    , size : List Float
    , colors : List String
    }


type alias LabeledData =
    { labels : List String
    , values : List Float
    }


type alias Distributions =
    { geo : GeoData
    , habitat : LabeledData
    , microbialSource : LabeledData
    }


distributionsDecoder : Decoder Distributions
distributionsDecoder =
    Decode.map3 Distributions
        (Decode.field "geo" geoDecoder)
        (Decode.field "habitat" labeledDecoder)
        (Decode.field "microbial_source" labeledDecoder)


geoDecoder : Decoder GeoData
geoDecoder =
    Decode.map4 GeoData
        (Decode.field "lat" (Decode.list Decode.float))
        (Decode.field "lon" (Decode.list Decode.float))
        (Decode.field "size" (Decode.list Decode.float))
        (Decode.field "colors" (Decode.list Decode.string))


labeledDecoder : Decoder LabeledData
labeledDecoder =
    Decode.map2 LabeledData
        (Decode.field "labels" (Decode.list Decode.string))
        (Decode.field "values" (Decode.list Decode.float))


get : { accession : String, onResponse : Result Http.Error Distributions -> msg } -> Effect msg
get options =
    Effect.apiGet
        { endpoint = Endpoint.url [ "amps", options.accession, "distributions" ] []
        , decoder = distributionsDecoder
        , onResponse = options.onResponse
        }
