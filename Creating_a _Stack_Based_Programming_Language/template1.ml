(* parsing util functions *)

let is_lower_case c = 'a' <= c && c <= 'z'

let is_upper_case c = 'A' <= c && c <= 'Z'

let is_alpha c = is_lower_case c || is_upper_case c

let is_digit c = '0' <= c && c <= '9'

let is_alphanum c = is_lower_case c || is_upper_case c || is_digit c

let is_blank c = String.contains " \012\n\r\t" c

let explode s = List.of_seq (String.to_seq s)

let implode ls = String.of_seq (List.to_seq ls)

let readlines (file : string) : string =
  let fp = open_in file in
  let rec loop () =
    match input_line fp with
    | s -> s ^ "\n" ^ loop ()
    | exception End_of_file -> ""
  in
  let res = loop () in
  let () = close_in fp in
  res

(* end of util functions *)

(* parser combinators *)

type 'a parser = char list -> ('a * char list) option

let parse (p : 'a parser) (s : string) : ('a * char list) option = p (explode s)

let pure (x : 'a) : 'a parser = fun ls -> Some (x, ls)

let return=pure

let fail : 'a parser = fun ls -> None

let bind (p : 'a parser) (q : 'a -> 'b parser) : 'b parser =
  fun ls ->
  match p ls with
  | Some (a, ls) -> q a ls
  | None -> None

let ( >>= ) = bind

let ( let* ) = bind

let read : char parser =
  fun ls ->
  match ls with
  | x :: ls -> Some (x, ls)
  | _ -> None

let satisfy (f : char -> bool) : char parser =
  fun ls ->
  match ls with  
  | x :: ls ->
    if f x then
      Some (x, ls)
    else
      None
  | _ -> None

let char (c : char) : char parser = satisfy (fun x -> x = c)

let seq (p1 : 'a parser) (p2 : 'b parser) : 'b parser =
  fun ls ->
  match p1 ls with
  | Some (_, ls) -> p2 ls
  | None -> None

let ( >> ) = seq

let seq' (p1 : 'a parser) (p2 : 'b parser) : 'a parser =
  fun ls ->
  match p1 ls with
  | Some (x, ls) -> (
      match p2 ls with
      | Some (_, ls) -> Some (x, ls)
      | None -> None)
  | None -> None

let ( << ) = seq'

let alt (p1 : 'a parser) (p2 : 'a parser) : 'a parser =
  fun ls ->
  match p1 ls with
  | Some (x, ls) -> Some (x, ls)
  | None -> p2 ls

let ( <|> ) = alt

let map (p : 'a parser) (f : 'a -> 'b) : 'b parser =
  fun ls ->
  match p ls with
  | Some (a, ls) -> Some (f a, ls)
  | None -> None

let ( >|= ) = map

let ( >| ) p c = map p (fun _ -> c)

let rec many (p : 'a parser) : 'a list parser =
  fun ls ->
  match p ls with
  | Some (x, ls) -> (
      match many p ls with
      | Some (xs, ls) -> Some (x :: xs, ls)
      | None -> Some ([ x ], ls))
  | None -> Some ([], ls)

let rec many1 (p : 'a parser) : 'a list parser =
  fun ls ->
  match p ls with
  | Some (x, ls) -> (
      match many p ls with
      | Some (xs, ls) -> Some (x :: xs, ls)
      | None -> Some ([ x ], ls))
  | None -> None

let rec many' (p : unit -> 'a parser) : 'a list parser =
  fun ls ->
  match p () ls with
  | Some (x, ls) -> (
      match many' p ls with
      | Some (xs, ls) -> Some (x :: xs, ls)
      | None -> Some ([ x ], ls))
  | None -> Some ([], ls)

let rec many1' (p : unit -> 'a parser) : 'a list parser =
  fun ls ->
  match p () ls with
  | Some (x, ls) -> (
      match many' p ls with
      | Some (xs, ls) -> Some (x :: xs, ls)
      | None -> Some ([ x ], ls))
  | None -> None

let whitespace : unit parser =
  fun ls ->
  match ls with
  | c :: ls ->
    if String.contains " \012\n\r\t" c then
      Some ((), ls)
    else
      None
  | _ -> None

let ws : unit parser = many whitespace >| ()

let ws1 : unit parser = many1 whitespace >| ()

let digit : char parser = satisfy is_digit

let natural : int parser =
  fun ls ->
  match many1 digit ls with
  | Some (xs, ls) -> Some (int_of_string (implode xs), ls)
  | _ -> None

let literal (s : string) : unit parser =
  fun ls ->
  let cs = explode s in
  let rec loop cs ls =
    match (cs, ls) with
    | [], _ -> Some ((), ls)
    | c :: cs, x :: xs ->
      if x = c then
        loop cs xs
      else
        None
    | _ -> None
  in
  loop cs ls

let keyword (s : string) : unit parser = literal s >> ws >| ()

let reserved =
  [ "Push"
  ; "True"
  ; "False"
  ; "Pop"
  ; "Add"
  ; "Sub"
  ; "Mul"
  ; "Div"
  ; "Equal"
  ; "Lte"
  ; "And"
  ; "Or"
  ; "Not"
  ; "Trace"
  ; "Local"
  ; "Global"
  ; "Lookup"
  ; "Begin"
  ; "If"
  ; "Else"
  ; "Fun"
  ; "End"
  ; "Call"
  ; "Try"
  ; "Switch"
  ; "Case"
  ]

let name : string parser =
  let* c = satisfy is_alpha in
  let* cs = many (satisfy (fun c -> is_alphanum c || c = '_' || c = '\'')) in
  let s = implode (c :: cs) in
  if List.exists (fun x -> x = s) reserved then
    fail
  else
    pure s << ws

(* end of parser combinators *)

(* TODO *)

(*
type digit = 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9;;
type int= [-] digit {digit}

type bool= True | False
type const= int | bool | ()

type com= Push const | Pop int | Trace int
        | Add int | Sub int | Mul int | Div int;;
type coms=com {com}

type prog= coms

type val =int | bool | ()
*)



type const=   
    I of int
  |
    B of bool
  |
    U of unit
  |
    N of string
  |
    Clo of (env*env*string*const*coms)  (*first env is for local second one is for global*)

and env = (string * const) list

and com= Push of const| Pop of int | Trace of int| Add of int  
       | Sub of int | Mul of int | Div of int | And | Or | Not | Equal | Lte |Local
       | Global | Lookup | Begin of coms | End | IfElse of (coms*coms) | Call | Fun of (string*string*coms)
       | Try of coms | Switch of coms | Case of (int*coms)


and coms = com list ;;



let integerParser() =
  natural <|> 
  (satisfy (fun n->n='-') >>= fun c1->
   natural >>= fun n->
   return (-1*n))

;;

let boolParsert() = 
  satisfy (fun x ->x='T') >>= fun c1->
  satisfy (fun x ->x='r') >>= fun c2->
  satisfy (fun x ->x='u') >>= fun c3->
  satisfy (fun x ->x='e') >>= fun c4->
  return (true)

;;

let boolParserf() =
  satisfy (fun x ->x='F') >>= fun c1->
  satisfy (fun x ->x='a') >>= fun c2->
  satisfy (fun x ->x='l') >>= fun c3->
  satisfy (fun x ->x='s') >>= fun c4->
  satisfy (fun x ->x='e') >>= fun c5->
  return (false)

;;

let unitParser() = 
  satisfy (fun x ->x='(') >>= fun c1->
  satisfy (fun x ->x=')') >>= fun c2->
  return (())

;;

let nameParser()=
  name >>= fun c->
  return c


let rec pars()=
  pushi() <|> pushb1() <|> pushb2() <|> pushu() <|> pop() <|> trace() <|> add() <|> sub() <|> mul() <|> div()
  <|> andParser() <|> orParser() <|> notParser() <|> equalParser() <|> lteParser() <|> localParser() <|> globalParser()
  <|> lookupParser() <|> endParser() <|> beginParser()  <|> ifelseParser()  <|> pushs () <|> endParser () <|> funParser () <|> callParser ()
  <|> tryParser () <|> caseParser() <|> switchParser()

and pars1()=
  pushi() <|> pushb1() <|> pushb2() <|> pushu() <|> pop() <|> trace() <|> add() <|> sub() <|> mul() <|> div()
  <|> andParser() <|> orParser() <|> notParser() <|> equalParser() <|> lteParser() <|> localParser() <|> globalParser()
  <|> lookupParser() <|> beginParser()  <|> ifelseParser() <|> pushs () <|> funParser () <|> callParser ()
  <|> tryParser () <|> switchParser()


and pushi () =                    (*three types of push ex: pushi, pushb, pushu*)
  many whitespace >>= fun c0->
  satisfy (fun x ->x='P') >>= fun c1->
  satisfy (fun x ->x='u') >>= fun c2->
  satisfy (fun x ->x='s') >>= fun c3->
  satisfy (fun x ->x='h') >>= fun c4->
  whitespace >>= fun c5->
  integerParser() >>= fun n->     
  return (Push (I n))


and pushb1 () =    
  many whitespace >>= fun c0->
  satisfy (fun x ->x='P') >>= fun c1->
  satisfy (fun x ->x='u') >>= fun c2->
  satisfy (fun x ->x='s') >>= fun c3->
  satisfy (fun x ->x='h') >>= fun c4->
  whitespace >>= fun c5->
  boolParsert() >>= fun n->     
  return (Push (B n))


and pushb2 () =    
  many whitespace >>= fun c0->
  satisfy (fun x ->x='P') >>= fun c1->
  satisfy (fun x ->x='u') >>= fun c2->
  satisfy (fun x ->x='s') >>= fun c3->
  satisfy (fun x ->x='h') >>= fun c4->
  whitespace >>= fun c5->
  boolParserf() >>= fun n->     
  return (Push (B n))


and pushu () =
  many whitespace >>= fun c0->
  satisfy (fun x ->x='P') >>= fun c1->
  satisfy (fun x ->x='u') >>= fun c2->
  satisfy (fun x ->x='s') >>= fun c3->
  satisfy (fun x ->x='h') >>= fun c4->
  whitespace >>= fun c5->
  unitParser() >>= fun n->     
  return (Push (U n))

and pushs () =
  many whitespace >>= fun c0->  
  satisfy (fun x ->x='P') >>= fun c1->
  satisfy (fun x ->x='u') >>= fun c2->
  satisfy (fun x ->x='s') >>= fun c3->
  satisfy (fun x ->x='h') >>= fun c4->
  whitespace >>= fun c5->
  nameParser()>>= fun n->     
  return (Push (N n))


and pop () =
  many whitespace >>= fun c0->
  satisfy (fun x ->x='P') >>= fun c1->
  satisfy (fun x ->x='o') >>= fun c2->
  satisfy (fun x ->x='p') >>= fun c3->
  whitespace >>= fun c4->
  integerParser() >>= fun n->
  return (Pop n)


and trace () =
  many whitespace >>= fun c0->
  satisfy (fun x ->x='T') >>= fun c1->
  satisfy (fun x ->x='r') >>= fun c2->
  satisfy (fun x ->x='a') >>= fun c3->
  satisfy (fun x ->x='c') >>= fun c4->
  satisfy (fun x ->x='e') >>= fun c5->
  whitespace >>= fun c6->
  integerParser() >>= fun n->
  return (Trace n)


and add () =
  many whitespace >>= fun c0->
  satisfy (fun x ->x='A') >>= fun c1->
  satisfy (fun x ->x='d') >>= fun c2->
  satisfy (fun x ->x='d') >>= fun c3->
  whitespace >>= fun c4->
  integerParser() >>= fun n->
  return (Add n)


and sub () =
  many whitespace >>= fun c0->
  satisfy (fun x ->x='S') >>= fun c1->
  satisfy (fun x ->x='u') >>= fun c2->
  satisfy (fun x ->x='b') >>= fun c3->
  whitespace >>= fun c4->
  integerParser() >>= fun n->
  return (Sub n)


and mul () =
  many whitespace >>= fun c0->
  satisfy (fun x ->x='M') >>= fun c1->
  satisfy (fun x ->x='u') >>= fun c2->
  satisfy (fun x ->x='l') >>= fun c3->
  whitespace >>= fun c4->
  integerParser() >>= fun n->
  return (Mul n)


and div () =
  many whitespace >>= fun c0->
  satisfy (fun x ->x='D') >>= fun c1->
  satisfy (fun x ->x='i') >>= fun c2->
  satisfy (fun x ->x='v') >>= fun c3->
  whitespace >>= fun c4->
  integerParser() >>= fun n->
  return (Div n)

and andParser () =         (*YENİLER BUNLARI DE ANDLE*)
  many whitespace >>= fun c0->
  satisfy (fun x ->x='A') >>= fun c1->
  satisfy (fun x ->x='n') >>= fun c2->
  satisfy (fun x ->x='d') >>= fun c3->    
  return (And)

and orParser () =
  many whitespace >>= fun c0->
  satisfy (fun x ->x='O') >>= fun c1->
  satisfy (fun x ->x='r') >>= fun c2->    
  return (Or)


and notParser () =
  many whitespace >>= fun c0->
  satisfy (fun x ->x='N') >>= fun c1->
  satisfy (fun x ->x='o') >>= fun c2->
  satisfy (fun x ->x='t') >>= fun c3->    
  return (Not)


and equalParser () =
  many whitespace >>= fun c0->
  satisfy (fun x ->x='E') >>= fun c1->
  satisfy (fun x ->x='q') >>= fun c2->
  satisfy (fun x ->x='u') >>= fun c3->
  satisfy (fun x ->x='a') >>= fun c4-> 
  satisfy (fun x ->x='l') >>= fun c5->     
  return (Equal)

and lteParser () =
  many whitespace >>= fun c0->
  satisfy (fun x ->x='L') >>= fun c1->
  satisfy (fun x ->x='t') >>= fun c2->
  satisfy (fun x ->x='e') >>= fun c3->    
  return (Lte)

and localParser () =
  many whitespace >>= fun c0->
  satisfy (fun x ->x='L') >>= fun c1->
  satisfy (fun x ->x='o') >>= fun c2->
  satisfy (fun x ->x='c') >>= fun c3->
  satisfy (fun x ->x='a') >>= fun c4-> 
  satisfy (fun x ->x='l') >>= fun c5->     
  return (Local)


and globalParser () =
  many whitespace >>= fun c0->
  satisfy (fun x ->x='G') >>= fun c1->
  satisfy (fun x ->x='l') >>= fun c2->
  satisfy (fun x ->x='o') >>= fun c3->
  satisfy (fun x ->x='b') >>= fun c4-> 
  satisfy (fun x ->x='a') >>= fun c5-> 
  satisfy (fun x ->x='l') >>= fun c6->    
  return (Global)


and lookupParser () =
  many whitespace >>= fun c0->
  satisfy (fun x ->x='L') >>= fun c1->
  satisfy (fun x ->x='o') >>= fun c2->
  satisfy (fun x ->x='o') >>= fun c3->
  satisfy (fun x ->x='k') >>= fun c4-> 
  satisfy (fun x ->x='u') >>= fun c5-> 
  satisfy (fun x ->x='p') >>= fun c6->    
  return (Lookup)

and endParser () =
  many whitespace >>= fun c0->
  satisfy (fun x ->x='E') >>= fun c1->
  satisfy (fun x ->x='n') >>= fun c2->
  satisfy (fun x ->x='d') >>= fun c3->    
  return (End)


and beginParser () =
  many whitespace >>= fun c0->
  satisfy (fun x ->x='B') >>= fun c1->
  satisfy (fun x ->x='e') >>= fun c2->
  satisfy (fun x ->x='g') >>= fun c3->
  satisfy (fun x ->x='i') >>= fun c4->
  satisfy (fun x ->x='n') >>= fun c5->
  whitespace >>= fun c5->
  parser1() >>= fun n ->
  endParser() >>= fun c6->
  return (Begin n)

and ifelseParser () =
  many whitespace >>= fun c0->
  satisfy (fun x ->x='I') >>= fun c1->
  satisfy (fun x ->x='f') >>= fun c2->
  whitespace >>= fun c3->
  parser() >>= fun n ->
  many whitespace >>= fun c0->
  satisfy (fun x ->x='E') >>= fun c1->
  satisfy (fun x ->x='l') >>= fun c2->
  satisfy (fun x ->x='s') >>= fun c3->
  satisfy (fun x ->x='e') >>= fun c4->
  whitespace >>= fun c5->
  parser1() >>= fun n1 ->
  endParser() >>= fun c6->
  return (IfElse (n,n1))

and callParser ()=
  many whitespace >>= fun c0->
  satisfy (fun x ->x='C') >>= fun c1->
  satisfy (fun x ->x='a') >>= fun c2->
  satisfy (fun x ->x='l') >>= fun c3->
  satisfy (fun x ->x='l') >>= fun c3->
  return (Call)
  ;

and funParser ()=
  many whitespace >>= fun c0->
  satisfy (fun x ->x='F') >>= fun c1->
  satisfy (fun x ->x='u') >>= fun c2->
  satisfy (fun x ->x='n') >>= fun c3->
  whitespace >>= fun c5->
  nameParser () >>= fun n->
  many whitespace >>= fun c5->
  nameParser () >>= fun n1->
  many whitespace >>= fun c0->
  parser1() >>= fun n2 ->
  endParser() >>= fun c6->
  return (Fun (n,n1,n2))

and tryParser ()=
  many whitespace >>= fun c0->
  satisfy (fun x ->x='T') >>= fun c1->
  satisfy (fun x ->x='r') >>= fun c2->
  satisfy (fun x ->x='y') >>= fun c3->
  whitespace >>= fun c4->
  parser1() >>= fun n ->
  endParser() >>= fun c6->
  return (Try n)

and caseParser ()=
  many whitespace >>= fun c0->
  satisfy (fun x ->x='C') >>= fun c1->
  satisfy (fun x ->x='a') >>= fun c2->
  satisfy (fun x ->x='s') >>= fun c3->
  satisfy (fun x ->x='e') >>= fun c3->
  whitespace >>= fun c4->
  integerParser() >>= fun n->
  many whitespace >>= fun c0->
  parser1() >>= fun cm->
  return (Case (n,cm))

and switchParser ()=
  many whitespace >>= fun c0->
  satisfy (fun x ->x='S') >>= fun c1->
  satisfy (fun x ->x='w') >>= fun c2->
  satisfy (fun x ->x='i') >>= fun c3->
  satisfy (fun x ->x='t') >>= fun c3->
  satisfy (fun x ->x='c') >>= fun c3->
  satisfy (fun x ->x='h') >>= fun c3->
  many whitespace >>= fun c0->
  many (caseParser()) >>= fun n->
  many whitespace >>= fun c0->
  endParser() >>= fun c4->
  return (Switch n)




and parser ()=      
  many (pars()) >>= fun c0->
  many whitespace >>= fun c->
  return c0

and parser1 ()=       
  many (pars1()) >>= fun c0->
  many whitespace >>= fun c->
  return c0


(* *)


let helperpush1 n ls=  
  match n with   
    I i-> (I i)::ls
  |
    B b-> (B b)::ls
  |
    U u-> (U u)::ls
  |
    N n-> (N n)::ls
  |
    Clo c-> (Clo c)::ls   (*never be executed*)
;;

let helperpop n ls= 
  let rec aux acc n ls=    
    if n=0 then acc
    else (match ls with
          []->ls
        |
          h::t-> aux t (n-1) t )
  in aux ls n ls
;;


let helpertrace1 n ls log= 
  let rec aux acc n ls log=  
    if n=0 then acc
    else (match ls with
          []->log
        |
          h::t-> (match h with
              I i->aux (string_of_int i::acc) (n-1) t (string_of_int i::log)
            |
              B b->if b=true then aux ("True"::acc) (n-1) t ("True"::log) else aux ("False"::acc) (n-1) t ("False"::log)
            |
              U u->aux ("()"::acc) (n-1) t ("()"::log)
            |
              N n1-> aux (n1::acc) (n-1) t (n1::log)
            |
              Clo c-> aux acc n t log ))
  in aux log n ls log
;;


let helperaddlo n ls log =     (* ERROR CASESci FOR LOG*) 
  let rec aux acc n ls log=   
    if log=["Error"] then ["Error"]
    else if n=0 then log
    else (match ls with
          []->log
        |
          h::t-> (match h with
              I i->aux (0) (n-1) t log
            |
              _-> aux (0) (n-1) t ["Error"] 
          ))
  in aux 0 n ls log
;;

let helperaddst n ls log =   (*BU STACK. FOR STACK*)
  let rec aux acc n ls log=    
    if log=["Error"] then []
    else if n=0 then I acc::ls
    else (match ls with
          []->ls
        |
          h::t-> (match h with
              I i->aux (acc+i) (n-1) (t) log
            |
              _-> aux (acc+0) (n-1) (t) ["Error"] 
          ))
  in aux 0 n ls log
;;


let helpersublo n ls log=   (* ERROR CASESci LOG *)
  if n=0 then log      
  else (match ls with
        []->log
      |
        h::t->(match h with
            I i->(match helperaddlo (n-1) t log, helperaddst (n-1) t log with
                _,(I i1)::t1-> log  
              |
                h::t,[]-> if h="Error" then ["Error"] else log (*sıkıntı var*)
              |
                _,_->["Error"])  
          |
            _->["Error"] ))
;;

let helpersubst n ls log=  (*BU STACK*)  
  if n=0 then I 0::ls      
  else (match ls with
        []->ls
      |
        h::t->(match h with
            I i->(match helperaddlo (n-1) t log, helperaddst (n-1) t log with
                _,(I i1)::t1-> I (i-i1)::t1
              |
                h3::t,[]->ls   (*sıkıntı var*)
              |
                _,_->ls)  
          |
            _->ls ))
;;


let helpermullo n ls log =   (* ERROR CASESci. FOR LOG *) 
  let rec aux acc n ls log=   
    if log=["Error"] then ["Error"]
    else if n=0 then log
    else (match ls with
          []->log
        |
          h::t-> (match h with
              I i->aux (0) (n-1) t log
            |
              _->aux (0) (n-1) t ["Error"] 
          ))
  in aux 1 n ls log
;;

let helpermulst n ls log =    (*BU STACK. FOR STACK*)
  let rec aux acc n ls log=    
    if log=["Error"] then []
    else if n=0 then I acc::ls
    else (match ls with
          []->ls
        |
          h::t-> (match h with
              I i->aux (acc*i) (n-1) (t) log
            |
              _-> aux (acc+0) (n-1) (t) ["Error"]
          ))
  in aux 1 n ls log
;;


let helperdivlo n ls log=   (* ERROR CASESci LOG *)
  if n=0 then log    
  else (match ls with
        []->log
      |
        h::t->(match h with
            I i->(match helpermullo (n-1) t log, helpermulst (n-1) t log with
                _,(I i1)::t1->if i1=0 then ["Error"] else log
              |
                h::t,[]->if h="Error" then ["Error"] else log    (*there is a problem*)
              |
                _,_->["Error"])  
          |
            _-> ["Error"]))
;;

let helperdivst n ls log=  (*BU STACK. FOR STACK*)
  if n=0 then I 1::ls    
  else (match ls with
        []->ls
      |
        h::t->(match h with
            I i->(match helpermullo (n-1) t log, helpermulst (n-1) t log with
                _,(I i1)::t1-> if i1=0 then ls else I (i/i1)::t1
              |
                h::t,[]->if h="Error" then ls else ls    (*there is a problem*)
              |
                _,_->ls)  
          |
            _->ls ))
;;

(*NEW FUNCTİONS:*)

let helperandst ls log=
  match ls with
    []->[] 
  |
    h::h1::t->(match h,h1 with
        B b,B b1->B (b && b1)::t
      |
        _,_->[]
    )
  |
    _->[]
;;


let helperandlo ls log=
  match ls with
    []->["Error"] 
  |
    h::h1::t->(match h,h1 with
        B b,B b1->log
      |
        _,_->["Error"]
    )
  |
    _->["Error"]
;;

let helperorst ls log=
  match ls with
    []->[] 
  |
    h::h1::t->(match h,h1 with
        B b,B b1->B (b || b1)::t
      |
        _,_->[]
    )
  |
    _->[]
;;

let helperorlo ls log= helperandlo ls log


let helpernotst ls log=
  match ls with
    []->[] 
  |
    h::t->(match h with
        B b ->B (not b)::t
      |
        _->[]
    )
;;

let helpernotlo ls log=
  match ls with
    []->["Error"] 
  |
    h::t->(match h with
        B b ->log
      |
        _->["Error"]
    )
;;

let helperequalst ls log=
  match ls with
    []->[] 
  |
    h::h1::t->(match h,h1 with
        I i,I i1->B (i = i1)::t
      |
        _,_->[]
    )
  |
    _->[]
;;

let helperequallo ls log=
  match ls with
    []->["Error"] 
  |
    h::h1::t->(match h,h1 with
        I i,I i1->log
      |
        _,_->["Error"]
    )
  |
    _->["Error"]
;;

let helperltest ls log=
  match ls with
    []->[] 
  |
    h::h1::t->(match h,h1 with
        I i,I i1->B (i <= i1)::t
      |
        _,_->[]
    )
  |
    _->[]
;;

let helperltelo ls log= helperequallo ls log


let helperlocalst ls log=
  match ls with
    []->[]
  |
    h::h1::t->(match h,h1 with
        N n,n1->(U ())::t
      |
        _,_->[])
  |
    _->[]
;;

let helperlocallo ls log=
  match ls with
    []->["Error"]
  |
    h::h1::t->(match h,h1 with
        N n,n1->log
      |
        _,_->["Error"])
  |
    _->["Error"]
;;

let helperlocalEl ls log envl=
  match ls with
    []->[]
  |
    h::h1::t->(match h,h1 with
        N n,n1->(n,n1)::envl
      |
        _,_->[])
  |
    _->[]
;;

let helperglobalst ls log= helperlocalst ls log

let helpergloballo ls log=helperlocallo ls log

let helperglobalEg ls log envg=helperlocalEl ls log envg



let helperlookupst ls log envl envg=
  match ls with
    []->[]
  |
    h::t->(match h with
        N n->if (List.exists (fun n1->match n1 with | (i,i1)-> i=n) envl) =true then 
          (match List.find (fun n1->match n1 with | (i,i1)-> i=n) envl with | (x,y)-> y::t) 
        else if (List.exists (fun n1->match n1 with | (i,i1)-> i=n) envg) =true then 
          (match List.find (fun n1->match n1 with | (i,i1)-> i=n) envg with | (x,y)-> y::t) 
        else []
      |
        _->[])
;;

let helperlookuplo ls log envl envg=
  match ls with
    []->["Error"]
  |
    h::t->(match h with
        N n->(if (List.exists (fun n1->match n1 with | (i,i1)-> i=n) envl) =true then 
           log 
         else if (List.exists (fun n1->match n1 with | (i,i1)-> i=n) envg) =true then 
           log 
         else ["Error"])
      |
        _->["Error"])
;;


let helperfunEl fname name envl cs =
  (fname,Clo (envl,[],fname,N name,cs))::envl

let helpercall ls= (*looks top two value of the stack true/false. the topmost must be closure and the other one should be const typed parameter*)
  match ls with
    []->false
  |
    Clo cl::h1::t->(match h1 with
        I i->true
      |
        B b->true
      |
        U u->true
      |
        _->false)
  |
    _->false
;;

let getcoms ls = (*looks at the topmost value which is a closure and takes out coms in it*)
  match ls with
    []->[]  (*never be executed*)
  |
    Clo (e1,e2,str,cnst,cs)::t->cs
  |
    _-> []
;;

let doublepop ls=  (*just makes a doublepop*)
  match ls with
    []->[] (*never be executed*)
  |
    h::h1::t->t
  |
    _->[]
;;

let getlocal ls= (*takes out local list from closure*)
  match ls with
    []->[]  (*never be executed*)
  |
    Clo (e1,e2,str,cnst,cs)::t->e1
  |
    _-> []
;;

let getpara ls= (*takes out the second element from the stack, which is const and takes out name of the parameter from closure and returns (name,const)*)
  match ls with
    []->("null",N "null")  (*never be executed*)
  |
    Clo (e1,e2,str,N n,cs)::h1::t->(n,h1)
  |
    _-> ("null",N "null") (*never be executed*)
;;

let gettop ls=
  match ls with
    []->N "null" (*means function returned empty stack. N null never stay at stack becuase error functions will deal with this*)
  |
    h::t->h

let getclosure ls envg= (*takes top element from the stack which is closure and returns (fname,closure)*)
  match ls with

    Clo (lcl,glbl,fname,n,cs)::t->(fname,Clo (lcl,envg,fname,n,cs))
  |
    _->("null",Clo ([],[],"null",N "null",[]))  (*never be executed*)
;;

let istopint ls=
  match ls with
    []->false
  |
    I n::t->true
  |
    _->false
;;

let rec findcase num cms=
  match cms with
    []->false
  |
    Case (n,css)::t-> if num=n then true else findcase num t
  |
    _->false
;;

let rec helperfindcase num cms=
  match cms with
    []->Case (0,[])
  |
    Case (n,css)::t-> if num=n then Case(n,css) else helperfindcase num t
  |
    _->Case (0,[])
;;

let rec eval coms stack log envl envg =
  (*BASE CASE*)
  if log=["Error"] then (stack,["Error"],envl,envg) else (
    match coms,stack with
      Some(cl,chl),s-> (match cl,chl with 
          [],_->(stack,log,envl,envg)   (* BASE CASE *)
        |
          _,h::t->(stack,["Error"],envl,envg)   (*if the char list is not empty it means bad input is given*)
        |
          h::t,_-> (match h with
              Push n-> eval (Some(t,chl)) (helperpush1 n s) log envl envg
            |
              Pop po->if po>(List.length stack) then eval coms stack (["Error"]) envl envg else if po<0 then eval coms stack (["Error"]) envl envg 
              else eval (Some(t,chl)) (helperpop po stack) log envl envg
            |
              Trace tr->if tr>(List.length stack) then eval coms stack (["Error"]) envl envg else if tr<0 then eval coms stack (["Error"]) envl envg
              else eval (Some(t,chl)) (helperpop tr stack) (helpertrace1 tr stack log) envl envg
            |
              Add ad->if ad>(List.length stack) then eval coms stack (["Error"]) envl envg else if ad<0 then eval coms stack (["Error"]) envl envg
              else eval (Some(t,chl)) (helperaddst ad stack log) (helperaddlo ad stack log) envl envg 
            |
              Sub su->if su>(List.length stack) then eval coms stack (["Error"]) envl envg else if su<0 then eval coms stack (["Error"]) envl envg
              else eval (Some(t,chl)) (helpersubst su stack log)  (helpersublo su stack log) envl envg
            |
              Mul m-> if m>(List.length stack) then eval coms stack (["Error"]) envl envg else if m<0 then eval coms stack (["Error"]) envl envg
              else eval (Some(t,chl)) (helpermulst m stack log) (helpermullo m stack log) envl envg 
            |
              Div di-> if di>(List.length stack) then eval coms stack (["Error"]) envl envg else if di<0 then eval coms stack (["Error"]) envl envg 
              else eval (Some(t,chl)) (helperdivst di stack log) (helperdivlo di stack log) envl envg 
            |
              And-> if 2>(List.length stack) then eval coms stack (["Error"]) envl envg else eval (Some(t,chl)) (helperandst stack log) (helperandlo stack log) envl envg 
            |
              Or->if 2>(List.length stack) then eval coms stack (["Error"]) envl envg else eval (Some(t,chl)) (helperorst stack log) (helperorlo stack log) envl envg 
            |
              Not->if 1>(List.length stack) then eval coms stack (["Error"]) envl envg else eval (Some(t,chl)) (helpernotst stack log) (helpernotlo stack log) envl envg
            |
              Equal->if 2>(List.length stack) then eval coms stack (["Error"]) envl envg else eval (Some(t,chl)) (helperequalst stack log) (helperequallo stack log) envl envg
            |
              Lte->if 2>(List.length stack) then eval coms stack (["Error"]) envl envg else eval (Some(t,chl)) (helperltest stack log) (helperltelo stack log) envl envg
            |
              Local->if 2>(List.length stack) then eval coms stack (["Error"]) envl envg else eval (Some(t,chl)) (helperlocalst stack log) (helperlocallo stack log) (helperlocalEl stack log envl) envg
            |
              Global->if 2>(List.length stack) then eval coms stack (["Error"]) envl envg else eval (Some(t,chl)) (helperglobalst stack log) (helpergloballo stack log) envl (helperglobalEg stack log envg)
            |
              Lookup -> if 0=(List.length stack) then eval coms stack (["Error"]) envl envg else eval (Some(t,chl)) (helperlookupst stack log envl envg) (helperlookuplo stack log envl envg) envl envg
            |
              Begin bs -> (match eval (Some(bs,chl)) [] log envl envg with |([],lg,lcl,gbl)->eval coms stack (["Error"]) envl envg | (st::t1,lg,lcl,gbl)-> eval (Some(t,chl)) (st::stack) lg lcl gbl)
            (*if (helperbeginst bs [] log envl envg)=[] then eval coms stack (["Error"]) envl envg else eval (Some(t,chl)) ((List.hd (helperbeginst bs [] [] envl envg))::s) log envl envg*)
            |
              End-> eval coms stack log envl envg    (*no need*)
            |
              IfElse (comsi,comse)->if (List.length stack)=0 then eval coms stack (["Error"]) envl envg
              else if (not ((List.hd stack)=B false || (List.hd stack)=B true)) then eval coms stack (["Error"]) envl envg
              else if (List.hd stack)=B true then (match eval (Some(comsi,chl)) (List.tl stack) log envl envg with | (st,lg,lcl,gbl)-> eval (Some(t,chl)) st lg lcl gbl)
              (*eval (Some(t,chl)) (helperbeginst comsi (List.tl stack) log envl envg ) (eval (Some(comsi,chl)) (List.tl stack) log envl envg) (helperbeginEg comsi (List.tl stack) log envl envg 0) (helperbeginEg comsi (List.tl stack) log envl envg 1)*)
              else if (List.hd stack)=B false then (match eval (Some(comse,chl)) (List.tl stack) log envl envg with | (st,lg,lcl,gbl)-> eval (Some(t,chl)) st lg lcl gbl)
              else eval coms stack log envl envg
            |
              Fun (fn,n,cs)-> eval (Some(t,chl)) stack log (helperfunEl fn n envl cs) envg
            |
              Call -> if (helpercall stack)=false then eval coms stack (["Error"]) envl envg
              else (match eval (Some((getcoms stack),chl)) [] log ((getclosure stack envg)::(getpara stack)::(getlocal stack)) envg with |([],lg,lcl,gbl)->eval coms stack (["Error"]) envl envg |(st,lg,lcl,gbl)-> eval (Some(t,chl)) ((gettop (st)::(doublepop stack))) lg envl gbl)
            (*let y= ((getclosure stack envg)::(getpara stack)::(getlocal stack)) in let x= helperbeginst (getcoms stack) [] log y envg in eval (Some(t,chl)) ((gettop (x)::(doublepop stack))) (if x=[] then eval coms stack (["Error"]) envl envg else (eval (Some((getcoms stack),chl)) [] log y envg)) envl (helperbeginEg (getcoms stack) [] log y envg 1)*)
            |
              Try cmts->(match eval (Some(cmts,chl)) [] log envl envg with | (st,["Error"],lcl,gbl)->eval (Some(t,chl)) stack log envl gbl |([],lg,lcl,gbl)->eval coms stack ["Error"] envl envg | (st::t1,lg,lcl,gbl)-> eval (Some(t,chl)) (st::stack) lg envl gbl)
            |
              Case (n,css)->(match eval (Some(css,chl)) stack log envl envg with | (st,lg,lcl,gbl)->eval (Some(t,chl)) st lg lcl gbl)
            |
              Switch css->if stack=[] then eval coms stack (["Error"]) envl envg else if (istopint stack)=false then eval coms stack (["Error"]) envl envg 
              else if (findcase (match List.hd stack with |I n->n |_->0) css)=false then eval coms stack (["Error"]) envl envg else eval (Some((helperfindcase (match List.hd stack with |I n->n |_->0) css)::t,chl)) (List.tl stack) log envl envg
          ) 
      )
    |
      None, _->([],[],[],[]) (*Never be executed*) )



(* *)

let interp (src : string) : string list = match (eval (parse (parser()) src) [] [] [] []) with | (st,lg,envl,envg)->lg

;;


(* Calling (main "test.txt") will read the file test.txt and run interp on it.
   This is only used for debugging and will not be used by the gradescope autograder. *)
let main fname =
  let src = readlines fname in
  interp src


(*parse (parser()) "Push 1 Push 2 Begin Push 3 Push 7 Push 4 End Push 5 Push 6";;*)
(*parse (parser()) "Fun f x Push x Lookup Trace 1 Push () End Push 10 Push f Lookup Call Trace 1";;*)


(*if (helperbeginst (getcoms stack) [] log ((getclosure stack envg)::(getpara stack)::(getlocal stack)) envg)=[] then eval coms stack (["Error"]) envl envg else *)

(*after else *** (eval (Some((getcoms stack),chl)) [] log y envg)*)


