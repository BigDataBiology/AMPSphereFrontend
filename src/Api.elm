module Api exposing (Data(..), view)

import Html exposing (Html)
import Http


type Data value
    = NotAsked
    | Loading
    | Success value
    | Failure Http.Error


{-| Render a piece of remote data, collapsing the usual
`NotAsked | Loading | Failure | Success` ladder into one call.

`NotAsked` renders nothing; callers supply the `loading` and `failure` views
(see `Util.Html.spinner` / `Util.Html.errorAlert`) and a function for the success
case.

-}
view :
    { loading : Html msg, failure : Http.Error -> Html msg }
    -> (value -> Html msg)
    -> Data value
    -> Html msg
view handlers onSuccess data =
    case data of
        NotAsked ->
            Html.text ""

        Loading ->
            handlers.loading

        Failure err ->
            handlers.failure err

        Success value ->
            onSuccess value
