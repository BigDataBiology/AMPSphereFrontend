module Layouts.Default exposing (Model, Msg, Props, layout)

import Effect exposing (Effect)
import Html exposing (Html)
import Html.Attributes exposing (class, href, placeholder, type_, value)
import Html.Events exposing (onInput, onSubmit)
import Layout exposing (Layout)
import Route exposing (Route)
import Route.Path
import Shared
import Shared.Msg
import View exposing (View)


type alias Props =
    {}


layout : Props -> Shared.Model -> Route () -> Layout () Model Msg contentMsg
layout props shared route =
    Layout.new
        { init = init
        , update = update
        , view = view shared route
        , subscriptions = subscriptions
        }



-- MODEL


type alias Model =
    {}


init : () -> ( Model, Effect Msg )
init _ =
    ( {}
    , Effect.none
    )



-- UPDATE


type Msg
    = SearchQueryChanged String
    | SearchSubmitted


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        SearchQueryChanged query ->
            ( model
            , Effect.sendSharedMsg (Shared.Msg.GlobalSearchQueryChanged query)
            )

        SearchSubmitted ->
            ( model
            , Effect.sendSharedMsg Shared.Msg.GlobalSearchSubmitted
            )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


view :
    Shared.Model
    -> Route ()
    -> { toContentMsg : Msg -> contentMsg, content : View contentMsg, model : Model }
    -> View contentMsg
view shared route { toContentMsg, model, content } =
    { title = content.title ++ " | AMPSphere"
    , body =
        [ viewHeader shared route toContentMsg
        , Html.main_ [ class "main-content" ]
            content.body
        , viewFooter
        ]
    }


viewHeader : Shared.Model -> Route () -> (Msg -> contentMsg) -> Html contentMsg
viewHeader shared route toContentMsg =
    Html.header [ class "site-header" ]
        [ Html.div [ class "header-inner" ]
            [ Html.a [ href "/", class "logo" ]
                [ Html.text "AMPSphere" ]
            , Html.nav [ class "main-nav" ]
                [ navLink route Route.Path.Home_ "Home"
                , navLink route Route.Path.BrowseData "Browse Data"
                , navLink route Route.Path.Downloads "Downloads"
                , navLink route Route.Path.About "About"
                , navLink route Route.Path.Contact "Contact"
                ]
            , Html.form
                [ class "header-search"
                , onSubmit (toContentMsg SearchSubmitted)
                ]
                [ Html.input
                    [ type_ "text"
                    , placeholder "Search AMP, family, or text..."
                    , value shared.globalSearchQuery
                    , onInput (SearchQueryChanged >> toContentMsg)
                    ]
                    []
                , Html.button [ type_ "submit", class "search-btn" ]
                    [ Html.text "Search" ]
                ]
            ]
        ]


navLink : Route () -> Route.Path.Path -> String -> Html msg
navLink route path label =
    let
        isActive =
            route.path == path
    in
    Html.a
        [ Route.Path.href path
        , class
            (if isActive then
                "nav-link active"

             else
                "nav-link"
            )
        ]
        [ Html.text label ]


viewFooter : Html msg
viewFooter =
    Html.footer [ class "site-footer" ]
        [ Html.div [ class "footer-inner" ]
            [ Html.p []
                [ Html.text "AMPSphere: a comprehensive catalog of antimicrobial peptides" ]
            , Html.p []
                [ Html.a [ href "https://big-data-biology.org" ]
                    [ Html.text "Big Data Biology Lab" ]
                , Html.text " | "
                , Html.a [ href "https://doi.org/10.1016/j.cell.2024.05.013" ]
                    [ Html.text "Cite AMPSphere" ]
                ]
            ]
        ]
