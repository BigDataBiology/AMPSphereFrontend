module Components.Pagination exposing (small, view)

{-| A single, 0-indexed pagination control.

Previously every page hand-rolled its own pagination markup, and the conventions
drifted: the AMP list used 0-indexed pages while TextSearch defaulted to 1 and
built `List.range 1 …`. That mismatch is exactly where off-by-one bugs hide. This
module standardizes on **0-indexed** pages (page 0 is the first page) and renders a
±3 window with Prev/Next controls. Page labels shown to the user are `current + 1`.

Callers whose page values are 1-indexed should subtract 1 when passing `current`
and add 1 inside `toMsg`.

-}

import Html exposing (Html)
import Html.Attributes exposing (class, href)
import Util.Html exposing (onClickPreventDefault)


type alias Config msg =
    { current : Int
    , total : Int
    , toMsg : Int -> msg
    }


{-| Full-size pagination. -}
view : Config msg -> Html msg
view config =
    render "" "mt-3" config


{-| Compact (`pagination-sm`) pagination for tighter contexts. -}
small : Config msg -> Html msg
small config =
    render "pagination-sm" "mt-2" config


render : String -> String -> Config msg -> Html msg
render sizeClass marginClass { current, total, toMsg } =
    if total <= 1 then
        Html.text ""

    else
        let
            visiblePages =
                List.range (max 0 (current - 3)) (min (total - 1) (current + 3))
        in
        Html.nav [ class marginClass ]
            [ Html.ul [ class ("pagination justify-content-center " ++ sizeClass) ]
                (step "Prev" (current > 0) (toMsg (current - 1))
                    :: List.map (pageItem current toMsg) visiblePages
                    ++ [ step "Next" (current < total - 1) (toMsg (current + 1)) ]
                )
            ]


pageItem : Int -> (Int -> msg) -> Int -> Html msg
pageItem current toMsg pg =
    Html.li
        [ class
            (if pg == current then
                "page-item active"

             else
                "page-item"
            )
        ]
        [ Html.a
            [ class "page-link", href "#", onClickPreventDefault (toMsg pg) ]
            [ Html.text (String.fromInt (pg + 1)) ]
        ]


step : String -> Bool -> msg -> Html msg
step label enabled msg =
    if enabled then
        Html.li [ class "page-item" ]
            [ Html.a [ class "page-link", href "#", onClickPreventDefault msg ]
                [ Html.text label ]
            ]

    else
        Html.li [ class "page-item disabled" ]
            [ Html.span [ class "page-link" ] [ Html.text label ] ]
