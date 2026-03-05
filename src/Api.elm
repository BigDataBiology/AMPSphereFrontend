module Api exposing (Data(..))

import Http


type Data value
    = NotAsked
    | Loading
    | Success value
    | Failure Http.Error
