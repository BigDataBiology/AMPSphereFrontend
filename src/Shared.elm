module Shared exposing
    ( Flags, decoder
    , Model, Msg
    , init, update, subscriptions
    )

import Dict
import Effect exposing (Effect)
import Json.Decode
import Route exposing (Route)
import Route.Path
import Shared.Model
import Shared.Msg



-- FLAGS


type alias Flags =
    { apiBaseUrl : String
    }


decoder : Json.Decode.Decoder Flags
decoder =
    Json.Decode.map Flags
        (Json.Decode.field "apiBaseUrl" Json.Decode.string)



-- INIT


type alias Model =
    Shared.Model.Model


init : Result Json.Decode.Error Flags -> Route () -> ( Model, Effect Msg )
init flagsResult route =
    let
        flags =
            case flagsResult of
                Ok f ->
                    f

                Err _ ->
                    { apiBaseUrl = "https://ampsphere-api.big-data-biology.org/v1" }
    in
    ( { apiBaseUrl = flags.apiBaseUrl
      , globalSearchQuery = ""
      }
    , Effect.none
    )



-- UPDATE


type alias Msg =
    Shared.Msg.Msg


update : Route () -> Msg -> Model -> ( Model, Effect Msg )
update route msg model =
    case msg of
        Shared.Msg.GlobalSearchQueryChanged query ->
            ( { model | globalSearchQuery = query }
            , Effect.none
            )

        Shared.Msg.GlobalSearchSubmitted ->
            let
                query =
                    String.trim model.globalSearchQuery
            in
            if String.startsWith "AMP" (String.toUpper query) && not (String.contains " " query) then
                ( { model | globalSearchQuery = "" }
                , Effect.pushRoute
                    { path = Route.Path.Amp_Accession_ { accession = query }
                    , query = Dict.empty
                    , hash = Nothing
                    }
                )

            else if String.startsWith "SPHERE" (String.toUpper query) && not (String.contains " " query) then
                ( { model | globalSearchQuery = "" }
                , Effect.pushRoute
                    { path = Route.Path.Family_Accession_ { accession = query }
                    , query = Dict.empty
                    , hash = Nothing
                    }
                )

            else if query /= "" then
                ( { model | globalSearchQuery = "" }
                , Effect.pushRoute
                    { path = Route.Path.TextSearch
                    , query = Dict.singleton "query" query
                    , hash = Nothing
                    }
                )

            else
                ( model, Effect.none )



-- SUBSCRIPTIONS


subscriptions : Route () -> Model -> Sub Msg
subscriptions route model =
    Sub.none
