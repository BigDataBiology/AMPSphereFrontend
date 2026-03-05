module Pages.Contact exposing (Model, Msg, page)

import Effect exposing (Effect)
import Html exposing (Html)
import Html.Attributes exposing (class, href)
import Layouts
import Page exposing (Page)
import Route exposing (Route)
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



-- MODEL


type alias Model =
    {}


init : () -> ( Model, Effect Msg )
init _ =
    ( {}, Effect.none )



-- UPDATE


type Msg
    = NoOp


update : Msg -> Model -> ( Model, Effect Msg )
update msg model =
    ( model, Effect.none )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- VIEW


view : Model -> View Msg
view model =
    { title = "Contact"
    , body =
        [ Html.div [ class "page-contact" ]
            [ Html.h1 [] [ Html.text "Contact" ]
            , Html.section [ class "contact-section" ]
                [ Html.h2 [] [ Html.text "Big Data Biology Lab" ]
                , Html.p []
                    [ Html.text "AMPSphere is developed and maintained by the "
                    , Html.a [ href "https://big-data-biology.org" ]
                        [ Html.text "Big Data Biology Lab" ]
                    , Html.text " at the Centre for Microbiome Research, Queensland University of Technology."
                    ]
                ]
            , Html.section [ class "contact-section" ]
                [ Html.h2 [] [ Html.text "Feedback & Issues" ]
                , Html.p []
                    [ Html.text "For bug reports and feature requests, please open an issue on our "
                    , Html.a [ href "https://github.com/BigDataBiology/AMPSphere" ]
                        [ Html.text "GitHub repository" ]
                    , Html.text "."
                    ]
                ]
            , Html.section [ class "contact-section" ]
                [ Html.h2 [] [ Html.text "Email" ]
                , Html.p []
                    [ Html.text "For general inquiries, contact: "
                    , Html.a [ href "mailto:luispedro@big-data-biology.org" ]
                        [ Html.text "luispedro@big-data-biology.org" ]
                    ]
                ]
            ]
        ]
    }
