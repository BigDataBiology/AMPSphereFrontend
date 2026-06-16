module Api.FamilyFeatures exposing (AmpFeatures, FamilyFeatures, get)

import Api.Endpoint as Endpoint
import Dict exposing (Dict)
import Effect exposing (Effect)
import Http
import Json.Decode as Decode exposing (Decoder)


type alias AmpFeatures =
    { mw : Float
    , length : Float
    , aromaticity : Float
    , gravy : Float
    , instabilityIndex : Float
    , isoelectricPoint : Float
    , chargeAtPH7 : Float
    }


type alias FamilyFeatures =
    Dict String AmpFeatures


ampFeaturesDecoder : Decoder AmpFeatures
ampFeaturesDecoder =
    Decode.map7 AmpFeatures
        (Decode.field "MW" Decode.float)
        (Decode.field "Length" Decode.float)
        (Decode.field "Aromaticity" Decode.float)
        (Decode.field "GRAVY" Decode.float)
        (Decode.field "Instability_index" Decode.float)
        (Decode.field "Isoelectric_point" Decode.float)
        (Decode.field "Charge_at_pH_7" Decode.float)


decoder : Decoder FamilyFeatures
decoder =
    Decode.dict ampFeaturesDecoder


get : { accession : String, onResponse : Result Http.Error FamilyFeatures -> msg } -> Effect msg
get options =
    Effect.apiGet
        { endpoint = Endpoint.url [ "families", options.accession, "features" ] []
        , decoder = decoder
        , onResponse = options.onResponse
        }
