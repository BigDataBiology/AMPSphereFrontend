module Api.Statistics exposing (Statistics, get)

import Api.Endpoint as Endpoint
import Effect exposing (Effect)
import Http
import Json.Decode as Decode exposing (Decoder)


type alias Statistics =
    { numAmps : Int
    , numFamilies : Int
    , numGenomes : Int
    , numGenes : Int
    , numHabitats : Int
    , numMetagenomes : Int
    }


decoder : Decoder Statistics
decoder =
    Decode.map6 Statistics
        (Decode.field "num_amps" Decode.int)
        (Decode.field "num_families" Decode.int)
        (Decode.field "num_genomes" Decode.int)
        (Decode.field "num_genes" Decode.int)
        (Decode.field "num_habitats" Decode.int)
        (Decode.field "num_metagenomes" Decode.int)


get : { onResponse : Result Http.Error Statistics -> msg } -> Effect msg
get options =
    Effect.apiGet
        { endpoint = Endpoint.url [ "statistics" ] []
        , decoder = decoder
        , onResponse = options.onResponse
        }
