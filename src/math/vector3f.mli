(* Operations on immutable 3 floats vectors *)

type t = {x : float; y : float; z : float}

val zero : t

val unit_x : t

val unit_y : t

val unit_z : t

val add : t -> t -> t

val sub : t -> t -> t

val prop : float -> t -> t

val div : float -> t -> t

val floor : t -> Vector3i.t

val from_int : Vector3i.t -> t

val project : t -> Vector2f.t

val lift : Vector2f.t -> t

val dot : t -> t -> float

val product : t -> t -> t

val cross : t -> t -> t

val angle : t -> t -> float

val squared_norm : t -> float

val norm : t -> float

val clamp : t -> t -> t -> t

val map : t -> (float -> float) -> t

val map2 : t -> t -> (float -> float -> float) -> t

val max : t -> float

val min : t -> float

val normalize : t -> t

val print : t -> string

(* Returns the normalized direction vector from point1 to point 2 
 * Equivalent to normalize @ sub *)
val direction : t -> t -> t

(* Returns the point u + tv *)
val endpoint : t -> t -> float -> t

