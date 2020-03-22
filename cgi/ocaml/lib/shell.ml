
(* https://caml.inria.fr/pub/docs/manual-ocaml/libref/Sys.html *)

let hello () =
  Cgi.w "🌺 At first check if we really have no commandline arguments.";
  let argc = Array.length Sys.argv in
    for i = 0 to argc - 1 do
      Printf.printf "[%i] '%s'\n" i Sys.argv.(i)
    done;
  let cwd = Sys.getcwd () in
    Cgi.w cwd;
  let prg = Sys.executable_name in
    Cgi.w prg;
 (* printf "cwd: '%s'\n" Sys.getcwd (); *)
  0
 
let run () =
  (* prerr_endline Version.git_sha; *)
  let exe = Filename.basename Sys.executable_name in
  let sep = ": " in
  match Array.length Sys.argv with
     | 1 ->
      let lst = [exe; "I need commandline parameters"] in
      let msg = String.concat sep lst in
      prerr_endline msg;
      2
    | _ -> 
      let lst = [exe; "I don't accept commandline parameters"] in
      let msg = String.concat sep lst in
      prerr_endline msg;
      2

