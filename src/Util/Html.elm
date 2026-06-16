module Util.Html exposing (errorAlert, onClickPreventDefault, spinner)

{-| Small shared view helpers that were previously duplicated across pages.
-}

import Bootstrap.Alert as Alert
import Bootstrap.Spinner as Spinner
import Html exposing (Html)
import Html.Attributes exposing (class)
import Html.Events
import Json.Decode


{-| `onClick` that also prevents the default action.

Needed for `<a href="#">` action links so `Browser.application` doesn't intercept
the click and push `"#"` onto the history.

-}
onClickPreventDefault : msg -> Html.Attribute msg
onClickPreventDefault msg =
    Html.Events.preventDefaultOn "click" (Json.Decode.succeed ( msg, True ))


{-| Centered "growing" spinner with a muted caption. -}
spinner : String -> Html msg
spinner message =
    Html.div [ class "text-center py-4" ]
        [ Spinner.spinner [ Spinner.grow ] []
        , Html.p [ class "text-muted mt-2" ] [ Html.text message ]
        ]


{-| Standard danger alert for a load/request failure. -}
errorAlert : String -> Html msg
errorAlert message =
    Alert.simpleDanger [] [ Html.text message ]
