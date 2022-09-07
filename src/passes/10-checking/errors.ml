module Snippet  = Simple_utils.Snippet
module Location = Simple_utils.Location
module Var      = Simple_utils.Var
open Simple_utils.Display
open Ligo_prim

let stage = "typer"

let type_improve t =
  let open Ast_typed in
  let make_type (module_path, element) =
    match module_path with
      [] -> (t_variable element ())
    | _ ->
      let open Simple_utils.PP_helpers in
      let x = Format.asprintf "%a" (list_sep ModuleVar.pp (tag ".")) module_path in
      let y = Format.asprintf "%a" TypeVar.pp element in
      (t_variable (TypeVar.of_input_var (x^"."^y)) ())
  in
  match t.type_content with
  | T_constant { parameters ; _ } when List.length parameters = 0 -> t
  | _ ->
  match Context.Hashes.find_type t with
  | Some t -> let t = make_type t in { t with type_meta = t.type_meta ; orig_var = t.orig_var }
  | _ -> t

let rec type_mapper ~f (t : Ast_typed.type_expression) =
  let open Ast_typed in
  let t = f t in
  match t.type_content with
  | T_arrow { type1 ; type2 } ->
     let type1 = type_mapper ~f type1 in
     let type2 = type_mapper ~f type2 in
     { t with type_content = T_arrow { type1 ; type2 } }
  | T_constant { language ; injection ; parameters } ->
     let parameters = List.map ~f:(type_mapper ~f) parameters in
     { t with type_content = T_constant { language ; injection ; parameters } }
  | T_record { fields ; layout } ->
     let fields = Record.map (fun Rows.{ associated_type ; michelson_annotation ; decl_pos } -> Rows.{ associated_type = type_mapper ~f associated_type ; michelson_annotation ; decl_pos }) fields in
     { t with type_content = T_record { fields ; layout } }
  | T_sum { fields ; layout } ->
     let fields = Record.map (fun Rows.{ associated_type ; michelson_annotation ; decl_pos } -> Rows.{ associated_type = type_mapper ~f associated_type ; michelson_annotation ; decl_pos }) fields in
     { t with type_content = T_sum { fields ; layout } }
  | _ -> t

let type_improve t =
  Context.Hashes.hash_types ();
  type_mapper ~f:type_improve t

