module Util.Export exposing (downloadFasta, downloadTsv, fasta, tsv)

{-| Helpers for turning tabular data into a TSV (tab-separated) file and
triggering a browser download. Used by the result tables (Browse Data, Text
Search, Sequence Search) so users can export what they see.

@docs tsv, downloadTsv, fasta, downloadFasta

-}

import File.Download as Download


{-| Build a TSV string from a header row and data rows. Tabs and newlines inside
a field are replaced with single spaces so they can't break the column/row
structure. Rows are separated by `\n`.
-}
tsv : List String -> List (List String) -> String
tsv headers rows =
    (headers :: rows)
        |> List.map (List.map sanitizeField >> String.join "\t")
        |> String.join "\n"


sanitizeField : String -> String
sanitizeField field =
    field
        |> String.replace "\t" " "
        |> String.replace "\u{000D}" " "
        |> String.replace "\n" " "


{-| Trigger a browser download of `content` as a TSV file named `filename`.
Returns a `Cmd`; wrap it with `Effect.sendCmd` at the call site.
-}
downloadTsv : String -> String -> Cmd msg
downloadTsv filename content =
    Download.string filename "text/tab-separated-values;charset=utf-8" content


{-| Build a FASTA string from a list of `(header, sequence)` pairs. Each record
is rendered as `>header` followed by the sequence on the next line. Newlines in
either field are stripped so they can't break the record structure.
-}
fasta : List ( String, String ) -> String
fasta records =
    records
        |> List.map
            (\( header, sequence ) ->
                ">" ++ stripNewlines header ++ "\n" ++ stripNewlines sequence
            )
        |> String.join "\n"


stripNewlines : String -> String
stripNewlines field =
    field
        |> String.replace "\u{000D}" ""
        |> String.replace "\n" ""


{-| Trigger a browser download of `content` as a FASTA file named `filename`.
Returns a `Cmd`; wrap it with `Effect.sendCmd` at the call site.
-}
downloadFasta : String -> String -> Cmd msg
downloadFasta filename content =
    Download.string filename "text/x-fasta;charset=utf-8" content
