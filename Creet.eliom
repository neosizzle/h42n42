[%%client
open Types
open Eliom_content
open Html.D
open Js_of_ocaml
open Js_of_ocaml_lwt

let next_creet_id = ref 0
let size_const = 45.


(* ------------------UTIL------------------ *)
let _get_bg_color state =
  Js.string
    (match state with
    | Healthy -> "green"
    | Sick -> "yellow"
    | Beserk -> "red"
    | Mean -> "purple")

(* Converts number to a px string which DOM understands*)
let _get_px number = Js.string (Printf.sprintf "%fpx" number)

(* Converts scale to actual size on px *)
let _get_size_px scale = size_const *. scale

(* Check if creet is myself *)
let _is_self creet_a creet_b = creet_a.id == creet_b.id

(* Determine if 2 creets are colliding (overlapping) *)
let _is_creet_colliding creet_a creet_b = 
  let a_size = _get_size_px creet_a.scale in 
  let b_size = _get_size_px creet_b.scale in
  (* print_endline ("Creet_A left : " ^ string_of_float creet_a.left ^ ", Creet_A size: " ^ string_of_float a_size);
  print_endline ("Creet_B left : " ^ string_of_float creet_b.left ^ ", Creet_B size: " ^ string_of_float b_size);
  print_endline (string_of_bool ((creet_b.left > creet_a.left) && (creet_b.left <= (creet_a.left +. a_size))));
  print_endline "============================================";
  ((creet_b.left > creet_a.left) && (creet_b.left <= (creet_a.left +. a_size))) *)
  (((creet_b.left > creet_a.left) && (creet_b.left <= (creet_a.left +. a_size))) || 
  (((creet_b.left +. b_size) >= creet_a.left) && (creet_b.left +. b_size) < (creet_a.left +. a_size)))
  &&
  (((creet_b.top > creet_a.top) && (creet_b.top <= (creet_a.top +. a_size))) || 
  (((creet_b.top +. b_size) >= creet_a.top) && ((creet_b.top +. b_size) < (creet_a.top +. a_size))))


(* Handles moving of creet *)
let _handle_mousemove creet event =
  let left = float_of_int event##.clientX -. _get_size_px creet.scale in
  let top = float_of_int event##.clientY -. _get_size_px creet.scale in
  creet.left <- max 0. (min creet.max_left left);
  creet.top <- max 0. (min creet.max_top top);
  creet.dom_elt##.style##.top := _get_px creet.top;
  creet.dom_elt##.style##.left := _get_px creet.left

(* Handles releasing of creet *)
let _handle_mouseup creet _ =
  creet.is_grabbed <- false;
  creet.dom_elt##.style##.opacity := Js.Optdef.return(Js.string "1.0");
  creet.dom_elt##.style##.cursor := Js.string "grab";
  if (creet.top +. _get_size_px creet.scale) >= 555. && creet.state != Healthy then
    begin
      creet.state <- Healthy;
      creet.scale <- 1.
    end
  
(* Handles grabbing of creet *)
let _handle_mousedown creet _ _ =
  creet.is_grabbed <- true;
  creet.dom_elt##.style##.cursor := Js.string "grabbing";
  creet.dom_elt##.style##.opacity := Js.Optdef.return(Js.string "0.5");
  Lwt.pick
  [
    Lwt_js_events.mousemoves Dom_html.document (fun mouse_move _ ->
      _handle_mousemove creet mouse_move;
        Lwt.return ());
    (let%lwt mouse_up = Lwt_js_events.mouseup Dom_html.document in
    _handle_mouseup creet mouse_up;
     Lwt.return ());
  ]


(* Handles creet movement with rebounds*)
let _move_creet creet = 
  if (creet.top +. creet.step_top) >= creet.max_top || (creet.top +. creet.step_top) <= 0. then
    begin
      if creet.top +. creet.step_top >= creet.max_top then
        begin
        creet.step_top <- float_of_int ((Random.int 10) - 11) /. 10.
        end
      else
        begin
          creet.step_top <- float_of_int ((Random.int 10) + 1) /. 10.
        end
    end;

  if (creet.left +. creet.step_left) >= creet.max_left || (creet.left +. creet.step_left) <= 0. then
    begin
      if creet.left +. creet.step_left >= creet.max_left then
        begin
        creet.step_left <- float_of_int ((Random.int 10) - 11) /. 10.
        end
      else
        begin
          creet.step_left <- float_of_int ((Random.int 10) + 1) /. 10.
        end
    end;
  if creet.is_grabbed = false then
    begin
      creet.top <- creet.top +. creet.step_top;
      creet.left <- creet.left +. creet.step_left
    end

(* Roll for mutations for a sick creet *)
let _roll_mutations creet root_state = 
  if creet.state = Sick  then
    begin
      let rng_result = float_of_int(Random.int 100) /. 100. in
      if rng_result <= root_state.mean_percent then
        begin
          creet.state <- Mean
        end;
      let rng_result = float_of_int(Random.int 100) /. 100. in
      if rng_result <= root_state.berserk_percent then 
        begin
          creet.state <- Beserk
        end
    end
  
(* roll for infection when healthy creet contact sick creet*)
let _roll_infection creet root_state = 
  if creet.state = Healthy && creet.is_grabbed = false then
    begin
      let rng_result = float_of_int(Random.int 100) /. 100. in
      if rng_result <= root_state.infect_percent then
        begin
          creet.state <- Sick;
          creet.step_top <- creet.step_top *. 0.75; 
          creet.step_left <- creet.step_left *. 0.75;
          _roll_mutations creet root_state
        end
    end

(* for mean creets, this function will make them follow the next healthy creet*)
let _follow_next_healthy_creet mean_creet root_state = 
  let found_healthy_creet = List.find_opt (fun x -> x.state = Healthy) root_state.creets in
  match found_healthy_creet with 
  | Some healthy_creet ->
    let top_diff = healthy_creet.top -. mean_creet.top in
    let left_diff = healthy_creet.left -. mean_creet.left in
    let total = Float.abs top_diff +. Float.abs left_diff in
    mean_creet.step_top <- top_diff /. total;
    mean_creet.step_left <- left_diff /. total
  | None -> mean_creet.step_top <- mean_creet.step_top

(* Update mutated sick creets properties*)
let _update_mutation_properties creet root_state =
  if creet.state = Beserk && creet.is_grabbed = false then
    begin
      creet.scale <- creet.scale +. 0.001;
      creet.max_top <- 666. -.( _get_size_px creet.scale);
      creet.max_left <- 666. -.( _get_size_px creet.scale)
    end;
  if creet.state = Mean && creet.is_grabbed = false then
    begin
      creet.scale <- 0.75;
      creet.max_top <- 666. -.( _get_size_px creet.scale);
      creet.max_left <- 666. -.( _get_size_px creet.scale);
      _follow_next_healthy_creet creet root_state
    end

(* Updates the speed of the creet based on global acceleration and sick debuffs*)
let _update_speed creet root_state = 
  let global_accel = (float_of_int root_state.iter) *. 0.0001 +. 1. in
  if creet.is_grabbed = false then
    begin
      creet.step_top <- creet.step_top *. global_accel; 
      creet.step_left <- creet.step_left *. global_accel    
    end

(* Detects if current creet is in river, make them sick and roll for mutations *)
let _detect_river creet root_state = 
  if creet.top <= 111. && creet.state = Healthy && creet.is_grabbed = false then
    begin
      creet.state <- Sick;
      creet.step_top <- creet.step_top *. 0.75; 
      creet.step_left <- creet.step_left *. 0.75;
      _roll_mutations creet root_state
    end

(* Detect if current creet is colliding with any creet which is sick, for each non-healthy creet, roll for infection*)
let _detect_infection creet root_state = 
  let non_healthy_contact_creets = List.filter (fun x -> _is_self creet x = false && x.is_grabbed = false && _is_creet_colliding creet x && x.state != Healthy) root_state.creets in
  List.iter (fun _ -> _roll_infection creet root_state) non_healthy_contact_creets

let _kill_berserk creet root_state = 
  if creet.state = Beserk && creet.scale >= 4. then 
    begin
      root_state.creets <- List.filter (fun x -> x.id != creet.id) root_state.creets ;
      Html.Manip.removeSelf creet.elt
    end

let _create_creet creet_id =
  let elt = div ~a:[ a_class [ "creet" ]; a_id ("creet_" ^ (string_of_int creet_id)) ] [] in
  let init_size = _get_size_px 1. in
  let creet = Types.{
    state = Types.Healthy;
    spd_bonus = 1.;
    is_grabbed = false;
    id = creet_id;
    name = "asdf";
    top = float_of_int(Random.int (555 - 45)) +. 111.;
    left = float_of_int(Random.int (666 - 45));
    max_left = 666. -. init_size;
    max_top = 666. -. init_size;
    step_top = float_of_int ((Random.int 20) - 9) /. 10.;
    step_left = float_of_int ((Random.int 20) - 9) /. 10.;
    scale = 1.;

    elt = elt;
    dom_elt = Html.To_dom.of_div elt
  } in
  creet.dom_elt##.style##.backgroundColor := _get_bg_color creet.state;
  creet.dom_elt##.style##.height := _get_px (init_size);
  creet.dom_elt##.style##.width := _get_px (init_size);
  creet.dom_elt##.style##.left := _get_px (creet.left);
  creet.dom_elt##.style##.top := _get_px (creet.top);
  Lwt.async (fun () -> Lwt_js_events.mousedowns creet.dom_elt (_handle_mousedown creet));
  creet
  
(* -------------------API-------------- *)
let rec spawn_initial_creets root_state number =
  if number != 0 then
    let new_creet = _create_creet !next_creet_id in
    next_creet_id := (!next_creet_id + 1) ;
    root_state.creets <- root_state.creets@[new_creet];    
    spawn_initial_creets root_state (number - 1)

let rec spawn_creet root_state  =
  let new_creet = _create_creet !next_creet_id in
  next_creet_id := (!next_creet_id + 1) ;
  root_state.creets <- root_state.creets@[new_creet];
  new_creet

let update_creets creets root_state = 
  List.iter (fun creet -> 
    Lwt.async (fun () ->
      _detect_river creet root_state;
      _update_mutation_properties creet root_state;
      _kill_berserk creet root_state;
      _detect_infection creet root_state;
      _update_speed creet root_state;
      _move_creet creet;
      Lwt.return ())
    ) creets

let apply_creet_updates creets = 
  List.iter (fun creet -> 
    creet.dom_elt##.style##.backgroundColor := _get_bg_color creet.state;
    creet.dom_elt##.style##.height := _get_px (_get_size_px creet.scale);
    creet.dom_elt##.style##.width := _get_px (_get_size_px creet.scale);
    creet.dom_elt##.style##.left := _get_px (creet.left);
    creet.dom_elt##.style##.top := _get_px (creet.top);
    ) creets

let remove_all_creets root_state = 
  List.iter (fun creet -> Html.Manip.removeSelf creet.elt) root_state.creets;
  root_state.creets <- []
]