type typer_error = [
  | `Typer_missing_funarg_annotation of ValueVar.t
  | `Typer_unbound_module_variable of ModuleVar.t * Location.t
  | `Typer_unbound_type_variable of TypeVar.t * Location.t
  | `Typer_unbound_variable of ValueVar.t * Location.t
  | `Typer_match_missing_case of Label.t list * Label.t list * Location.t
  | `Typer_match_extra_case of Label.t list * Label.t list * Location.t
  | `Typer_unbound_constructor of Label.t * Location.t
  | `Typer_type_app_wrong_arity of TypeVar.t option * int * int * Location.t
  | `Typer_michelson_or_no_annotation of Label.t * Location.t
  | `Typer_constant_declaration_tracer of Location.t * ValueVar.t * Ast_core.expression * (Ast_typed.type_expression option) * typer_error
  | `Typer_match_error of Ast_typed.type_expression * Ast_typed.type_expression * Location.t
  | `Typer_should_be_a_function_type of Ast_typed.type_expression * Ast_core.expression
  | `Typer_bad_record_access of Label.t * Ast_typed.expression * Location.t
  | `Typer_expression_tracer of Ast_core.expression * typer_error
  | `Typer_assert_equal of Location.t * Ast_typed.type_expression * Ast_typed.type_expression
  | `Typer_corner_case of string
  | `Typer_bad_collect_loop of Ast_typed.type_expression * Location.t
  | `Typer_expected_record of Location.t * Ast_typed.type_expression
  | `Typer_expected_variant of Location.t * Ast_typed.type_expression
  | `Typer_expected_map of Location.t * Ast_typed.type_expression
  | `Typer_expected of Location.t * Ast_typed.type_expression list * Ast_typed.type_expression list
  | `Typer_wrong_param_number of Location.t * string * int * Ast_typed.type_expression list
  | `Typer_expected_option of Location.t * Ast_typed.type_expression
  | `Typer_not_matching of Location.t * Ast_typed.type_expression * Ast_typed.type_expression
  | `Typer_not_annotated of Location.t
  | `Typer_typeclass_error of Location.t * Ast_typed.type_expression list list * Ast_typed.type_expression list
  | `Typer_uncomparable_types of Location.t * Ast_typed.type_expression * Ast_typed.type_expression
  | `Typer_comparator_composed of Location.t * Ast_typed.type_expression
  | `Typer_pattern_do_not_match of Location.t
  | `Typer_pattern_do_not_conform_type of Ast_core.type_expression option Pattern.t * Ast_typed.type_expression
  | `Typer_pattern_missing_cases of Location.t * (Syntax_types.t option) * Ast_core.type_expression option Pattern.t list
  | `Typer_pattern_redundant_case of Location.t
  | `Typer_redundant_pattern of Location.t
  | `Typer_wrong_type_for_unit_pattern of Location.t * Ast_typed.type_expression
  | `Typer_constant_since_protocol of Location.t * string * Environment.Protocols.t
] [@@deriving poly_constructor { prefix = "typer_" }]

let match_error ~(expected: Ast_typed.type_expression) ~(actual: Ast_typed.type_expression) (loc:Location.t) =
  match_error expected actual loc

let rec error_ppformat : display_format:string display_format ->
  Format.formatter -> typer_error -> unit =
  fun ~display_format f a ->
  match display_format with
  | Human_readable | Dev -> (
    match a with
    | `Typer_wrong_type_for_unit_pattern (l,t) ->
      Format.fprintf f
        "@[<hv>%a@.Variant pattern argument is expected of type %a but is of type unit.@]"
          Snippet.pp l
          Ast_typed.PP.type_expression t
    | `Typer_pattern_do_not_match loc ->
      Format.fprintf f
        "@[<hv>%a@.Pattern do not match returned expression.@]"
          Snippet.pp loc
    | `Typer_missing_funarg_annotation (v) ->
      Format.fprintf f
        "@[<hv>%a@.Missing a type annotation for argument \"%a\".@]"
          Snippet.pp (ValueVar.get_location v)
          ValueVar.pp v
    | `Typer_unbound_module_variable (mv,loc) ->
      Format.fprintf f
        "@[<hv>%a@.Module \"%a\" not found. @]"
        Snippet.pp loc
        ModuleVar.pp mv
    | `Typer_unbound_type_variable (tv,loc) ->
      Format.fprintf f
        "@[<hv>%a@.Type \"%a\" not found. @]"
        Snippet.pp loc
        TypeVar.pp tv
    | `Typer_unbound_variable (v,loc) ->
      Format.fprintf f
        "@[<hv>%a@.Variable \"%a\" not found. @]"
        Snippet.pp loc
        ValueVar.pp v
    | `Typer_match_missing_case (m, v, loc) ->
      let missing = List.fold_left ~f:(fun all o ->
        match List.find ~f:(Label.equal o) v with
        | Some _ -> all
        | None ->
          let (Label o) = o in
          o :: all
      ) ~init:[] m in
      let missing = String.concat ~sep:", " missing in
      Format.fprintf f
        "@[<hv>%a@.Pattern matching is not exhaustive.@.Cases that are missing: %s. @]"
        Snippet.pp loc
        missing
    | `Typer_match_extra_case (m, v,loc) ->
      let open Ast_core in
      let rec extra (processed: string list) (redundant: string list) (unknown: string list) = function
      | Label.Label l :: remaining -> (
        match (List.find ~f:(Label.equal (Label l)) m)  with
        | Some _ -> (
          match (List.find ~f:(fun f -> String.equal f l) processed) with
          | Some _ -> extra processed (l :: redundant) unknown remaining
          | None -> extra (l :: processed) redundant unknown remaining
        )
        | None -> extra processed redundant (l :: unknown) remaining)
      | [] -> (List.rev redundant, List.rev unknown)
      in
      let (redundant, unknown) = extra [] [] [] v in
      Format.fprintf f "@[<hv>%a@.Pattern matching over too many cases.@]"
        Snippet.pp loc;
      if List.length redundant > 0 then (
        let redundant = String.concat ~sep:", " redundant in
        Format.fprintf f
          "@[<hv>@.These case(s) are duplicate:@.%s@]"
          redundant
      );
      if List.length unknown > 0 then (
        let unknown = String.concat ~sep:", " unknown in
        Format.fprintf f
          "@[<hv>@.These case(s) don't belong to the variant:@.%s@]"
          unknown
      );
      Format.fprintf f
          "@[<hv>@.Please remove the extra cases. @]"
    | `Typer_unbound_constructor (c,loc) ->
      Format.fprintf f
        "@[<hv>%a@.Constructor \"%a\" not found. @]"
        Snippet.pp loc
        Label.pp c
    | `Typer_type_app_wrong_arity (op_opt,e,a,loc) ->
      let aux : Format.formatter -> TypeVar.t option -> unit =
        fun ppf operator_opt ->
          match operator_opt with
          | Some v -> Format.fprintf ppf " %a" TypeVar.pp v
          | None -> ()
      in
      Format.fprintf f
        "@[<hv>%a@ Type%a is applied to a wrong number of arguments, expected: %i got: %i@]"
        Snippet.pp loc
        aux op_opt
        e a
    | `Typer_michelson_or_no_annotation (c,loc) ->
      Format.fprintf f
        "@[<hv>%a@.Incorrect usage of type \"michelson_or\".@.The contructor \"%a\" must be annotated with a variant type. @]"
        Snippet.pp loc
        Label.pp c
    | `Typer_constant_declaration_tracer (_,_,_,_,err) ->
      error_ppformat ~display_format f err
    | `Typer_match_error (expected,actual,loc) ->
      Format.fprintf f
        "@[<hv>%a@.Pattern matching over an expression of an incorrect type.@.Type \"%a\" was expected, but got type \"%a\". @]"
        Snippet.pp loc
        Ast_typed.PP.type_expression (type_improve expected)
        Ast_typed.PP.type_expression (type_improve actual)
    | `Typer_should_be_a_function_type (actual,e) ->
      Format.fprintf f
        "@[<hv>%a@.Invalid type.@.Expected a function type, but got \"%a\". @]"
        Snippet.pp e.location
        Ast_typed.PP.type_expression (type_improve actual)
    | `Typer_bad_record_access (field,e,loc) ->
      Format.fprintf f
        "@[<hv>%a@.Invalid record field \"%a\" in record \"%a\". @]"
        Snippet.pp loc
        Label.pp field
        Ast_typed.PP.expression e
    | `Typer_corner_case desc ->
      Format.fprintf f
        "@[<hv>A type system corner case occurred:@.%s@]"
        desc
    | `Typer_bad_collect_loop (t,loc) ->
      Format.fprintf f
        "@[<hv>%a@.Bounded loop over a value with an incorrect type.@.Expected a value with type: \"list\", \"set\" or \"map\", but got a value of type \"%a\". @]"
        Snippet.pp loc
        Ast_typed.PP.type_expression (type_improve t)
    | `Typer_expression_tracer (_,err) -> error_ppformat ~display_format f err
    | `Typer_not_annotated l ->
      Format.fprintf f "@[<hv>%a@.Can't infer the type of this value, please add a type annotation.@]"
        Snippet.pp l
    | `Typer_comparator_composed (loc,_a) ->
      Format.fprintf f
        "@[<hv>%a@.Invalid arguments.@.Only composed types of not more than two element are allowed to be compared. @]"
        Snippet.pp loc
    | `Typer_assert_equal (loc, expected,actual) ->
      Format.fprintf f
        "@[<hv>%a@.Invalid type(s).@.Expected: \"%a\", but got: \"%a\". @]"
        Snippet.pp loc
        Ast_typed.PP.type_expression_orig (type_improve expected)
        Ast_typed.PP.type_expression_orig (type_improve actual)
    | `Typer_expected_record (loc,t) ->
      Format.fprintf f
        "@[<hv>%a@.Invalid argument.@.Expected a record, but got an argument of type \"%a\". @]"
        Snippet.pp loc
        Ast_typed.PP.type_expression (type_improve t)
    | `Typer_expected_variant (loc,t) ->
      Format.fprintf f
        "@[<hv>%a@.Invalid argument.@.Expected a variant, but got an argument of type \"%a\". @]"
        Snippet.pp loc
        Ast_typed.PP.type_expression (type_improve t)
    | `Typer_wrong_param_number (loc,name,expected,actual) ->
      Format.fprintf f
        "@[<hv>%a@.Function \"%s\" called with wrong number of arguments.@.Expected %d arguments, got %d arguments. @]"
        Snippet.pp loc
        name
        expected (List.length actual)
    | `Typer_expected_map (loc,e) ->
      Format.fprintf f
        "@[<hv>%a@.Incorrect argument.@.Expected a map, but got an argument of type \"%a\". @]"
        Snippet.pp loc
        Ast_typed.PP.type_expression (type_improve e)
    | `Typer_expected_option (loc,e) ->
      Format.fprintf f
        "@[<hv>%a@.Incorrect argument.@.Expected an option, but got an argument of type \"%a\". @]"
        Snippet.pp loc
        Ast_typed.PP.type_expression (type_improve e)
    | `Typer_not_matching (loc,t1,t2) ->
      Format.fprintf f
        "@[<hv>%a@.These types are not matching:@. - %a@. - %a@]"
        Snippet.pp loc
        Ast_typed.PP.type_expression (type_improve t1)
        Ast_typed.PP.type_expression (type_improve t2)
    | `Typer_uncomparable_types (loc,a,b) ->
      Format.fprintf f
        "@[<hv>%a@.Invalid arguments.@.These types cannot be compared: \"%a\" and \"%a\". @]"
        Snippet.pp loc
        Ast_typed.PP.type_expression (type_improve a)
        Ast_typed.PP.type_expression (type_improve b)
    | `Typer_typeclass_error (loc,exps,acts) ->
      let open Simple_utils.PP_helpers in
      let printl printer ppf args =
        Format.fprintf ppf "(%a)" (list_sep printer (const ", ")) args in
      Format.fprintf f
        "@[<hv>%a@.Invalid arguments.@.Expected an argument of type %a, but got an argument of type %a. @]"
        Snippet.pp loc
        (list_sep (printl Ast_typed.PP.type_expression) (const " or ")) exps
        (list_sep Ast_typed.PP.type_expression (const ", ")) acts
    | `Typer_expected (loc,exps,acts) ->
      let open Simple_utils.PP_helpers in
      Format.fprintf f
        "@[<hv>%a@.Cannot match arguments for operation.@.Expected arguments with types:%a@.but got arguments with types:%a. @]"
        Snippet.pp loc
        (list_sep_prep Ast_typed.PP.type_expression (tag "@.- ")) exps
        (list_sep_prep Ast_typed.PP.type_expression (tag "@.- ")) acts
    | `Typer_pattern_do_not_conform_type (p,t) ->
      let pf ppf value =
        match p.location with
        | Virtual _ ->  Format.fprintf ppf "%a " (Pattern.pp Ast_core.PP.type_expression_option) value
        | File _ -> ()
      in
      Format.fprintf f
        "@[<hv>%a@.Pattern %anot of the expected type %a @]"
        Snippet.pp p.location pf p Ast_typed.PP.type_expression (type_improve t)
    | `Typer_redundant_pattern loc ->
      Format.fprintf f
        "@[<hv>%a@.Redundant pattern matching@]"
        Snippet.pp loc
    | `Typer_pattern_missing_cases (loc, syntax, ps) ->
      let ps = List.fold ps ~init:"" ~f:(fun s p ->
        let s' = Desugaring.Decompiler.decompile_pattern_to_string ~syntax p in
        s ^ "- " ^ s' ^ "\n") in
      Format.fprintf f
        "@[<hv>%a@.Error : this pattern-matching is not exhaustive.@.Here are examples of cases that are not matched:@.%s@]"
        Snippet.pp loc
        ps
    | `Typer_pattern_redundant_case loc ->
      Format.fprintf f
        "@[<hv>%a@.Error : this match case is unused.@]"
        Snippet.pp loc
    | `Typer_constant_since_protocol (loc, constant, protocol) ->
      let protocol_name = Environment.Protocols.variant_to_string protocol in
      Format.fprintf f
        "@[<hv>%a@.%s is supported in protocol %s onwards.@.Hint: pass the compiler option `--protocol %s`.@]"
        Snippet.pp loc constant (String.capitalize protocol_name) protocol_name
  )
let rec error_jsonformat : typer_error -> Yojson.Safe.t = fun a ->
  let json_error ~stage ~content =
    `Assoc [
      ("status", `String "error") ;
      ("stage", `String stage) ;
      ("content",  content )]
  in
  match a with
  | `Typer_wrong_type_for_unit_pattern (l,t) ->
    let message = "Variant pattern argument is unit" in
    let content = `Assoc [
      ("message", `String message );
      ("expected", Ast_typed.type_expression_to_yojson t);
      ("location", Location.to_yojson l);
    ] in
    json_error ~stage ~content
  | `Typer_redundant_pattern loc ->
    let message = "Redundant pattern matching" in
    let content = `Assoc [
      ("message", `String message );
      ("location", Location.to_yojson loc);
    ] in
    json_error ~stage ~content
  | `Typer_pattern_do_not_match loc ->
    let message = Format.asprintf "Pattern do not match returned expression" in
    let content = `Assoc [
      ("message", `String message );
      ("location", Location.to_yojson loc); ] in
    json_error ~stage ~content
  | `Typer_missing_funarg_annotation v ->
    let message = Format.asprintf "Missing type annotation for argument" in
    let content = `Assoc [
      ("value", ValueVar.to_yojson v );
      ("message", `String message );
      ("location", Location.to_yojson @@ ValueVar.get_location v); ] in
    json_error ~stage ~content
  | `Typer_unbound_module_variable (mv,loc) ->
    let message = `String "unbound module" in
    let loc = Format.asprintf "%a" Location.pp loc in
    let value = Format.asprintf "%a" ModuleVar.pp mv in
    let content = `Assoc [
      ("message", message);
      ("location", `String loc);
      ("value", `String value);
    ] in
    json_error ~stage ~content
  | `Typer_unbound_type_variable (tv,loc) ->
    let message = `String "unbound type variable" in
    let loc = Format.asprintf "%a" Location.pp loc in
    let value = Format.asprintf "%a" TypeVar.pp tv in
    let content = `Assoc [
      ("message", message);
      ("location", `String loc);
      ("value", `String value);
    ] in
    json_error ~stage ~content
  | `Typer_unbound_variable (v,loc) ->
    let message = `String "unbound type variable" in
    let loc = Format.asprintf "%a" Location.pp loc in
    let value = Format.asprintf "%a" ValueVar.pp v in
    let content = `Assoc [
      ("message", message);
      ("location", `String loc);
      ("value", `String value);
    ] in
    json_error ~stage ~content
  | `Typer_match_missing_case (m, v, loc) ->
    let missing = List.fold_left ~f:(fun all o ->
      match List.find ~f:(Label.equal o) v with
      | Some _ -> all
      | None ->
        let (Label o) = o in
        `String o :: all
    ) ~init:[] m in
    let message = `String "Missing match case" in
    let loc = `String (Format.asprintf "%a" Location.pp loc) in
    let content = `Assoc [
      ("message", message);
      ("location", loc);
      ("value", `List missing);
    ] in
    json_error ~stage ~content
  | `Typer_match_extra_case (v, m,loc) ->
    let open Ast_core in
    let rec extra processed redundant unknown = function
    | Label.Label l :: remaining -> (
      match (List.find ~f:(Label.equal (Label l)) m)  with
      | Some _ -> (
        match (List.find ~f:(fun f -> String.equal f l) processed) with
        | Some _ -> extra processed (`String l :: redundant) unknown remaining
        | None -> extra (l :: processed) redundant unknown remaining
      )
      | None -> extra processed redundant (`String l :: unknown) remaining)
    | [] -> (List.rev redundant, List.rev unknown)
    in
    let (redundant, unknown) = extra [] [] [] v in
    let message = `String "Redundant case in match cases" in
    let loc = `String (Format.asprintf "%a" Location.pp loc) in
    let content = `Assoc [
      ("message", message);
      ("location", loc);
      ("redundant", `List redundant);
      ("unknown", `List unknown)
    ] in
    json_error ~stage ~content
  | `Typer_unbound_constructor (c,loc) ->
    let message = `String "unbound type variable" in
    let loc = Format.asprintf "%a" Location.pp loc in
    let value = Format.asprintf "%a" Label.pp c in
    let content = `Assoc [
      ("message", message);
      ("location", `String loc);
      ("value", `String value);
    ] in
    json_error ~stage ~content
  | `Typer_type_app_wrong_arity (op, e, a, loc) ->
    let message = `String "Wrong arity in type application" in
    let loc = Format.asprintf "%a" Location.pp loc in
    let op = Option.value_map ~default:`Null ~f:TypeVar.to_yojson op in
    let content = `Assoc [
      ("message", message);
      ("location", `String loc);
      ("type_constant", op);
      ("expected", `Int e);
      ("actuel", `Int a);
    ] in
    json_error ~stage ~content
  | `Typer_michelson_or_no_annotation (c,loc) ->
    let message = `String "michelson_or must be annotated with a sum type" in
    let loc = Format.asprintf "%a" Location.pp loc in
    let value = Format.asprintf "%a" Label.pp c in
    let content = `Assoc [
      ("message", message);
      ("location", `String loc);
      ("value", `String value);
    ] in
    json_error ~stage ~content
  | `Typer_constant_declaration_tracer (loc,name,ae,Some t,err) ->
    let message = `String "Typing constant declaration" in
    let value = `String (Format.asprintf "%a" Ast_core.PP.expression ae) in
    let loc = Location.to_yojson loc in
    let name = ValueVar.to_yojson name in
    let expected = `String (Format.asprintf "%a" Ast_typed.PP.type_expression t) in
    let content = `Assoc [
      ("message", message);
      ("location", loc);
      ("name", name);
      ("value", value);
      ("expected", expected);
      ("children", error_jsonformat err);
    ] in
    json_error ~stage ~content
  | `Typer_constant_declaration_tracer (loc,name,_,None,err) ->
    let message = `String "Typing constant declaration" in
    let loc = Location.to_yojson loc in
    let name = ValueVar.to_yojson name in
    let content = `Assoc [
      ("message", message);
      ("location", loc);
      ("name", name);
      ("children", error_jsonformat err);
    ] in
    json_error ~stage ~content
  | `Typer_match_error (expected,actual,loc) ->
    let message = `String "matching over an expression of the wrong type" in
    let loc = Location.to_yojson loc in
    let expected = Ast_typed.type_expression_to_yojson expected in
    let actual = Ast_typed.type_expression_to_yojson actual in
    let content = `Assoc [
      ("message", message);
      ("location", loc);
      ("actual", actual);
      ("expected", expected);
    ] in
    json_error ~stage ~content
  | `Typer_should_be_a_function_type (actual,e) ->
    let message = `String "expected a function type" in
    let loc = `String (Format.asprintf "%a" Location.pp e.location) in
    let expression = `String (Format.asprintf "%a" Ast_core.PP.expression e) in
    let actual = `String (Format.asprintf "%a" Ast_typed.PP.type_expression actual) in
    let content = `Assoc [
      ("message", message);
      ("location", loc);
      ("expression", expression);
      ("actual", actual);
    ] in
    json_error ~stage ~content
  | `Typer_bad_record_access (field,e,loc) ->
    let message = `String "invalid record field" in
    let field = Label.to_yojson field in
    let value = Ast_typed.expression_to_yojson e in
    let loc = `String (Format.asprintf "%a" Location.pp loc) in
    let content = `Assoc [
      ("message", message); ("location", loc);
      ("value", value);
      ("field", field);
    ] in
    json_error ~stage ~content
  | `Typer_expression_tracer (e,err) ->
    let expression = `String (Format.asprintf "%a" Ast_core.PP.expression e) in
    let loc = `String (Format.asprintf "%a" Location.pp e.location) in
    let content = `Assoc [
      ("location", loc);
      ("expression", expression);
      ("children", error_jsonformat err);
    ] in
    json_error ~stage ~content
  | `Typer_assert_equal (loc,expected,actual) ->
    let message = `String "bad types" in
    let expected = Ast_typed.type_expression_to_yojson (type_improve expected) in
    let actual = Ast_typed.type_expression_to_yojson (type_improve actual) in
    let content = `Assoc [
      ("location", Location.to_yojson loc);
      ("message" , message);
      ("expected", expected);
      ("actual"  , actual);
    ] in
    json_error ~stage ~content
  | `Typer_corner_case desc ->
    let message = `String desc in
    let content = `Assoc [
      ("message", message);
    ] in
    json_error ~stage ~content
  | `Typer_bad_collect_loop (t,loc) ->
    let message = `String "Loops over collections expect lists, sets or maps" in
    let actual = `String (Format.asprintf "%a" Ast_typed.PP.type_expression t) in
    let loc = `String (Format.asprintf "%a" Location.pp loc) in
    let content = `Assoc [
      ("message", message);
      ("location", loc);
      ("actual", actual);
    ] in
    json_error ~stage ~content
  | `Typer_expected_record (loc,t) ->
    let message = `String "expected a record" in
    let value = `String (Format.asprintf "%a" Ast_typed.PP.type_expression t) in
    let content = `Assoc [
      ("location", Location.to_yojson loc);
      ("message", message);
      ("value", value);
    ] in
    json_error ~stage ~content
  | `Typer_expected_variant (loc,t) ->
    let message = `String "expected a record" in
    let value = `String (Format.asprintf "%a" Ast_typed.PP.type_expression t) in
    let content = `Assoc [
      ("message", message);
      ("location", Location.to_yojson loc);
      ("value", value);
    ] in
    json_error ~stage ~content
  | `Typer_wrong_param_number (loc,name,expected,actual) ->
    let message = `String "constant with a wrong number of parameter" in
    let value = `String name in
    let expected = `Int expected in
    let actual = `Int (List.length actual) in
    let content = `Assoc [
      ("message", message);
      ("location", Location.to_yojson loc);
      ("value", value);
      ("actual", actual);
      ("expected", expected);
    ] in
    json_error ~stage ~content
  | `Typer_expected_map (loc,e) ->
    let message = `String "expected a map" in
    let content = `Assoc [
      ("message", message);
      ("location", Location.to_yojson loc);
      ("value", Ast_typed.type_expression_to_yojson e);
    ] in
    json_error ~stage ~content
  | `Typer_expected_option (loc,e) ->
    let message = `String "expected an option" in
    let content = `Assoc [
      ("message", message);
      ("location", Location.to_yojson loc);
      ("value", Ast_typed.type_expression_to_yojson e);
    ] in
    json_error ~stage ~content
  | `Typer_not_matching (loc,t1,t2) ->
    let message = `String "types not matching" in
    let content = `Assoc [
      ("message", message);
      ("location", Location.to_yojson loc);
      ("value_1", Ast_typed.type_expression_to_yojson t1);
      ("value_2", Ast_typed.type_expression_to_yojson t2);
    ] in
    json_error ~stage ~content
  | `Typer_not_annotated _ ->
    let message = `String "not annotated" in
    let content = `Assoc [
      ("message", message);
    ] in
    json_error ~stage ~content
  | `Typer_typeclass_error (loc,exps,acts) ->
    let open Simple_utils.PP_helpers in
    let printl printer ppf args =
      Format.fprintf ppf "%a" (list_sep printer (const " , ")) args in
    let message = `String "typeclass error" in
    let expected = `String (Format.asprintf "%a" (list_sep (printl Ast_typed.PP.type_expression) (const " or ")) exps) in
    let actual = `String (Format.asprintf "%a" (list_sep Ast_typed.PP.type_expression (const " or ")) acts) in
    let content = `Assoc [
      ("message", message);
      ("location", Location.to_yojson loc);
      ("expected", expected);
      ("actual", actual);
    ] in
    json_error ~stage ~content
  | `Typer_expected (loc,exps,acts) ->
    let open Simple_utils.PP_helpers in
    let message = `String "expected type" in
    let expected = `String (Format.asprintf "%a" (list_sep Ast_typed.PP.type_expression (const ", ")) exps) in
    let actual = `String (Format.asprintf "%a" (list_sep Ast_typed.PP.type_expression (const ", ")) acts) in
    let content = `Assoc [
      ("message", message);
      ("location", Location.to_yojson loc);
      ("expected", expected);
      ("actual", actual);
    ] in
    json_error ~stage ~content
  | `Typer_uncomparable_types (loc,a,b) ->
    let message = `String "those two types are not comparable" in
    let t1 = `String (Format.asprintf "%a" Ast_typed.PP.type_expression a) in
    let t2 = `String (Format.asprintf "%a" Ast_typed.PP.type_expression b) in
    let content = `Assoc [
      ("message", message);
      ("location", Location.to_yojson loc);
      ("type_1", t1);
      ("type_2", t2);
    ] in
    json_error ~stage ~content
  | `Typer_comparator_composed (loc,_a) ->
    let message = `String "Only composed types of not more than two element are allowed to be compared" in
    let content = `Assoc [
      ("message", message);
      ("location", Location.to_yojson loc);
    ] in
    json_error ~stage ~content
  | `Typer_pattern_do_not_conform_type (p,t) ->
    let message = `String "pattern not of the expected type" in
    let pattern = (Pattern.to_yojson Ast_core.type_expression_option_to_yojson) p in
    let t = Ast_typed.type_expression_to_yojson t in
    let content = `Assoc [
      ("message", message);
      ("type", t);
      ("pattern", pattern);
      ("location", Location.to_yojson p.location);
    ] in
    json_error ~stage ~content
  | `Typer_pattern_missing_cases (loc,syntax,ps) ->
    let message = `String "pattern-matching is not exhaustive." in
    let patterns = List.map ps ~f:(fun p ->
      `String (Desugaring.Decompiler.decompile_pattern_to_string ~syntax p)) in
    let content = `Assoc [
      ("message", message);
      ("patterns", `List patterns);
      ("location", Location.to_yojson loc);
    ] in
    json_error ~stage ~content
  | `Typer_pattern_redundant_case loc ->
    let message = `String "redundant case in pattern-matching" in
    let content = `Assoc [
      ("message", message);
      ("location", Location.to_yojson loc);
    ] in
    json_error ~stage ~content
  | `Typer_constant_since_protocol (loc, constant, protocol) ->
    let protocol_name = Environment.Protocols.variant_to_string protocol in
    let message = `String (Format.asprintf "%s is supported in protocol %s onwards. Hint: pass the compiler option `--protocol %s`" constant (String.capitalize protocol_name) protocol_name) in
    let content = `Assoc [
      ("message", message);
      ("location", Location.to_yojson loc);
    ] in
    json_error ~stage ~content
