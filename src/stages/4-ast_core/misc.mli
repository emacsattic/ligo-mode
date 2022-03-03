open Types

val assert_value_eq : ( expression * expression ) -> unit option
val is_value_eq : ( expression * expression ) -> bool
val assert_type_expression_eq : ( type_expression * type_expression ) -> unit option
val merge_annotation :
  type_expression option ->
  type_expression option ->
  (type_expression * type_expression -> 'a option) -> type_expression option
val type_expression_eq : ( type_expression * type_expression ) -> bool

val equal_variables : expression -> expression -> bool

module Free_variables : sig
  type bindings = expression_variable list

  val matching_expression : bindings -> (expression, type_expression) match_case list -> bindings
  val lambda : bindings -> (expression,type_expression) lambda -> bindings

  val expression : bindings -> expression -> bindings

  val empty : bindings
  val singleton : expression_variable -> bindings
end

val assert_list_eq : ('a -> 'a -> unit option) -> 'a list -> 'a list -> unit option
val assert_eq : 'a -> 'a -> unit option
