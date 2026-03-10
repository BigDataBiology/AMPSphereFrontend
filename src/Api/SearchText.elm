module Api.SearchText exposing (SearchResult, SearchResults, get)

import Effect exposing (Effect)
import Http
import Json.Decode as Decode exposing (Decoder)
import Url.Builder


type alias SearchResult =
    { accession : String
    , sequence : String
    , family : String
    , numGenes : Int
    , quality : String
    }


type alias SearchResults =
    { results : List SearchResult
    , totalCount : Int
    }


decoder : Decoder SearchResults
decoder =
    Decode.map2 SearchResults
        (Decode.field "results" (Decode.list resultDecoder))
        (Decode.field "total_count" Decode.int)


resultDecoder : Decoder SearchResult
resultDecoder =
    Decode.map5 SearchResult
        (Decode.field "accession" Decode.string)
        (Decode.field "sequence" Decode.string)
        (Decode.field "family" Decode.string)
        (Decode.field "num_genes" Decode.int)
        (Decode.field "quality" Decode.string)


get :
    { query : String
    , page : Int
    , pageSize : Int
    , onResponse : Result Http.Error SearchResults -> msg
    }
    -> Effect msg
get options =
    Effect.apiGet
        { endpoint =
            Url.Builder.absolute [ "search", "text" ]
                [ Url.Builder.string "query" options.query
                , Url.Builder.int "page" options.page
                , Url.Builder.int "page_size" options.pageSize
                ]
        , decoder = decoder
        , onResponse = options.onResponse
        }
