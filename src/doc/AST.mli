type module_field = 
  | Comment of string
  | Documentation of string
  | Title of string
  | AbstractType of (type_param option * string)
  | ConcreteType of (type_param option * string * type_expr)
  | Value of string * type_expr
  | Exn of string * (type_expr option)
  | Module of string * (module_field list)

and variance = 
  | Lower 
  | Greater
  | Equals

and type_param = 
  | ParamTuple of type_param list
  | Polymorphic of string

and type_expr = 
  | ModuleType of string * type_expr
  | AtomType of string
  | Record of (string * type_expr) list
  | PolyVariant of variance * ((string * type_expr option) list)
  | PolyType of string
  | Arrow of type_expr * type_expr
  | TypeTuple of type_expr * type_expr
  | NamedParam of string * type_expr
  | OptionalParam of string * type_expr
  | Variant of (string * type_expr option) list
  | ParamType of (type_expr * type_expr)

