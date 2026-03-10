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
        |> decodeAndMap (Decode.field "target_id" Decode.string)
        |> decodeAndMap (Decode.field "seq_identity" Decode.float)
        |> decodeAndMap (Decode.field "aln_length" Decode.int)
        |> decodeAndMap (Decode.field "num_mismatches" Decode.int)
        |> decodeAndMap (Decode.field "num_gap_openings" Decode.int)
        |> decodeAndMap (Decode.field "query_start" Decode.int)
        |> decodeAndMap (Decode.field "query_end" Decode.int)
        |> decodeAndMap (Decode.field "target_start" Decode.int)
        |> decodeAndMap (Decode.field "target_end" Decode.int)
        |> decodeAndMap (Decode.field "e_value" Decode.float)
        |> decodeAndMap (Decode.field "bit_score" Decode.float)
        |> decodeAndMap (Decode.field "query_sequence_aligned" Decode.string)
        |> decodeAndMap (Decode.field "target_sequence_aligned" Decode.string)


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
