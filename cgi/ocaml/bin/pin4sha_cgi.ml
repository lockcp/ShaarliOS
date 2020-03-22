(* 
 * https://caml.inria.fr/pub/docs/u3-ocaml/ocaml-steps.html 
 *
 * extract some stuff about the request:
 * - method
 * - request uri
 * - header
 * - cookie(s)
 * - POST form data
 *
 * Response:
 * - http status + reason
 * - header
 *   - content-type
 *   - server
 * - body
 *   - xml+atom (syndic) with xslt and comment prefix,
 *   - xhtml or
 *   - text/plain
 *
 * http://cumulus.github.io/Syndic/syndic/Syndic__/Syndic_atom/#input-and-output
 *
 * other cgi lib:
 * https://gitlab.com/gerdstolpmann/lib-ocamlnet3/blob/master/code/examples/cgi/netcgi2/add.ml
 * http://projects.camlcity.org/projects/dl/ocamlnet-4.1.6/doc/html-main/Netcgi.html#TYPEexn_handler
 *)

open Lib

let () =
  let status =
    match Sys.getenv_opt Cgi.http_request_method with
    | Some _ -> Cgi.run()
    | None   -> Shell.run() in
  exit status;;

