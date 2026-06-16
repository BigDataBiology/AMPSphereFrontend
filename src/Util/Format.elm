module Util.Format exposing (eValue, float, percent, thousands, truncate)

{-| Shared number / string formatters.

Previously `formatFloat` was copy-pasted across BrowseData, Amp and Family pages,
`formatNumber` lived in Home, and `formatPercent`/`formatEValue`/`truncateSequence`
were one-offs in SequenceSearch / TextSearch. They now live here.

-}


{-| Round a float to `decimals` places, dropping trailing zeros.

    float 2 7.5  --> "7.5"
    float 1 3.14 --> "3.1"

-}
float : Int -> Float -> String
float decimals val =
    let
        factor =
            toFloat (10 ^ decimals)

        rounded =
            toFloat (round (val * factor)) / factor
    in
    String.fromFloat rounded


{-| Integer with comma thousands separators.

    thousands 1234567 --> "1,234,567"

-}
thousands : Int -> String
thousands n =
    let
        reversed =
            List.reverse (String.toList (String.fromInt n))
    in
    groupBy3 reversed []
        |> List.map (List.reverse >> String.fromList)
        |> String.join ","


groupBy3 : List Char -> List (List Char) -> List (List Char)
groupBy3 chars acc =
    case chars of
        [] ->
            acc

        _ ->
            groupBy3 (List.drop 3 chars) (List.take 3 chars :: acc)


{-| Fraction (0–1) rendered as a percentage with one decimal place.

    percent 0.1234 --> "12.3%"

-}
percent : Float -> String
percent val =
    String.fromFloat (toFloat (round (val * 1000)) / 10) ++ "%"


{-| Scientific notation for small e-values, plain rounding otherwise.

    eValue 1.0e-12 --> "1e-12"
    eValue 0.05    --> "0.05"

-}
eValue : Float -> String
eValue val =
    if val <= 0 then
        String.fromFloat val

    else if val < 0.001 then
        let
            exp =
                logBase 10 val |> floor

            mantissa =
                val / (10 ^ toFloat exp)
        in
        String.fromFloat (toFloat (round (mantissa * 10)) / 10) ++ "e" ++ String.fromInt exp

    else
        String.fromFloat (toFloat (round (val * 1000)) / 1000)


{-| Clip a string to `maxLen` characters, appending an ellipsis when clipped.

    truncate 3 "ABCDEF" --> "ABC..."

-}
truncate : Int -> String -> String
truncate maxLen str =
    if String.length str > maxLen then
        String.left maxLen str ++ "..."

    else
        str
