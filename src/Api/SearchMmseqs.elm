module Api.SearchMmseqs exposing (Hit, SearchResults, get)

import Effect exposing (Effect)
import Http
import Json.Decode as Decode exposing (Decoder)
import Url.Builder


type alias Hit =
    { queryId : String
    , targetId : String
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
    , queryAligned : String
    , targetAligned : String
    , matchPattern : String
    }


type alias SearchResults =
    List Hit


decoder : Decoder SearchResults
decoder =
    Decode.list hitDecoder


hitDecoder : Decoder Hit
hitDecoder =
    Decode.succeed Hit
        |> decodeAndMap (Decode.field "query_identifier" Decode.string)
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
        |> decodeAndMap (strippedAlnField 0)
        |> decodeAndMap (strippedAlnField 2)
        |> decodeAndMap (strippedAlnField 1)


{-| Decode alignment_strings[idx] with the position prefix stripped.
Some MMseqs2 results include a leading "N " position prefix (e.g. "1 GRVIGK...")
in all three alignment strings. We find the prefix length from string[0]
(first non-alpha character count) and drop the same number of chars from
string[idx] so that query, target, and match pattern always align correctly.
-}
strippedAlnField : Int -> Decoder String
strippedAlnField idx =
    Decode.field "alignment_strings"
        (Decode.map2
            (\queryStr targetStr ->
                let
                    prefixLen =
                        String.toList queryStr
                            |> List.foldl
                                (\c ( found, n ) ->
                                    if found then
                                        ( True, n )

                                    else if Char.isAlpha c || c == '-' then
                                        ( True, n )

                                    else
                                        ( False, n + 1 )
                                )
                                ( False, 0 )
                            |> Tuple.second
                in
                String.dropLeft prefixLen targetStr
            )
            (Decode.index 0 Decode.string)
            (Decode.index idx Decode.string)
        )


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
