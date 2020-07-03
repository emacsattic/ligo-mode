open Simple_utils.Display

let stage = "purification"

type purification_error = [
  | `purification_corner_case of string
]

let corner_case s = `purification_corner_case s

let error_ppformat : display_format:string display_format ->
  Format.formatter -> purification_error -> unit =
  fun ~display_format f a ->
  match display_format with
  | Human_readable | Dev -> (
    match a with
    | `purification_corner_case s ->
      Format.fprintf f
        "@[<hv>Corner case: %s@]"
        s
  )

let error_jsonformat : purification_error -> Yojson.t = fun a ->
  let json_error ~stage ~content =
    `Assoc [
      ("status", `String "error") ;
      ("stage", `String stage) ;
      ("content",  content )]
  in
  match a with
  | `purification_corner_case s ->
    let message = `String "corner case" in
    let content = `Assoc [
      ("message", message);
      ("value", `String s)
    ] in
    json_error ~stage ~content
