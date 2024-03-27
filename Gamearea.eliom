[%%client
open Eliom_lib
open Eliom_content
open Html.D
open Js_of_ocaml_lwt

type local_elems = {
  mutable game_info : Html_types.div elt;
  mutable game_board : Html_types.div elt;
}


let elt = div ~a:[a_class ["main__gamearea"]] []

(* Updates game info display*)
let update_game_info (root_state: Types.game) local_elems =
  (*Game information*)
  let game_info = div  [
    span [txt ("endless: " ^ string_of_bool root_state.endless_mode)];
    span [txt (", infect_percent: " ^ string_of_float root_state.infect_percent)];
    span [txt (", berserk_percent: " ^ string_of_float root_state.berserk_percent)];
    span [txt (", mean_percent: " ^ string_of_float root_state.mean_percent)];
    span [txt (", init_healthy_cnt: " ^ string_of_int root_state.init_healthy_cnt)];

  ] in
  Html.Manip.replaceSelf local_elems.game_info game_info;
  local_elems.game_info <- game_info

(*Spwan initial creets*)
let initialize_game (root_state: Types.game) local_elems =
   Creet.spawn_initial_creets root_state root_state.init_healthy_cnt;
   let init_creet_doms = List.map (fun (x: Types.creet) -> x.elt) root_state.creets in
   Html.Manip.appendChildren local_elems.game_board init_creet_doms

(* Update game state *)
let update_game (root_state: Types.game) local_elems =
  root_state.timer_ns <- root_state.timer_ns + 1;
  if root_state.timer_ns >= 300 then
    begin
      root_state.iter <- root_state.iter + 1;
      root_state.timer_ns <- 0;
      let new_creet = Creet.spawn_creet root_state in
      Html.Manip.appendChild local_elems.game_board new_creet.elt
    end;
  let healthy_creets = List.filter (fun (x: Types.creet) -> x.state = Healthy) root_state.creets in
  if List.length healthy_creets = 0 && root_state.endless_mode = false then
    begin
      let msg = "GAME OVER, your score is " ^ (string_of_int (root_state.iter * 300 + root_state.timer_ns)) in
      alert "%s" msg;
      Creet.remove_all_creets root_state;
      root_state.is_start <- false;
      root_state.is_running <- false
    end;
  Creet.update_creets root_state.creets root_state;
  Creet.apply_creet_updates root_state.creets;
  let creet_doms = List.map (fun (x: Types.creet) -> x.elt) root_state.creets in
  List.iter (fun new_creet_dom -> Html.Manip.replaceSelf new_creet_dom new_creet_dom ) creet_doms

let rec loop (root_state: Types.game) local_elems = 
  let%lwt () = Lwt_js.sleep 0.001 in
    update_game_info root_state local_elems;

  if root_state.is_start && (root_state.is_running = false) then begin
      root_state.is_running <- true;
      initialize_game root_state local_elems
  end;

  if root_state.is_start && root_state.is_running then begin
    update_game root_state local_elems
  end;

  loop root_state local_elems

let init (root_state: Types.game) = 
  Random.self_init ();

  let game_info = div [] in

  let game_board = div ~a:
    [ Html.D.a_id "game_board"]
    [
      div ~a:
      [ Html.D.a_id "game_board__river"]
      [
        txt "This is the AIDS river, anyone that comes here will get AIDS 🗣️🗣️!!!"
      ];

      div ~a:
      [ Html.D.a_id "game_board__heal"]
      [
        txt "Welcome to Malaysia, drag an AIDS patient here to give them healing 🫱🏿‍🫲🏻"
      ];
    ] in

  let local_elems = {
    game_info = game_info;
    game_board = game_board;
  } in
  
  Html.Manip.appendChild elt game_info;
  Html.Manip.appendChild elt game_board;
  loop root_state local_elems
]