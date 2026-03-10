module Api.SearchHmmer exposing (Hit, SearchResults, get)

import Effect exposing (Effect)
import Http
import Json.Decode as Decode exposing (Decoder)
import Url.Builder


type alias Hit =
    { targetName : String
    , accession : String
    , eValue : Float
    , score : Float
    , bias : Float
    , description : String
    }


type alias SearchResults =
    List Hit


decoder : Decoder SearchResults
decoder =
    Decode.list hitDecoder


hitDecoder : Decoder Hit
hitDecoder =
    Decode.map6 Hit
        (Decode.field "target_name" Decode.string)
        (Decode.field "accession" Decode.string)
        (Decode.field "e_value" Decode.float)
        (Decode.field "score" Decode.float)
        (Decode.field "bias" Decode.float)
        (Decode.field "description" Decode.string)


get :
    { query : String
    , onResponse : Result Http.Error SearchResults -> msg
    }
    -> Effect msg
get options =
    Effect.apiGet
        { endpoint = Url.Builder.absolute [ "search", "hmmer" ] [ Url.Builder.string "query" options.query ]
        , decoder = decoder
        , onResponse = options.onResponse
        }
