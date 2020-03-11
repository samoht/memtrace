open Memtrace
let dump filename =
  let trace = open_trace ~filename in
  let last = ref [| |] in
  iter_trace trace (fun time ev ->
    Printf.printf "%010Ld " time;
    match ev with
  | Alloc {obj_id; length; nsamples; is_major; common_prefix; new_suffix} ->
    Printf.printf "%010d %s %d len=%d % 4d:" (obj_id :> int) (if is_major then "alloc_major" else "alloc") nsamples length common_prefix;
    let print_location ppf { filename; line; start_char; end_char; defname  } =
      Printf.fprintf ppf "%s@%s:%d:%d-%d" defname filename line start_char end_char in
    let bt = Array.concat [Array.sub !last 0 common_prefix; Array.of_list new_suffix] in
    last := bt;
    bt |> Array.iter (fun s ->
      match lookup_location trace s with
      | [] -> Printf.printf " $%Ld" (s :> Int64.t)
      | ls -> ls |> List.iter (Printf.printf " %a" print_location));
    Printf.printf "\n%!"
  | Promote id ->
    Printf.printf "%010d promote\n" (id :> int)
  | Collect id ->
    Printf.printf "%010d collect\n" (id :> int));
  close_trace trace


let () =
  if Array.length Sys.argv <> 2 then
    Printf.fprintf stderr "Usage: %s <trace file>\n" Sys.executable_name
  else
    dump Sys.argv.(1)