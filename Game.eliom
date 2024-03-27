[%%shared
open Eliom_content.Html.D

let elt = div ~a:[a_class ["main"]] []
(**)]

[%%client
open Eliom_content
open Eliom_content.Html.D

open Types

type game_state = {
  mutable count: int;
  mutable dom: Html_types.div elt;
}

let main ()= 
  let init_state = {
    quadtree_root = Quadtree.generate_quadtree_root 2 666.; (* HARDCODED SIZE *)
    is_start = false;
    is_running = false;
    endless_mode = false;
    timer_ns = 0;
    iter = 0;
    total_speed = 0;
    creets = [];
    infect_percent = 0.02;
    mean_percent = 0.1;
    berserk_percent = 0.1;
    init_healthy_cnt = 2;
    gamearea_top = 0;
    gamearea_btm = 0;
    gamearea_width = 0;
    gamearea_height = 0;
    } in
  Html.Manip.appendChildren ~%elt [Gamearea.elt; ControlPanel.elt; Tutorial.elt] ;
  Lwt.async (fun () -> Gamearea.init init_state);
  Lwt.async (fun () -> ControlPanel.init init_state);
]


