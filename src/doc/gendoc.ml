open Lexing
open AST

exception DocError

let curr_doc = ref None

let curr_chan : out_channel option ref = ref None

let curr_subdir = ref "."

let curr_prefix = ref ""

let curr_module = ref ""

let reset () = 
  curr_doc    := None;
  curr_chan   := None;
  curr_subdir := ".";
  curr_prefix := "";
  curr_module := ""

let get_chan () = 
  match !curr_chan with
  |None -> assert false
  |Some c -> c

let get_doc () = 
  match !curr_doc with
  |None -> ""
  |Some c -> curr_doc := None; c

let begin_module () = 
  Printf.fprintf (get_chan ())
"---
modulename: %s 
prefix: %s
abstract: %s
---\n\n"
  !curr_module !curr_prefix (get_doc ())

let make_field s (values, vtype) = 
  Printf.fprintf (get_chan ())
"{%% capture listing %%}
%s
{%% endcapture %%}
{%% capture description %%}
%s
{%% endcapture %%}
%s
{%% include docelem.html listing=listing description=description %s %%}\n\n"
  s (get_doc ()) values vtype



let my_mkdir s = 
  try Unix.mkdir s 0o777
  with Unix.Unix_error(Unix.EEXIST, _, _) -> ()

let rec concat_sep sep to_str = function
  |[] -> ""
  |[t] -> to_str t
  |h::t -> (to_str h) ^ sep ^ (concat_sep sep to_str t)

let rec type_param_to_string = function
  | ParamTuple l -> Printf.sprintf "(%s)" (concat_sep ", " type_param_to_string l)
  | Polymorphic s -> Printf.sprintf "'%s" s

let rec type_expr_simple = function
  | Arrow _ -> false
  | _ -> true
  
let rec type_expr_to_string = function
  | ModuleType (s,e) -> Printf.sprintf "%s.%s" s (type_expr_to_string e)
  | AtomType s -> s
  | Record l -> 
      let record_param_to_string (a,b) = Printf.sprintf "%s : %s" a (type_expr_to_string b) in
      Printf.sprintf "{%s}" (concat_sep "; " record_param_to_string l)
  | PolyVariant (v,l) ->
      let variant_param_to_string (a,b) = 
        match b with
        |Some b -> Printf.sprintf "`%s of %s" a (type_expr_to_string b)
        |None -> Printf.sprintf "`%s" a
      in
      begin match v with
      |Lower   -> Printf.sprintf "[< %s]" (concat_sep " | " variant_param_to_string l)
      |Greater -> Printf.sprintf "[> %s]" (concat_sep " | " variant_param_to_string l)
      |Equals  -> Printf.sprintf "[%s]" (concat_sep " | " variant_param_to_string l)
      end
  | PolyType s -> Printf.sprintf "'%s" s
  | Arrow (t1,t2) -> 
      if type_expr_simple t1 then Printf.sprintf "%s -> %s" (type_expr_to_string t1) (type_expr_to_string t2)
      else Printf.sprintf "(%s) -> %s" (type_expr_to_string t1) (type_expr_to_string t2)
  | TypeTuple tl ->
      Printf.sprintf "(%s)" (concat_sep " * " type_expr_to_string tl)
  | NamedParam (s,t) ->
      if type_expr_simple t then Printf.sprintf "%s:%s" s (type_expr_to_string t)
      else Printf.sprintf "%s:(%s)" s (type_expr_to_string t)
  | OptionalParam (s,t) ->
      if type_expr_simple t then Printf.sprintf "?%s:%s" s (type_expr_to_string t)
      else Printf.sprintf "?%s:(%s)" s (type_expr_to_string t)
  | Variant l ->
      let variant_param_to_string (a,b) = 
        match b with
        |Some b -> Printf.sprintf "%s of %s" a (type_expr_to_string b) 
        |None -> a
      in
      if List.length l <= 5 then 
        "\n| " ^ concat_sep "\n| " variant_param_to_string l
      else 
        "..."
  | ParamType (t1, t2) ->
      Printf.sprintf "%s %s" (type_expr_to_string t1) (type_expr_to_string t2)

