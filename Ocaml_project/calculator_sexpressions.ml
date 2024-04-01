(* Honor code comes here:

   First Name: Can 
   Last Name: Erozer
   BU ID: U40104182

   I pledge that this program represents my own program code and that I have
   coded on my own. I received help from no one in designing and debugging my
   program. I have read the course syllabus of CS 320 and have read the sections
   on Collaboration and Academic Misconduct. I also understand that I may be
   asked to meet the instructor or the TF for a follow up interview on Zoom. I
   may be asked to explain my solution in person and may also ask you to solve a
   related problem.
*)

(* IMPORTANT

   Problems that do not satisfy requirements will have points deducted from your
   Gradescope score during manual grading.

   Requirements for the assignemnt.
   * You may NOT add or remove the 'rec' keyword.
   * Your helper functions may NOT use the 'rec' keyword.
   * You may not use built-in @.
   * You may not use ANY standard library functions.
   * You may not use standard library functions (List.*, Option.*, etc.)
*)

(******************************************************************************)
(* PRELUDE - Part 0 - Introduction

   In this assignment, rather than working on individual problems, you will be
   working through one longer problem to prepare you for the interpreter
   assignment.

   - 'DONE' :: code marked with 'DONE' are given functions which you may use
     throughout the rest of the assignment.

   - 'TODO' :: code marked 'TODO' is just that: you are expected to provide the
     implementation, so you may use the function throughout the rest of the
     assignment.

   - 'EXAMPLE' :: code marked 'EXAMPLE' are given, but are not relevant
     throughout the rest of the assignment.

   The assignment is to be done in order, reading through provided code to
   understand what is going on. Further, there are some functions which allow
   you to easily test sections in utop/ocaml. MAKE USE OF TESTING IN UTOP/OCAML!
 ********************************************)

(* DONE Wrap empty list constructor. *)
let nil: 'a list = []
(* DONE Wrap cons operator. *)
let cons (h : 'a) (t : 'a list) = h :: t

(* DONE Operator for function composition.

   This is useful any time you write (fun x -> f (g x)). You may now write
   f % g.

   Example: (((+) 1) % ((-) 2)) 4 = (2 - 4) + 1 = -1
*)
let (%) (f : 'a -> 'b) (g : 'c -> 'a): 'c -> 'b =
  fun x -> f (g x)

