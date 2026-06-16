module Api.Endpoint exposing (url)

{-| URL builder helper for API endpoints.
-}

import Url.Builder


{-| Build an API endpoint URL from path segments and query parameters.

Path segments are percent-encoded, so callers can pass raw values (e.g. an
accession) without worrying about stray spaces or slashes breaking the request.

-}
url : List String -> List Url.Builder.QueryParameter -> String
url paths queryParams =
    Url.Builder.absolute paths queryParams
