module Api.FamilyDownloads exposing (FamilyDownloads, get)

import Api.Endpoint as Endpoint
import Effect exposing (Effect)
import Http
import Json.Decode as Decode exposing (Decoder)


type alias FamilyDownloads =
    { alignment : String
    , sequences : String
    , hmmProfile : String
    , treeFigure : String
    , treeNwk : String
    }


decoder : Decoder FamilyDownloads
decoder =
    Decode.map5 FamilyDownloads
        (Decode.field "alignment" Decode.string)
        (Decode.field "sequences" Decode.string)
        (Decode.field "hmm_profile" Decode.string)
        (Decode.field "tree_figure" Decode.string)
        (Decode.field "tree_nwk" Decode.string)


get : { accession : String, onResponse : Result Http.Error FamilyDownloads -> msg } -> Effect msg
get options =
    Effect.apiGet
        { endpoint = Endpoint.url [ "families", options.accession, "downloads" ] []
        , decoder = decoder
        , onResponse = options.onResponse
        }
