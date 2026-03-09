module Layouts.Default exposing (Model, Msg, Props, layout)

import Bootstrap.Button as Button
import Bootstrap.Form.Input as Input
import Bootstrap.Grid as Grid
import Bootstrap.Navbar as Navbar
import Effect exposing (Effect)
import Html exposing (Html)
import Html.Attributes exposing (class, href)
import Html.Events exposing (onSubmit)
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
    { navbarState : Navbar.State
    }


init : () -> ( Model, Effect Msg )
init _ =
    let
        ( navState, navCmd ) =
            Navbar.initialState NavbarMsg
    in
    ( { navbarState = navState }
    , Effect.sendCmd navCmd
    )



-- UPDATE


type Msg
    = NavbarMsg Navbar.State
    | SearchQueryChanged String
    | SearchSubmitted


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    case msg of
        NavbarMsg state ->
            ( { model | navbarState = state }
            , Effect.none
            )

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
    Navbar.subscriptions model.navbarState NavbarMsg



-- VIEW


view :
    Shared.Model
    -> Route ()
    -> { toContentMsg : Msg -> contentMsg, content : View contentMsg, model : Model }
    -> View contentMsg
view shared route { toContentMsg, model, content } =
    { title = content.title ++ " | AMPSphere"
    , body =
        [ viewNavbar shared model toContentMsg
        , Grid.container [ class "main-content mt-4 mb-5" ]
            content.body
        , viewFooter
        ]
    }


viewNavbar : Shared.Model -> Model -> (Msg -> contentMsg) -> Html contentMsg
viewNavbar shared model toContentMsg =
    Navbar.config (NavbarMsg >> toContentMsg)
        |> Navbar.withAnimation
        |> Navbar.dark
        |> Navbar.attrs [ class "navbar-ampsphere" ]
        |> Navbar.brand [ href "/" ] [ Html.text "AMPSphere" ]
        |> Navbar.items
            [ Navbar.itemLink [ href "/" ] [ Html.text "Home" ]
            , Navbar.itemLink [ href "/browse-data" ] [ Html.text "Browse Data" ]
            , Navbar.itemLink [ href "/downloads" ] [ Html.text "Downloads" ]
            , Navbar.itemLink [ href "/about" ] [ Html.text "About" ]
            , Navbar.itemLink [ href "/contact" ] [ Html.text "Contact" ]
            ]
        |> Navbar.customItems
            [ Navbar.customItem <|
                Html.form [ class "form-inline ml-auto", onSubmit (toContentMsg SearchSubmitted) ]
                    [ Input.text
                        [ Input.placeholder "Search AMP, family, or text..."
                        , Input.value shared.globalSearchQuery
                        , Input.onInput (\s -> toContentMsg (SearchQueryChanged s))
                        , Input.attrs [ class "mr-2", Html.Attributes.style "width" "220px" ]
                        ]
                    , Button.button
                        [ Button.outlineLight
                        , Button.attrs [ Html.Attributes.type_ "submit" ]
                        ]
                        [ Html.text "Search" ]
                    ]
            ]
        |> Navbar.view model.navbarState


viewFooter : Html msg
viewFooter =
    Html.footer [ class "site-footer" ]
        [ Grid.container []
            [ Html.p [ class "mb-1" ]
                [ Html.text "AMPSphere: a comprehensive catalog of antimicrobial peptides" ]
            , Html.p [ class "mb-0" ]
                [ Html.a [ href "https://big-data-biology.org" ]
                    [ Html.text "Big Data Biology Lab" ]
                , Html.text " | "
                , Html.a [ href "https://doi.org/10.1016/j.cell.2024.05.013" ]
                    [ Html.text "Cite AMPSphere" ]
                ]
            ]
        ]
