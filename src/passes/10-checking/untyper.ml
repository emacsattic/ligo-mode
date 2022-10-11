module Ligo_string = Simple_utils.Ligo_string
module Location    = Simple_utils.Location
module I = Ast_core
module O = Ast_typed
open Ligo_prim

let untype_value_attr : O.ValueAttr.t -> I.ValueAttr.t =
  fun {inline;no_mutation;view;public;hidden;thunk} -> {inline;no_mutation;view;public;hidden;thunk}
let rec untype_type_expression (t:O.type_expression) : I.type_expression =
  let self = untype_type_expression in
  let return t = I.make_t t in
  match t.type_content with
  | O.T_sum {fields ; layout} ->
      let aux ({associated_type ; michelson_annotation ; decl_pos} : O.row_element) =
        let associated_type = self associated_type in
        let v' = ({associated_type ; michelson_annotation ; decl_pos} : I.row_element) in
        v' in
      let x' = Record.map aux fields in
      return @@ I.T_sum { fields = x' ; layout = Some layout }
  | O.T_record {fields;layout} -> (
    let aux ({associated_type ; michelson_annotation ; decl_pos} : O.row_element) =
      let associated_type = self associated_type in
      let v' = ({associated_type ; michelson_annotation ; decl_pos} : I.row_element) in
      v' in
    let x' = Record.map aux fields in
    return @@ I.T_record {fields = x' ; layout = Some layout}
  )
  | O.T_variable name -> return @@ I.T_variable name
  | O.T_arrow arr ->
    let arr = Arrow.map self arr in
    return @@ I.T_arrow arr
  | O.T_constant {language=_;injection;parameters} ->
    let arguments = List.map ~f:self parameters in
    let type_operator = Type_var.fresh ~name:(Literal_types.to_string injection) () in
    return @@ I.T_app {type_operator;arguments}
  | O.T_singleton l ->
    return @@ I.T_singleton l
  | O.T_abstraction x ->
    let x = Abstraction.map self x in
    return @@ T_abstraction x
  | O.T_for_all x ->
    let x = Abstraction.map self x in
    return @@ T_for_all x

let untype_type_expression_option = fun x -> Option.return @@ untype_type_expression x

let rec untype_expression (e:O.expression) : I.expression =
  untype_expression_content e.expression_content
and untype_expression_content (ec:O.expression_content) : I.expression =
  let open I in
  let self = untype_expression in
  let self_type = untype_type_expression in
  let self_type_opt = untype_type_expression_option in
  let return e = e in
  match ec with
  | E_literal l ->
      return (e_literal l)
  | E_constant {cons_name;arguments} ->
      let lst' = List.map ~f:self arguments in
      return (e_constant cons_name lst')
  | E_variable n ->
      return (e_variable (n))
  | E_application {lamb;args} ->
      let f' = self lamb in
      let arg' = self args in
      return (e_application f' arg')
  | E_lambda {binder ; output_type; result} -> (
      let binder = Param.map self_type_opt binder in
      let output_type = self_type_opt output_type in
      let result = self result in
      return (e_lambda binder output_type result)
    )
  | E_type_abstraction {type_binder;result} -> (
    let result = self result in
    return (e_type_abs type_binder result)
  )
  | E_constructor {constructor; element} ->
      let p' = self element in
      return (e_constructor constructor p')
  | E_record r ->
    let r' = Record.map self r in
    return (e_record r' ())
  | E_accessor {struct_; path} ->
      let r' = self struct_ in
      let Label s = path in
      return (e_record_accessor r' (Label s))
  | E_update {struct_=r; path=Label l; update=e} ->
    let r' = self r in
    let e = self e in
    return (e_record_update r' (Label l) e)
  | E_matching {matchee;cases} ->
    let matchee = self matchee in
    let cases = List.map cases 
      ~f:(O.Match_expr.map_match_case 
            untype_expression untype_type_expression_option) in
    let cases = List.map cases 
      ~f:(fun {pattern;body} -> 
        let pattern = O.Helpers.Conv.o_to_i pattern in
        I.Match_expr.{pattern;body}) in
    return (e_matching matchee cases)
  | E_let_in {let_binder;rhs;let_result; attr} ->
      let tv = self_type rhs.type_expression in
      let rhs = self rhs in
      let result = self let_result in
      let attr : ValueAttr.t = untype_value_attr attr in
      return (e_let_mut_in (Binder.map (Fn.const @@ Some tv) let_binder) rhs result attr)
  | E_mod_in {module_binder;rhs;let_result} ->
      let rhs = untype_module_expr rhs in
      let result = self let_result in
      return @@ e_mod_in module_binder rhs result
  | E_raw_code {language; code} ->
      let code = self code in
      return (e_raw_code language code)
  | E_recursive {fun_name;fun_type; lambda} ->
      let fun_type = self_type fun_type in
      let lambda = Lambda.map self self_type lambda in
      return @@ e_recursive fun_name fun_type lambda
  | E_module_accessor ma -> return @@ I.make_e @@ E_module_accessor ma
  | E_let_mut_in {let_binder;rhs;let_result; attr} ->
    let tv = self_type rhs.type_expression in
    let rhs = self rhs in
    let result = self let_result in
    let attr : ValueAttr.t = untype_value_attr attr in
    return (e_let_in (Binder.map (Fn.const @@ Some tv) let_binder) rhs result attr)
  | E_assign a ->
    let a = Assign.map self self_type_opt a in
    return @@ make_e @@ E_assign a
  | E_for for_loop ->
    let for_loop = For_loop.map self for_loop in
    return @@ I.make_e @@ E_for for_loop
  | E_for_each for_each_loop ->
    let for_each_loop = For_each_loop.map self for_each_loop in
    return @@ I.make_e @@ E_for_each for_each_loop
  | E_while while_loop ->
    let while_loop = While_loop.map self while_loop in
    return @@ I.make_e @@ E_while while_loop
  | E_deref var ->
    return @@ I.make_e @@ E_variable var
  | E_type_inst {forall;type_=type_inst} ->
    match forall.type_expression.type_content with
    | T_for_all {ty_binder;type_;kind=_} ->
      let type_ = Ast_typed.Helpers.subst_type ty_binder type_inst type_ in
      let forall = { forall with type_expression = type_ } in
      self forall
    | T_arrow _ ->
      (* This case is used for external typers *)
      self forall
    | _ ->
      failwith "Impossible case: cannot untype a type instance of a non polymorphic type"

and untype_module_expr : O.module_expr -> I.module_expr =
  fun module_expr ->
    let return wrap_content : I.module_expr = { module_expr with wrap_content } in
    match module_expr.wrap_content with
    | M_struct prg ->
      let prg = untype_module prg in
      return (M_struct prg)
    | M_module_path path ->
      return (M_module_path path)
    | M_variable v ->
      return (M_variable v)
and untype_declaration_constant : (O.expression -> I.expression) -> _ O.Value_decl.t -> _ I.Value_decl.t =
  fun untype_expression {binder;expr;attr} ->
    let ty = untype_type_expression expr.O.type_expression in
    let binder = Binder.map (Fn.const @@ Some ty) binder in
    let expr = untype_expression expr in
    let expr = I.e_ascription expr ty in
    let attr = untype_value_attr attr in
    {binder;attr;expr;}

and untype_declaration_type : _ O.Type_decl.t -> _ I.Type_decl.t =
  fun {type_binder; type_expr; type_attr={public;hidden}} ->
    let type_expr = untype_type_expression type_expr in
    let type_attr = ({public;hidden}: I.TypeOrModuleAttr.t) in
    {type_binder; type_expr; type_attr}

and untype_declaration_module : _ O.Module_decl.t -> _ I.Module_decl.t =
  fun {module_binder; module_; module_attr={public;hidden}} ->
    let module_ = untype_module_expr module_ in
    let module_attr = ({public;hidden}: I.TypeOrModuleAttr.t) in
    {module_binder; module_ ; module_attr}

and untype_declaration =
  let return (d: I.declaration_content) = d in
  fun (d: O.declaration_content) -> match d with
  | D_value dc ->
    let dc = untype_declaration_constant untype_expression dc in
    return @@ D_value dc
  | D_type dt ->
    let dt = untype_declaration_type dt in
    return @@ D_type dt
  | D_module dm ->
    let dm = untype_declaration_module dm in
    return @@ D_module dm

and untype_decl : O.decl -> I.decl = fun d -> Location.map untype_declaration d

and untype_module : O.module_ -> I.module_ = fun p ->
  List.map ~f:(untype_decl) p

and untype_program : O.program -> I.program = fun p ->
  List.map ~f:(Location.map untype_declaration) p
