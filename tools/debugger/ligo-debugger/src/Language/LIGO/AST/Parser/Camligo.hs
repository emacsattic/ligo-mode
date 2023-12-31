-- TODO: recogniser does not recognize maps and bigmaps properly

module Language.LIGO.AST.Parser.Camligo
  ( recognise
  ) where

import Data.Default (def)
import Prelude hiding (Alt)

import Duplo.Tree

import Language.LIGO.AST.Skeleton
import Language.LIGO.ParseTree
import Language.LIGO.Parser

recognise :: SomeRawTree -> ParserM (SomeLIGO Info)
recognise (SomeRawTree dialect rawTree)
  = fmap (SomeLIGO dialect)
  $ flip (descent (error "Camligo.recognise")) rawTree
  $ map usingScope
  [ -- Contract
    Descent do
      boilerplate $ \case
        "source_file" -> RawContract <$> fields "declaration"
        _             -> fallthrough

  , Descent do
      boilerplate $ \case
        "fun_decl"  -> BFunction <$> flag "recursive" <*> field "name" <*> fields "type_name" <*> fields "arg" <*> fieldOpt "type" <*> field "body"
        "let_decl"  -> BConst    <$> flag "recursive" <*> field "name" <*> fields "type_name" <*> fieldOpt "type" <*> fieldOpt "body"
        "p_include" -> BInclude  <$>                      field "filename"
        "p_import"  -> BImport   <$>                      field "filename" <*> field "alias"
        "type_decl" -> BTypeDecl <$> field "name"     <*> fieldOpt "params" <*> field "type"
        "module_decl"  -> BModuleDecl <$> field "moduleName" <*> fields "declaration"
        "module_alias" -> BModuleAlias <$> field "moduleName" <*> fields "module"
        _           -> fallthrough

    -- QuotedTypeParams
  , Descent do
      boilerplate \case
        "quoted_type_param"  -> QuotedTypeParam  <$> field  "param"
        "quoted_type_params" -> QuotedTypeParams <$> fields "param"
        _                    -> fallthrough

  , Descent do
      boilerplate $ \case
        "let_in" -> Let <$> field "decl" <*> field "body"
        _        -> fallthrough

  --   -- Expr
  , Descent do
      boilerplate $ \case
        "fun_app"           -> Apply      <$> field  "f"         <*> fields "x"
        "record_expr"       -> RecordUpd  <$> field  "subject"   <*> fields "field"
        "record_literal"    -> Record     <$> fields "field"
        "if_expr"           -> If         <$> field  "condition" <*> field "then"  <*> fieldOpt "else"
        "match_expr"        -> Case       <$> field  "subject"   <*> fields "alt"
        "lambda_expr"       -> Lambda     <$> fields "arg" <*> fields "type_name" <*> fieldOpt "type" <*> field "body"
        "list_expr"         -> List       <$> fields "item"
        "tup_expr"          -> Tuple      <$> fields "x"
        "paren_expr"        -> Paren      <$> field  "expr"
        "block_expr"        -> Seq        <$> fields "item"
        "annot_expr"        -> Annot      <$> field  "expr"      <*> field "type"
        "binary_op_app"     -> BinOp      <$> field  "left"      <*> field "op"    <*> field "right"
        "unary_op_app"      -> UnOp       <$> field  "negate"    <*> field "arg"
        "code_inj"          -> CodeInj    <$> field  "lang"      <*> field "code"
        _                   -> fallthrough

    -- QualifiedName
  , Descent do
      boilerplate $ \case
        "data_projection" -> QualifiedName <$> field "box" <*> fields "accessor"
        _                 -> fallthrough


    -- Pattern
  , Descent do
      boilerplate $ \case
        "list_pattern"      -> IsList   <$> fields "item"
        "list_con_pattern"  -> IsCons   <$> field  "x"    <*> field "xs"
        "tuple_pattern"     -> IsTuple  <$> fields "item"
        "constr_pattern"    -> IsConstr <$> field  "ctor" <*> fieldOpt "args"
        "par_annot_pattern" -> IsAnnot  <$> field  "pat"  <*> field "type"
        "paren_pattern"     -> IsParen  <$> field  "pat"
        "var_pattern"       -> IsVar    <$> field  "var"
        "record_pattern"    -> IsRecord <$> fields "field"
        "wildcard_pattern"  -> pure IsWildcard
        _                   -> fallthrough

    -- Irrefutable
  , Descent do
      boilerplate $ \case
        "irrefutable_tuple"  -> IsTuple <$> fields "item"
        "annot_pattern"      -> IsAnnot <$> field  "pat"  <*> field "type"
        "closed_irrefutable" -> IsParen <$> field  "pat"
        _                    -> fallthrough

   -- RecordFieldPattern
  , Descent do
      boilerplate $ \case
        "record_field_pattern"   -> IsRecordField <$> field "name" <*> field "body"
        "record_capture_pattern" -> IsRecordCapture <$> field "name"
        _                        -> fallthrough

    -- Alt
  , Descent do
      boilerplate $ \case
        "matching" -> Alt <$> field "pattern" <*> field  "body"
        _          -> fallthrough

    -- Record fields
  , Descent do
      boilerplate $ \case
        "record_assignment"      -> FieldAssignment <$> fields "accessor" <*> field "value"
        "record_path_assignment" -> FieldAssignment <$> fields "accessor" <*> field "value"
        "record_capture"         -> Capture <$> field "accessor"
        _                        -> fallthrough

  , Descent do
      boilerplate' $ \case
        ("+", _)      -> return $ Op "+"
        ("-", _)      -> return $ Op "-"
        ("mod", _)    -> return $ Op "mod"
        ("/", _)      -> return $ Op "/"
        ("*", _)      -> return $ Op "*"
        ("^", _)      -> return $ Op "^"
        ("::", _)     -> return $ Op "::"
        (">", _)      -> return $ Op ">"
        ("<", _)      -> return $ Op "<"
        (">=", _)     -> return $ Op ">="
        ("<=", _)     -> return $ Op "<="
        ("=", _)      -> return $ Op "="
        ("!=", _)     -> return $ Op "!="
        ("<>", _)     -> return $ Op "<>"
        ("||", _)     -> return $ Op "||"
        ("|>", _)     -> return $ Op "|>"
        ("&&", _)     -> return $ Op "&&"
        ("not", _)    -> return $ Op "not"
        ("lsl", _)    -> return $ Op "lsl"
        ("lsr", _)    -> return $ Op "lsr"
        ("land", _)   -> return $ Op "land"
        ("lor", _)    -> return $ Op "lor"
        ("lxor", _)   -> return $ Op "lxor"
        ("or", _)     -> return $ Op "or"
        _             -> fallthrough

    -- Literal
  , Descent do
      boilerplate' $ \case
        ("Int",    i) -> return $ CInt i
        ("Nat",    i) -> return $ CNat i
        ("Bytes",  i) -> return $ CBytes i
        ("String", i) -> return $ CString i
        ("Tez",    i) -> return $ CTez i
        _             -> fallthrough

    -- Verbatim
  , Descent do
      boilerplate' \case
        ("Verbatim", code) -> pure $ Verbatim code
        _                  -> fallthrough

    -- Name
  , Descent do
      boilerplate' $ \case
        ("Name", n) -> return $ Name n
        _           -> fallthrough

    -- NameDecl
  , Descent do
      boilerplate' $ \case
        ("NameDecl", n) -> return $ NameDecl n
        _               -> fallthrough

    -- ModuleName
  , Descent do
      boilerplate' $ \case
        ("ModuleName", n) -> return $ ModuleName n
        _                 -> fallthrough

    -- FieldName
  , Descent do
      boilerplate' $ \case
        ("FieldName", n) -> return $ FieldName n
        _                -> fallthrough

    -- Type
  , Descent do
      boilerplate $ \case
        "string_type"  -> TString  <$> field  "value"
        "fun_type"     -> TArrow   <$> field  "domain" <*> field "codomain"
        "prod_type"    -> TProduct <$> fields "x"
        "app_type"     -> TApply   <$> field  "f"      <*> fields "x"
        "record_type"  -> TRecord def <$> fields "field"
        "tuple_type"   -> TProduct <$> fields "x"
        "TypeWildcard" -> pure TWildcard
        "var_type"     -> TVariable <$> field "name"
        "sum_type_prod_type_level" -> TSum def <$> fields1 "variant"
        "sum_type_fun_type_level"  -> TSum def <$> fields1 "variant"
        _              -> fallthrough

    -- Module access:
  , Descent do
      boilerplate $ \case
        "module_TypeName" -> ModuleAccess <$> fields "path" <*> field "type"
        "module_access"   -> ModuleAccess <$> fields "path" <*> field "field"
        _                 -> fallthrough

    -- Variant
  , Descent do
      boilerplate $ \case
        "variant_prod_type_level" -> Variant <$> field "constructor" <*> fieldOpt "type"
        "variant_fun_type_level"  -> Variant <$> field "constructor" <*> fieldOpt "type"
        _                         -> fallthrough

    -- TField
  , Descent do
      boilerplate $ \case
        "field_decl" -> TField <$> field "field" <*> (Just <$> field "type")
        _            -> fallthrough

    -- TypeName
  , Descent do
      boilerplate' $ \case
        ("TypeName", name) -> return $ TypeName name
        _                  -> fallthrough

    -- TypeVariableName
  , Descent do
      boilerplate' \case
        ("TypeVariableName", name) -> pure $ TypeVariableName name
        _                          -> fallthrough

    -- Preprocessor
  , Descent do
      boilerplate \case
        "preprocessor" -> Preprocessor <$> field "preprocessor_command"
        _              -> fallthrough

    -- ProcessorCommand
  , Descent do
      boilerplate' \case
        ("p_if"      , rest) -> return $ PreprocessorCommand $ "#if "      <> rest
        ("p_error"   , rest) -> return $ PreprocessorCommand $ "#error "   <> rest
        ("p_warning" , rest) -> return $ PreprocessorCommand $ "#warning " <> rest
        ("p_define"  , rest) -> return $ PreprocessorCommand $ "#define "  <> rest
        _                    -> fallthrough

    -- Ctor
  , Descent do
      boilerplate' $ \case
        ("ConstrName", name) -> return $ Ctor name
        ("False", _)         -> return $ Ctor "False"
        ("True", _)          -> return $ Ctor "True"
        ("Unit", _)          -> return $ Ctor "Unit"
        _                    -> fallthrough

  -- Attr
  , Descent $
      boilerplate' \case
        ("Attr", attr) -> pure $ Attr attr
        _              -> fallthrough

  -- Err
  , Descent noMatch
  ]