let rec field_to_string = function
  |AbstractType (opt,s) -> begin
    match opt with
    |None -> Printf.sprintf "type %s" s
    |Some o -> Printf.sprintf "type %s %s" (type_param_to_string o) s
  end
  |ConcreteType (opt, s, exp) -> begin
    match opt with
    |None -> Printf.sprintf "type %s = %s" s (type_expr_to_string exp)
    |Some o -> Printf.sprintf "type %s %s = %s" (type_param_to_string o) s (type_expr_to_string exp)
  end
  |Value (s, expr) -> Printf.sprintf "val %s : %s" s (type_expr_to_string expr)
  |Exn (s, opt) -> begin
    match opt with
    |None -> Printf.sprintf "exception %s" s
    |Some o -> Printf.sprintf "exception %s of %s" s (type_expr_to_string o)
  end
  | _ -> assert false

let rec field_info = function
  |ConcreteType (_, _, Variant v) -> begin
    List.fold_left (fun str (s, opt) ->
      let data = 
        match opt with
        |None -> s
        |Some b -> Printf.sprintf "%s of %s" s (type_expr_to_string b)
      in
      Printf.sprintf "%s{%% include add_value.html value=\"%s\" %%}\n" str data
    ) "" v, "values=values"
  end
  |ConcreteType (_, _, Record r) -> begin
    List.fold_left (fun str (s, t) ->
      let data = Printf.sprintf "%s : %s" s (type_expr_to_string t) in
      Printf.sprintf "%s{%% include add_value.html value=\"%s\" %%}\n" str data 
    ) "" r, "struct_values=values"
  end
  | _ -> "", ""

let rec document_ast = function
  |[] -> ()
  |Comment _ :: t -> 
    document_ast t
  |Documentation s :: t -> 
    begin 
      match !curr_doc, !curr_chan with
      | _, None |None, _ -> ()
      |Some t, Some c -> Printf.fprintf c "\n## %s\n" t
    end;
    curr_doc := Some s;
    document_ast t
  |Title s :: t ->
    begin
      match !curr_chan with
      |None -> ()
      |Some c -> Printf.fprintf c "### %s\n\n" s
    end;
    document_ast t
  |Module (s,l) :: t -> 
    let backup_dir = !curr_subdir in
    let backup_prefix = !curr_prefix in
    let backup_module = !curr_module in
    let backup_chan = !curr_chan in
    my_mkdir !curr_subdir;
    Unix.chdir !curr_subdir;
    curr_prefix := 
      if !curr_prefix = "" then !curr_module
      else !curr_prefix ^ "." ^ !curr_module;
    curr_module := s;
    curr_subdir := String.lowercase s;
    let chan = open_out (String.lowercase s ^ ".md") in
    curr_chan   := Some chan;
    begin_module ();
    document_ast l;
    Unix.chdir "..";
    curr_prefix := backup_prefix;
    curr_subdir := backup_dir;
    curr_module := backup_module;
    close_out chan;
    curr_chan   := backup_chan;
    document_ast t
  | f :: t -> 
    let str = field_to_string f in
    make_field str (field_info f);
    document_ast t

let print_position lexbuf =
  let pos = lexbuf.lex_curr_p in
  let str = Lexing.lexeme lexbuf in
  let begchar = pos.pos_cnum - pos.pos_bol + 1 in
  Printf.printf "In %s, line %d, characters %d-%d : %s"
    pos.pos_fname pos.pos_lnum begchar
    (begchar + (String.length str))
    (Lexing.lexeme lexbuf)

let parse_with_errors lexbuf =
  try
    Parser.file Lexer.token lexbuf
  with
    |Lexer.SyntaxError msg ->
        print_position lexbuf;
        Printf.printf " : %s" msg;
        print_endline "";
        raise DocError
    |Parser.Error ->
        print_position lexbuf;
        Printf.printf " : Syntax Error";
        print_endline "";
        raise DocError

let parse_from_file f = 
  let input = open_in f in
  let lexbuf = from_channel input in
  lexbuf.lex_curr_p <- {lexbuf.lex_curr_p with pos_fname = f};
  let ast = parse_with_errors lexbuf in
  close_in input;
  ast

let document f = 
  let ast = parse_from_file f in
  Unix.chdir "doc";
  let main_module = String.sub f 0 (String.rindex f '.') in
  let main_module = Str.string_after main_module (String.rindex main_module '/' + 1) in
  let new_dir = String.lowercase main_module in
  curr_module := String.capitalize main_module;
  curr_subdir := new_dir;
  document_ast ast;
  reset ();
  Unix.chdir ".."

let _ = 
  my_mkdir "doc";
  for i = 1 to Array.length Sys.argv - 1 do
    document Sys.argv.(i)
  done
