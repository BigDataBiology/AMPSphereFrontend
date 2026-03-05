module Api.Endpoint exposing (url)

{-| URL builder helper for API endpoints.
-}

import Url.Builder


{-| Build an API endpoint URL from path segments and query parameters.
-}
url : List String -> List Url.Builder.QueryParameter -> String
url paths queryParams =
    "/" ++ String.join "/" paths ++ Url.Builder.toQuery queryParams
