module Api.Family exposing (Downloads, Family, get)

import Api.AmpDistributions exposing (Distributions)
import Api.Endpoint as Endpoint
import Effect exposing (Effect)
import Http
import Json.Decode as Decode exposing (Decoder)


type alias Downloads =
    { alignment : String
    , sequences : String
    , hmmProfile : String
    , treeFigure : String
    , treeNwk : String
    }


type alias Family =
    { accession : String
    , consensusSequence : String
    , numAmps : Int
    , downloads : Downloads
    , associatedAmps : List String
    , distributions : Distributions
    }


decoder : Decoder Family
decoder =
    Decode.map6 Family
        (Decode.field "accession" Decode.string)
        (Decode.field "consensus_sequence" Decode.string)
        (Decode.field "num_amps" Decode.int)
        (Decode.field "downloads" downloadsDecoder)
        (Decode.field "associated_amps" (Decode.list Decode.string))
        (Decode.field "distributions" Api.AmpDistributions.distributionsDecoder)


downloadsDecoder : Decoder Downloads
downloadsDecoder =
    Decode.map5 Downloads
        (Decode.field "alignment" Decode.string)
        (Decode.field "sequences" Decode.string)
        (Decode.field "hmm_profile" Decode.string)
        (Decode.field "tree_figure" Decode.string)
        (Decode.field "tree_nwk" Decode.string)


get : { accession : String, onResponse : Result Http.Error Family -> msg } -> Effect msg
get options =
    Effect.apiGet
        { endpoint = Endpoint.url [ "families", options.accession ] []
        , decoder = decoder
        , onResponse = options.onResponse
        }
