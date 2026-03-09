module Components.SeqLogo exposing (view)

{-| Sequence logo renderer.

Parses a FASTA-format multiple sequence alignment and renders an SVG sequence
logo showing information content (in bits) at each position.

**Gap handling:** Gaps ('-' and other non-amino-acid characters) are excluded
when computing amino acid frequencies. However, the information content at each
position is scaled by the coverage fraction (non-gap count / total sequences).
This means positions where most sequences have gaps will show very short letter
stacks, correctly reflecting the low confidence at those positions.

-}

import Html exposing (Html)
import Html.Attributes
import Svg exposing (Svg)
import Svg.Attributes as SA


aminoAcids : List Char
aminoAcids =
    String.toList "ACDEFGHIKLMNPQRSTVWY"


{-| Maximum possible information content: log2(20) ≈ 4.322 bits.
A position where all sequences have the same amino acid achieves this.
-}
maxBits : Float
maxBits =
    logBase 2 20



-- Amino acid color scheme (matching existing CSS classes)


aaColor : Char -> String
aaColor aa =
    case aa of
        'K' ->
            "#1465AC"

        'R' ->
            "#1465AC"

        'H' ->
            "#1465AC"

        'D' ->
            "#DC143C"

        'E' ->
            "#DC143C"

        'F' ->
            "#FF8C00"

        'Y' ->
            "#FF8C00"

        'W' ->
            "#FF8C00"

        'S' ->
            "#32CD32"

        'T' ->
            "#32CD32"

        'N' ->
            "#32CD32"

        'Q' ->
            "#32CD32"

        'C' ->
            "#B8860B"

        'G' ->
            "#808080"

        'P' ->
            "#808080"

        _ ->
            "#333333"



-- FASTA parsing


parseFasta : String -> List String
parseFasta text =
    String.lines text
        |> List.foldl
            (\line ( current, seqs ) ->
                if String.startsWith ">" line then
                    if current == "" then
                        ( "", seqs )

                    else
                        ( "", seqs ++ [ current ] )

                else
                    ( current ++ String.trim line, seqs )
            )
            ( "", [] )
        |> (\( last, seqs ) ->
                if last == "" then
                    seqs

                else
                    seqs ++ [ last ]
           )



-- PSSM / information content


type alias LetterHeight =
    { aa : Char
    , height : Float
    }


computePositionHeights : List String -> List (List LetterHeight)
computePositionHeights sequences =
    let
        seqLen =
            List.head sequences
                |> Maybe.map String.length
                |> Maybe.withDefault 0
    in
    if List.isEmpty sequences then
        []

    else
        List.range 0 (seqLen - 1)
            |> List.map (positionHeights sequences)


{-| Compute letter heights (in bits) for a single alignment position.

1.  Count only non-gap characters (those in the 20-letter amino acid alphabet).
2.  Compute frequencies over non-gap characters.
3.  Compute Shannon entropy: H = -Σ p(a) × log₂(p(a))
4.  Information content: R = (log₂(20) - H) × coverage
    where coverage = non-gap count / total sequences.
    Multiplying by coverage ensures that positions dominated by gaps show
    proportionally shorter stacks.
5.  Per-letter height = frequency × information content, sorted ascending
    so that the tallest (most frequent) letter is stacked on top.

-}
positionHeights : List String -> Int -> List LetterHeight
positionHeights sequences pos =
    let
        numSeqs =
            toFloat (List.length sequences)

        charsAtPos =
            List.filterMap
                (\seq ->
                    String.toList seq
                        |> List.drop pos
                        |> List.head
                        |> Maybe.andThen
                            (\c ->
                                if List.member c aminoAcids then
                                    Just c

                                else
                                    Nothing
                            )
                )
                sequences

        nonGapCount =
            toFloat (List.length charsAtPos)

        -- Fraction of sequences with a real amino acid at this position.
        -- Used to down-weight positions that are mostly gaps.
        coverage =
            nonGapCount / numSeqs

        freqs =
            aminoAcids
                |> List.filterMap
                    (\aa ->
                        let
                            f =
                                toFloat (List.length (List.filter ((==) aa) charsAtPos)) / nonGapCount
                        in
                        if f > 0 then
                            Just ( aa, f )

                        else
                            Nothing
                    )

        entropy =
            List.sum (List.map (\( _, f ) -> -f * logBase 2 f) freqs)

        info =
            max 0 (maxBits - entropy) * coverage
    in
    if nonGapCount == 0 then
        []

    else
        freqs
            |> List.map (\( aa, f ) -> { aa = aa, height = f * info })
            |> List.sortBy .height



-- SVG rendering


colWidth : Float
colWidth =
    16


logoHeight : Float
logoHeight =
    140


yAxisWidth : Float
yAxisWidth =
    35


xAxisHeight : Float
xAxisHeight =
    20