(* DONE Operator to reverse the arguments of a function.

   Example: flip cons [2; 3] 1 = [1; 2; 3]
*)
let flip (f : 'a -> 'b -> 'c): 'b -> 'a -> 'c =
  fun b a -> f a b

(*******************************************)

(* TODO #0.0 Implement fold_left on lists. *)
let rec fold_left (f : 'a -> 'b -> 'b) (acc : 'b) (ls : 'a list): 'b =
  match ls with
    []->acc
  |
    h::t->fold_left f (f h acc) t

(* TODO #0.1 Implement reverse on lists. *)
let reverse (ls : 'a list): 'a list = fold_left cons nil ls

(* TODO #0.2 Implement map on lists. *)
let map (f : 'a -> 'b) (ls : 'a list): 'b list =
  reverse (fold_left (fun x rest->(f x) :: rest) [] ls)

(* TODO #0.3 Implement append on lists. *)
let append (l1 : 'a list) (l2 : 'a list): 'a list =
  fold_left (fun x rest->x::rest) l2 (reverse l1)

(* DONE *)
(* We may define operators ourselves, let us do so for append! *)
let (@) = append

(******************************************************************************)
(* Binary Trees and General Trees - Part 1

   We define a binary tree data type.

   A binary tree is either a node, which has two children (hence binary), or a
   leaf, which stores the values. We can visually an int tree:

          .
         / \
        2   .
           / \
         -1   4
 ********************************************)

type 'a tree =
  | Leaf of 'a
  | Node of 'a tree * 'a tree

(* DONE *)
let leaf (x : 'a) = Leaf(x)
(* DONE *)
let node (l : 'a tree) (r : 'a tree) = Node(l, r)

(* TODO #1.1 Define a fold function on trees. This function takes in two
   function arguments: one to apply on nodes and one to apply on leafs. Think of
   it as a combination and transformation/mapping steps.

   Examples:
   fold_tree ( * ) (fun x -> x) (node (leaf 3) (node (leaf 3) (leaf 2))) = 6
   fold_tree ( * ) (fun x -> x + 1) (node (leaf 3) (leaf 2)) = 12
*)
let rec fold_tree (f : 'b -> 'b -> 'b) (g : 'a -> 'b) (t : 'a tree): 'b =
  match t with
    Leaf x->g x
  |
    Node (left,right)-> f (fold_tree f g left) (fold_tree f g right)

(*******************************************
   We define a 'general tree' data type.

   General trees, unlike binary trees, have an arbitrary number of children.
   This is a special case of a Directed, Acyclic Graph (DAG) data type. But,
   unlike a DAG (or any graph), a node in a tree has only ONE parent.

   For example:
           .
         / | \
        2  .  3
          / \
        -1   .
          ///|\\\
          .......
 ********************************************)

type 'a gtree =
  | GLeaf of 'a
  | GNode of ('a gtree) list

let gleaf (x : 'a) = GLeaf(x)
let gnode (ls : 'a gtree list) = GNode(ls)

(* TODO #1.2 Define a fold function on this data type, this should be an
   equivalent operation to the fold_tree function above.

   Example:
   Given
     let sum_list = fold_left (+) 0

   fold_gtree sum_list (fun x -> x) (gnode [gleaf 3; gleaf 2]) = 5
   fold_gtree (sum_list) (fun x -> x + 1)
            (gnode [gnode [gleaf 1; gleaf 3]; gleaf 2])
     = 9
*)
let rec fold_gtree (f : 'b list -> 'b) (g : 'a -> 'b) (t : 'a gtree): 'b =
  match t with
    GLeaf x-> g x
  |
    GNode ls-> f (map (fun xx->fold_gtree f g xx) ls)

(* TODO #1.3 Define a map function on gtrees. 
   Examples:
   map_gtree ((+) 1) (gnode [gnode [gleaf 1; gleaf 3]; gleaf 2])
     = GNode [GNode [GLeaf 2; GLeaf 4]; GLeaf 3]
*)
let map_gtree (f : 'a -> 'b) (t : 'a gtree): 'b gtree =
  fold_gtree gnode (gleaf % f) t


(*let map_gtree1 (f : 'a -> 'b) (t : 'a gtree): 'b gtree =
  fold_gtree (fun x->GNode x) (fun y-> GLeaf (f y)) t     *)


(* TODO #1.4 Define a 'flatten' function on gtrees. Converting it into a list.
   Examples:
   flatten_gtree (gnode [gnode [gleaf 1; gleaf 3]; gleaf 2]) = [1; 3; 2]
*)


let flatten_gtree (t : 'a gtree): 'a list =
  fold_gtree (fun x->fold_left append [] (reverse x)) (fun y->[y]) t


(*******************************************
   A result is a type with two type parameters (list and option have one type
   parameter). Unlike option, which holds nothing or one thing, a result holds
   one thing or another thing.

   Result types let us represent errors better than option types, because we
   either have the value we expect or we have an error value.

   Specifically:

   type ('a, 'e) result =
     | Ok of 'a
     | Error of 'e

   Let us see an example:
*)

(* EXAMPLE *)
type numeric_err =
  | DivisionByZero
  | IDoNotLikeNegatives

(* EXAMPLE Safe divide, which can not go wrong, or be negative! *)
let divide (n : int) (m : int): (int, numeric_err) result =
  if n < 0 || m < 0 then
    Error(IDoNotLikeNegatives)
  else if m = 0 then
    Error(DivisionByZero)
  else
    Ok(n / m)

(*******************************************************************************
 * Part 2 - Symbolic expressions (sexprs)

   Way back in the 1950s John McCarthy created symbolic expressions [1], or
   s-expressions (abbreviated as sexprs). Sexprs were, and are still, used as the
   syntax for the LISP family of languages [2]. Sexprs are defined as:

   - an atom (a singular value)
   - an expression of the form (x . y) where x and y are both expressions

   This definition should remind you of a data type you have already seen. In
   fact, an s-expression is really just an 'atom tree'! (But not exactly, as we
   will see).

   What is an atom? It depends on the language you are trying to define; for now
   we will be defining a simple calculator language, so we will define atoms as a
   symbol (string) or a number (int). For example:
   (+ . (2 . (3 . 4))) is an sexpr.

   This notation is really cumbersome, so we would like to simplify it. We would
   much prefer to write: (+ 2 3 4). This is an arithmetic expressions using prefix
   or 'Polish' notation. This means the operator comes /before/ the inputs. The
   above then is equal to 9 (as (+ 2 3 4) = 2 + 3 + 4 = 9).

   This 'flattened' versions of sexprs is not actually very special. Notice, if we
   were allowed to have multiple types of data in a list in OCaml, this is the
   same transformation as "+"::(2::(3::(4::[]))) to ["+"; 2; 3; 4]. That is
   because LISP allows multiple types of data in a list. And it is /homoiconic/,
   the syntax of the language is itself a primitive data type in the language!
   "LISP" comes from "LISt Processing". The language is entirely based on the
   concept of manipulating lists and by extension manipulating itself.

   The . then in sexprs is really just (::) in OCaml but it does not enforce
   anything about the types it works with. So you may say (+ . (- . 3 . 2) . 4) in
   LISP but "+"::("-"::3::2::[])::4::[] does not work in OCaml. To solve this, we
   have to explicitly represent sexprs as /trees/ over /atoms/ so we may nest
   sexprs while being able to store both symbols and numbers.

   Just like OCaml's [a; b; c] list syntax is shorthand for a::b::c::[]. The sexpr
   (+ 3 4) is shorthand for (+ . (3 . (4 . []))). And we get the tree
   representation:

      .
    /  \
   +    .
       / \
      3   .
         / \
        4  []

   Notice that all right-leaning trees of this form are equivalent to lists. But
   what is this [] value here if we are making a binary tree over atoms? Is it an
   atom? Maybe. You could certainly make it an atom. However, for this assignment,
   we want to take note of the fact that the following type is logically
   equivalent to a list:

   type 'a list0 = | Cons of ('a * 'a list0) option

   let _ = Cons(Some(3, Cons(Some(2, Cons(Some(1, Cons(None)))))))
   let _ = 3::2::1::[]

   So, rather than extending atom with a '[]' value. We may just wrap it in an
   option for the same effect.

   Your task will be to go from string to sexprs to 'flat' sexprs to numbers. To have
   a full polish-notation calculator. Specifically:
   interp "(+ 2 ( * 2 199)) (/ 8 2 (- 6 3 1))"
   should print out:
    400
    2

   Reporting back the results of "(+ 2 ( * 2 199))" and "(/ 8 2 (- 6 3 1))"
   respectively.

   ---- Footnotes
   [1] https://en.wikipedia.org/wiki/S-expression
   [2] https://en.wikipedia.org/wiki/Lisp_(programming_language)
     The most common LISP languages are:
   - Common Lisp: https://common-lisp.net/
   - Clojure: https://clojure.org/
     And some from the Scheme language family/standard, originally designed by
     Steele and Sussman in the 70s:
   - Racket: https://racket-lang.org/
   - Guile: https://www.gnu.org/software/guile/
   - Chicken: https://www.call-cc.org/

 ********************************************)

type atom =
  | Symbol of string
  | Number of int

(* Notice the option type here *)
type sexpr = atom option tree

(*******************************************)

(*******************************************************************************
   DONE - A Tokenizer

   First, we must 'tokenize' the string: convert it into a sequence of 'token's
   which are easier to manipulate than strings.

   It is much easier to work with:
   [LPAREN; SYMBOL("+"); LPAREN; NUMBER("23"); RPAREN; RPAREN;]
   Then
   "(+( 23) )"

   In practice, a tokenizer (or 'lexer') should store the locations of characters
   for error reporting. For simplicity, we do not do so here.

   The final function 'tokenize' brings everything in this section together.

   This code is provided.
 ********************************************)

type token =
  | SYMBOL of string
  | NUMBER of int
  | LPAREN
  | RPAREN

type token_err =
  | UnknownChar of char
  | InvalidNum of char
  | InvalidSym of char

(*******************************************)

(* DONE Is the given character a digit? *)
let is_digit (c : char): bool =
  match c with | '0' .. '9' -> true | _ -> false

(* DONE Is the given character an alphabet character or special? *)
let is_alpha (c : char): bool =
  match c with | 'a' .. 'z' | 'A' .. 'Z' | '*' .. '/' -> true | _ -> false

(* DONE Is the given character a whitespace? *)
let is_whitespace (c : char): bool =
  c = ' ' || c = '\n' || c = '\t'

(* DONE Is the given character a parenthesis? *)
let is_paren (c : char): bool =
  c = '(' || c = ')'

(* DONE Convert a string into a list of characters *)
let char_list_of_string (s : string): char list =
  List.init (String.length s) (String.get s)

(* DONE Convert a single digit character into an integer *)
let digit_to_int (c : char): int =
  int_of_string @@ Char.escaped c

(* DONE Attempt to get the first symbol from the char list.
   Return the remaining list. *)
let get_symbol (cs : char list): (string, token_err) result * char list =
  let rec aux cs acc =
    match cs with
    | [] -> (Ok(acc), cs)
    | h::t ->
      if is_alpha h then
        aux t @@ acc ^ Char.escaped h
      else if is_whitespace h || is_paren h then
        (Ok(acc), cs)
      else (Error(InvalidSym(h)), cs)
  in aux cs ""

(* DONE Attempt to get the first number from the char list.
   Return the remaining list. *)
let get_num (cs : char list): (int, token_err) result * char list =
  let rec aux (cs : char list) acc =
    match cs with
    | [] -> (Ok(acc), cs)
    | h::t ->
      if is_digit h then
        aux t ((acc * 10) + digit_to_int h)
      else if is_whitespace h || is_paren h then
        (Ok(acc), cs)
      else (Error(InvalidNum(h)), cs)
  in aux cs 0

(* DONE *)
let into_tokens (cs : char list): (token list, token_err) result =
  let rec aux cs acc =
    match cs with
    | [] -> Ok(reverse acc)
    | c::rest ->
      match c with
      | '(' -> aux rest (LPAREN :: acc)
      | ')' -> aux rest (RPAREN :: acc)
      | x -> if is_whitespace x then
          aux rest acc
        else if is_digit x then
          match get_num cs with
          | (Ok(i), rest) -> aux rest (NUMBER(i) :: acc)
          | (Error(e), _) -> Error(e)
        else if is_alpha x then
          match get_symbol cs with
          | (Ok(s), rest) -> aux rest (SYMBOL(s) :: acc)
          | (Error(e), _) -> Error(e)
        else Error(UnknownChar(x))
  in aux cs []

(* DONE *)
let tokenize (s : string): (token list, token_err) result =
  into_tokens (char_list_of_string s)

(*******************************************************************************
   Parsing

   Next, we must 'parse' the tokens into a tree. To do this we need mutually
   recursive functions. This means we have two functions which may call each
   other recursively. In OCaml, this is accomplished with the 'and' keyword as
   seen below.

   The provided function 'parse' brings everything together. Notice, it returns a
   'sexpr list' in the Ok case. If we call our interp function with more than one
   sexpr: interp "(+ 2 1) (- 4 3)", we expect more than one outputs: 3 and 1 in
   this case. This is just like OCaml when it takes in multiple definitions. So
   our parser needs to return a /list/ of sexpr. Then we will just need to
   implement a single sexpr to number function and we can compute the whole
   result with something like map!

   Be sure to read the code for 'parse' to understand how 'parse_sexpr' will be
   called.

 ********************************************)

type parse_err =
  | UnexpectedEOS
  | UnmatchedParen
  | TokanizeErr of token_err

(*******************************************)

(* TODO #2.1 Implement the following two functions.
   See below in 'parse' for examples.
*)
let rec parse_sexpr (ts : token list): (sexpr * token list, parse_err) result =
  match ts with
    NUMBER (n)::t-> Ok(Leaf (Some (Number n)),t)
  |
    SYMBOL (s)::t-> Ok(Leaf (Some (Symbol s)),t)
  |
    LPAREN::t-> parse_list t
  | 
    RPAREN::t->Error(UnmatchedParen)
  |
    []->Error(UnexpectedEOS)


(* TODO (match parse_list t with ) *)
and parse_list (ts : token list): (sexpr * token list, parse_err) result =
  match ts with 
    RPAREN::t->Ok(Leaf (None),t)
  |
    ts->
    match parse_sexpr ts with
    |Error(e)->Error(e)
    |Ok(n,rs)-> (
        match parse_list rs with
          Ok(n1,rs)->Ok(Node (n,n1),rs)
        |
          e->e
      )


(* DONE (NUMBER n)::t-> Ok(Node ((Leaf (Some (Number n))),Leaf None),t)
   Examples:
   parse ""  = Ok []
   parse "1" = Ok [Leaf (Some (Number 1))]
   parse "(+ (3 4) (- 2 1))"
     = Ok [Node (Leaf (Some (Symbol "+")),
            Node
             (Node (Leaf (Some (Number 3)),
              Node (Leaf (Some (Number 4)),
              Leaf None)),
             Node
              (Node (Leaf (Some (Symbol "-")),
                 Node (Leaf (Some (Number 2)),
                 Node (Leaf (Some (Number 1)),
                 Leaf None))),
            Leaf None)))]
   parse "(+ 1 1) (- 1 1)"
    = Ok  [Node (Leaf (Some (Symbol "+")),
                 Node (Leaf (Some (Number 1)),
                 Node (Leaf (Some (Number 1)),
                 Leaf None)));
           Node (Leaf (Some (Symbol "-")),
                 Node (Leaf (Some (Number 1)),
                 Node (Leaf (Some (Number 1)), Leaf None)))]

   parse "(+ (3 4) 2" = Error UnexpectedEOS
   parse "+ (3 4) 2)" = Error UnmatchedParen
*)
let parse (s : string): (sexpr list, parse_err) result =
  let rec parse_all ts acc =
    match ts with
    | [] -> Ok(reverse acc)
    | ts -> match parse_sexpr ts with
      | Ok(s, ts) -> parse_all ts (cons s acc)
      | Error(e) -> Error(e)
  in
  match tokenize s with
  | Ok(ts) -> parse_all ts []
  | Error(e) -> Error(TokanizeErr(e))


(*******************************************************************************
   Generalizing

   Next, we transform this binary tree representation into a gtree.

   This is the 'flattening' process mentioned previously. Although there is
   nothing that requires this step, it will make interpreting our sexpr a bit
   easier in some ways. Think now to yourself about how you would implement the
   interpreter for binary trees (and feel free to try it out!). If our goal is to
   have a simple recursive function, then the fact that (+ 3 4 5) has the subtree
   '4 . (5 . Nil)' is actually a bit of a bother. By turning it into a flattened
   tree, we can just remove the head of the list as each node (here, "+") and
   apply the operator to the tail ([3; 4; 5]).

 ********************************************)

type sexpr_gtree = atom gtree

(* TODO #2.2 Implement the following function.
   Example:

   tree_to_gtree (Leaf None) = GNode []
   tree_to_gtree (Leaf (Some (Number 3))) = GNode [GLeaf (Number 3)]
   tree_to_gtree (Node((Leaf (Some (Number 3))), (Leaf None)))
     = GNode [GLeaf (Number 3)]

   (* This is the tree of "(- 2 (+ 3 2) ( * 4 5))" *)
   tree_to_gtree
     (Node (Leaf (Some (Symbol "-")),
      Node (Leaf (Some (Number 2)),
      Node
       (Node (Leaf (Some (Symbol "+")),
        Node (Leaf (Some (Number 3)),
        Node (Leaf (Some (Number 2)),
        Leaf None))),
      Node
       (Node (Leaf (Some (Symbol "*")),
        Node (Leaf (Some (Number 4)),
        Node (Leaf (Some (Number 5)),
        Leaf None))),
      Leaf None)))))
     = GNode
         [GLeaf (Symbol "-");
          GLeaf (Number 2);
          GNode [GLeaf (Symbol "+"); GLeaf (Number 3); GLeaf (Number 2)];
          GNode [GLeaf (Symbol "*"); GLeaf (Number 4); GLeaf (Number 5)]]
*)


(*if not gnode (append r t)*)
let help l=
  match l with
    []->0
  |
    h::t-> if t=[] then 1 else 0
;;

let helper x z=
  match (x,z) with
    (GNode [GLeaf r] , GNode t)->gnode ((GLeaf r) :: t)
  |
    (_,GNode y)->gnode (x::y)
  |
    (_, GLeaf e)-> gnode (x::z::[])


let helper1 y=
  match y with
    Some s->gnode [gleaf s]
  |
    None-> gnode []


let tree_to_gtree (s : sexpr): sexpr_gtree =
  fold_tree (fun x z->helper x z) (fun y-> helper1 y) s


(*******************************************************************************
 * Part 3 - Evaluation

   Finally, we can evaluate our (flat) s-expressions!

   To do this, we inspect the first element of the list at a gnode. If it is a
   symbol that we know, we evaluate appropriately.

   The 'eval' function is the function we mention in passing in the section
   header for parsing which goes from sexpr to number. Inside 'interp' below, we
   use 'List.iter'. 'List.iter' works like map, but instead of /mapping/ values
   to a new list, it has type signature:

    iter : ('a -> unit) -> 'a list -> unit

   Meaning it calls the first argument on every element of the list, but since
   the function returns nothing ('unit'), so does iter. And remember that '|>' is
   a binary operator which passes the left hand side to a function on the right
   hand side. E.g. 2 |> (+) 2 = 4

   Implement the following operations, n-wise of each:
   - (+ ...)
   - (- ...)
   - ( * ...)
   - (/ ...)

   On zero arguments, fail with 'NotEnoughArguments'.
   On one argument, return the one argument.

   Otherwise, (+ a b c...)  = ((a + b) + c)...
             ( * a b c...) = ((a * b) * c)...
             (- a b c...)  = ((a - b) - c)...
             (/ a b c...)  = ((a / b) / c)...
 ********************************************)

type eval_err =
  | EmptyInput
  | NotEnoughArguments
  | NotAFunction
  | NotANumber of string

(*******************************************)

(* TODO #3.1 Implement the following function. *)
(* Examples
   eval (GNode [
          GLeaf (Symbol "-");
          GLeaf (Number 2);
          GNode [
            GLeaf (Symbol "+");
            GLeaf (Number 3);
            GLeaf (Number 4)
          ];
          GLeaf (Number 3)
       ])
     = Ok (-8)

   eval (GNode [])                                   = Error EmptyInput
   eval (GNode [GLeaf (Symbol "+")])                 = Error NotEnoughArguments
   eval (GNode [GLeaf (Number 1); GLeaf (Number 2)]) = Error NotAFunction

   eval (GNode [GLeaf (Symbol "+"); GLeaf (Symbol "x")])
     = Error (NotANumber "x")*)

let helperh ls=
  match ls with
    []->gnode []
  |
    h::t->h
;;

let helper5 rs1 rs2 op=
  match (rs1,rs2) with
    (Error e,Error e1)-> Error(e)
  |
    (Ok o1, Ok o2)->Ok (op o1 o2)
  |
    (_,_)-> Error(NotAFunction)
;;

let helpert ls=
  match ls with
    []->[]
  |
    h::t-> t
;;

let multip b i= b * i

let helper2 acc r op=
  match acc with
    Error e->Error e
  |
    Ok(o)-> Ok(op o r)
;;


let rec eval (s : sexpr_gtree): (int, eval_err) result =
  match s with
    GLeaf (Number num1)-> Ok(num1) (*THİS PLACE CAN BE BASE CASE FOR eval h, it was Error(NotEnoughArguments)*)
  |
    GLeaf (Symbol s1)->Error(NotANumber s1)
  |
    GNode n->(match n with
        []-> Error(EmptyInput)
      |
        h::t-> (match h with
            GLeaf l1->(match l1 with    
                Symbol s-> if t=[] then Error (NotEnoughArguments) else (if s="+" then fold_left (fun x y->helper3 y x (+)) (eval (helperh t)) (helpert t)
                                                                         else if s="-" then fold_left (fun x y->helper3 y x (-)) (eval (helperh t)) (helpert t)
                                                                         else if s="*" then fold_left (fun x y->helper3 y x (multip)) (eval (helperh t)) (helpert t)
                                                                         else if s="/" then fold_left (fun x y->helper3 y x (/)) (eval (helperh t)) (helpert t)
                                                                         else Error(NotAFunction))
              |
                Number num->Error(NotAFunction)) 
          |
            GNode n1->Error(NotAFunction)))

and helper3 acc r op=
  match r with
    GLeaf l->(match l with
        Number num->helper2 acc num op
      |
        Symbol s->Error(NotANumber s)) 
  |
    GNode n->helper5 acc (eval (GNode n)) op

;;



(*******************************************************************************
   We can bring it all together.

   Example:
   interp "(+ 2 ( * 2 199)) (/ 8 2 (- 6 3 1))"
   Prints out:
    400
    2

 ********************************************)

(* DONE *)
let interp (s : string): unit =
  let parse_err s = print_endline @@ "Parsing error: " ^ s in
  let eval_err s = print_endline @@ "Eval error: " ^ s in
  match parse s with
  | Error(UnexpectedEOS)
    -> parse_err "Unexpected EOS"
  | Error(UnmatchedParen)
    -> parse_err "Unmatched parenthesis"
  | Error(TokanizeErr(UnknownChar(c)))
    -> parse_err @@ "Unknown character (" ^ Char.escaped c ^ ")"
  | Error(TokanizeErr(InvalidNum(c)))
    -> parse_err @@ "Invalid number (" ^ Char.escaped c ^ ")"
  | Error(TokanizeErr(InvalidSym(c)))
    -> parse_err @@ "Invalid symbol (" ^ Char.escaped c ^ ")"
  | Ok(ss) ->
    ss
    |> List.iter @@
    fun x ->
    match eval (tree_to_gtree x) with
    | Error(EmptyInput) ->  eval_err "Empty list"
    | Error(NotEnoughArguments) -> eval_err "Too few arguments"
    | Error(NotAFunction) -> eval_err "Not a function"
    | Error(NotANumber(s)) -> eval_err @@ "Not a number (" ^ s ^ ")"
    | Ok(i) -> Printf.printf "%d\n" i
