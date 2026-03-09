module Components.SequenceLegend exposing (view)

import Html exposing (Html)
import Html.Attributes exposing (class, style)


type alias Group =
    { label : String
    , residues : String
    , color : String
    }


groups : List Group
groups =
    [ { label = "Basic", residues = "K R H", color = "#1465AC" }
    , { label = "Acidic", residues = "D E", color = "#DC143C" }
    , { label = "Aromatic", residues = "F Y W", color = "#FF8C00" }
    , { label = "Polar", residues = "S T N Q", color = "#32CD32" }
    , { label = "Cysteine", residues = "C", color = "#B8860B" }
    , { label = "Special", residues = "G P", color = "#808080" }
    , { label = "Hydrophobic", residues = "A V I L M", color = "#333333" }
    ]


view : Html msg
view =
    Html.div [ class "d-flex flex-wrap mt-2", style "gap" "0.75rem" ]
        (List.map viewGroup groups)


viewGroup : Group -> Html msg
viewGroup group =
    Html.span [ class "d-inline-flex align-items-center small" ]
        [ Html.span
            [ style "display" "inline-block"
            , style "width" "10px"
            , style "height" "10px"
            , style "border-radius" "2px"
            , style "background-color" group.color
            , style "margin-right" "4px"
            ]
            []
        , Html.span [ style "color" group.color, style "font-weight" "600" ]
            [ Html.text group.residues ]
        , Html.span [ class "text-muted ml-1" ]
            [ Html.text ("(" ++ group.label ++ ")") ]
        ]