view : String -> Html msg
view alignmentText =
    let
        sequences =
            parseFasta alignmentText

        positions =
            computePositionHeights sequences

        numPos =
            List.length positions

        bitScale =
            logoHeight / maxBits

        totalW =
            yAxisWidth + toFloat numPos * colWidth

        totalH =
            logoHeight + xAxisHeight
    in
    if numPos == 0 then
        Html.text ""

    else
        Html.div [ Html.Attributes.style "overflow-x" "auto" ]
            [ Svg.svg
                [ SA.width (String.fromFloat totalW)
                , SA.height (String.fromFloat totalH)
                ]
                (viewYAxis bitScale
                    ++ List.concat
                        (List.indexedMap
                            (\i posData ->
                                viewPositionStack (yAxisWidth + toFloat i * colWidth) bitScale posData
                            )
                            positions
                        )
                    ++ viewXAxisTicks numPos
                )
            ]


viewYAxis : Float -> List (Svg msg)
viewYAxis bitScale =
    let
        ticks =
            [ 0, 1, 2, 3, 4 ]
    in
    Svg.line
        [ SA.x1 (String.fromFloat yAxisWidth)
        , SA.y1 "0"
        , SA.x2 (String.fromFloat yAxisWidth)
        , SA.y2 (String.fromFloat logoHeight)
        , SA.stroke "#333"
        , SA.strokeWidth "1"
        ]
        []
        :: List.concatMap
            (\tick ->
                let
                    y =
                        logoHeight - toFloat tick * bitScale
                in
                [ Svg.line
                    [ SA.x1 (String.fromFloat (yAxisWidth - 4))
                    , SA.y1 (String.fromFloat y)
                    , SA.x2 (String.fromFloat yAxisWidth)
                    , SA.y2 (String.fromFloat y)
                    , SA.stroke "#333"
                    , SA.strokeWidth "1"
                    ]
                    []
                , Svg.text_
                    [ SA.x (String.fromFloat (yAxisWidth - 6))
                    , SA.y (String.fromFloat (y + 3))
                    , SA.textAnchor "end"
                    , SA.fontSize "10"
                    , SA.fill "#333"
                    ]
                    [ Svg.text (String.fromInt tick) ]
                ]
            )
            ticks
        ++ [ Svg.text_
                [ SA.x "2"
                , SA.y (String.fromFloat (logoHeight / 2))
                , SA.textAnchor "middle"
                , SA.fontSize "10"
                , SA.fill "#333"
                , SA.transform ("rotate(-90, 8, " ++ String.fromFloat (logoHeight / 2) ++ ")")
                ]
                [ Svg.text "bits" ]
           ]


{-| Render one column of stacked letters. Letters are sorted ascending by
height, so the tallest (most conserved) letter ends up on top. We stack from
the baseline upward: `bottomY` starts at `logoHeight` and decreases as each
letter is placed.
-}
viewPositionStack : Float -> Float -> List LetterHeight -> List (Svg msg)
viewPositionStack x bitScale letters =
    letters
        |> List.filter (\lh -> lh.height * bitScale > 1)
        |> List.foldl
            (\lh ( bottomY, svgs ) ->
                let
                    pixH =
                        lh.height * bitScale
                in
                ( bottomY - pixH
                , svgs ++ [ viewLetter x bottomY colWidth pixH lh.aa ]
                )
            )
            ( logoHeight, [] )
        |> Tuple.second


{-| Render a single amino acid letter stretched to fill a (w × h) cell.

  - `textLength` + `lengthAdjust="spacingAndGlyphs"` stretches the glyph
    horizontally to exactly fill the column width.
  - In SVG the default baseline is "alphabetic", so `y` positions the baseline
    (bottom of uppercase glyphs). We set `y = bottomY` so letters sit on top
    of the stacking point.
  - `font-size` is set to `h * 1.4` to compensate for the cap-height being
    ~72% of the em square in most fonts, making the visible letter approximately
    `h` pixels tall.

-}
viewLetter : Float -> Float -> Float -> Float -> Char -> Svg msg
viewLetter x bottomY w h aa =
    Svg.text_
        [ SA.x (String.fromFloat (x + w / 2))
        , SA.y (String.fromFloat bottomY)
        , SA.fill (aaColor aa)
        , SA.fontSize (String.fromFloat (h * 1.4))
        , SA.fontFamily "Arial Black, Impact, sans-serif"
        , SA.fontWeight "bold"
        , SA.textAnchor "middle"
        , SA.textLength (String.fromFloat w)
        , SA.lengthAdjust "spacingAndGlyphs"
        ]
        [ Svg.text (String.fromChar aa) ]


viewXAxisTicks : Int -> List (Svg msg)
viewXAxisTicks numPos =
    let
        step =
            if numPos > 50 then
                10

            else if numPos > 20 then
                5

            else
                1

        positions =
            List.range 0 (numPos - 1)
                |> List.filter (\i -> modBy step i == 0)
    in
    List.map
        (\i ->
            Svg.text_
                [ SA.x (String.fromFloat (yAxisWidth + toFloat i * colWidth + colWidth / 2))
                , SA.y (String.fromFloat (logoHeight + 14))
                , SA.textAnchor "middle"
                , SA.fontSize "8"
                , SA.fill "#333"
                ]
                [ Svg.text (String.fromInt (i + 1)) ]
        )
        positions
