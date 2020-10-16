(* Driver for the CameLIGO parser *)

(* Vendor dependencies *)

module Region = Simple_utils.Region

(* Internal dependencies *)

module Comments = Lexer_cameligo.Comments
module File     = Lexer_cameligo.File
module Token    = Lexer_cameligo.Token
module CST      = Cst.Cameligo
module ParErr   = Parser_msg

(* CLIs *)

module Preproc_CLI = Preprocessor.CLI.Make (Comments)
module   Lexer_CLI =     LexerLib.CLI.Make (Preproc_CLI)
module  Parser_CLI =    ParserLib.CLI.Make (Lexer_CLI)

(* Renamings on the parser generated by Menhir to suit the functor. *)

module Parser =
  struct
    include Parser_cameligo.Parser
    type tree = CST.t

    let main = contract

    module Incremental =
      struct
        let main = Incremental.contract
      end
  end

module Pretty =
  struct
    include Parser_cameligo.Pretty
    type tree = CST.t
  end

module Printer =
  struct
    include Cst_cameligo.Printer
    type tree = CST.t
  end

(* Finally... *)

module Main = Shared.ParserMainGen.Make
                (Comments)
                (File)
                (Token)
                (CST)
                (Parser)
                (ParErr)
                (Printer)
                (Pretty)
                (Parser_CLI)

let () = Main.check_cli ()
let () = Main.parse ()
