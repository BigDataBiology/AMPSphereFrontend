module Pages.NotFound_ exposing (Model, Msg, page)

import Bootstrap.Alert as Alert
import Bootstrap.Button as Button
import Bootstrap.Grid as Grid
import Bootstrap.Grid.Col as Col
import Effect exposing (Effect)
import Html exposing (Html)
import Html.Attributes exposing (class)
import Layouts
import Page exposing (Page)
import Route exposing (Route)
import Route.Path
import Shared
import View exposing (View)


page : Shared.Model -> Route () -> Page Model Msg
page shared route =
    Page.new
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }
        |> Page.withLayout (always <| Layouts.Default {})



-- INIT


type alias Model =
    {}


init : () -> ( Model, Effect Msg )
init () =
    ( {}
    , Effect.none
    )



-- UPDATE


type Msg
    = NoOp


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        NoOp ->
            ( model
            , Effect.none
            )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


view : Model -> View Msg
view model =
    { title = "Page Not Found"
    , body =
        [ Grid.row []
            [ Grid.col [ Col.md6, Col.attrs [ class "mx-auto text-center py-5" ] ]
                [ Html.h1 [ class "display-1 text-muted" ] [ Html.text "404" ]
                , Html.p [ class "lead" ] [ Html.text "The page you're looking for doesn't exist." ]
                , Button.linkButton
                    [ Button.primary
                    , Button.attrs [ Route.Path.href Route.Path.Home_ ]
                    ]
                    [ Html.text "Go to Home Page" ]
                ]
            ]
        ]
    }
