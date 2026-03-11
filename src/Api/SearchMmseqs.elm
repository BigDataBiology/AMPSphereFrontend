module Api.SearchMmseqs exposing (Hit, SearchResults, get)

import Effect exposing (Effect)
import Http
import Json.Decode as Decode exposing (Decoder)
import Url.Builder


type alias Hit =
    { targetId : String
    , seqIdentity : Float
    , alnLength : Int
    , numMismatches : Int
    , numGapOpenings : Int
    , queryStart : Int
    , queryEnd : Int
    , targetStart : Int
    , targetEnd : Int
    , eValue : Float
    , bitScore : Float
    , querySequenceAligned : String
    , targetSequenceAligned : String
    }


type alias SearchResults =
    List Hit


decoder : Decoder SearchResults
decoder =
    Decode.list hitDecoder


hitDecoder : Decoder Hit
hitDecoder =
    Decode.succeed Hit
        |> decodeAndMap (Decode.field "target_identifier" Decode.string)
        |> decodeAndMap (Decode.field "sequence_identity" Decode.float)
        |> decodeAndMap (Decode.field "alignment_length" Decode.int)
        |> decodeAndMap (Decode.field "number_mismatches" Decode.int)
        |> decodeAndMap (Decode.field "number_gap_openings" Decode.int)
        |> decodeAndMap (Decode.field "domain_start_position_query" Decode.int)
        |> decodeAndMap (Decode.field "domain_end_position_query" Decode.int)
        |> decodeAndMap (Decode.field "domain_start_position_target" Decode.int)
        |> decodeAndMap (Decode.field "domain_end_position_target" Decode.int)
        |> decodeAndMap (Decode.field "E_value" Decode.float)
        |> decodeAndMap (Decode.field "bit_score" Decode.float)
        |> decodeAndMap (Decode.field "seq_query" Decode.string)
        |> decodeAndMap (Decode.field "seq_target" Decode.string)


decodeAndMap : Decoder a -> Decoder (a -> b) -> Decoder b
decodeAndMap =
    Decode.map2 (|>)


get :
    { query : String
    , onResponse : Result Http.Error SearchResults -> msg
    }
    -> Effect msg
get options =
    Effect.apiGet
        { endpoint = Url.Builder.absolute [ "search", "mmseqs" ] [ Url.Builder.string "query" options.query ]
        , decoder = decoder
        , onResponse = options.onResponse
        }
