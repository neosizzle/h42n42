[%%client
open Eliom_content.Html.D
open Js_of_ocaml

type creet_state = Healthy | Mean | Beserk | Sick

type creet = {
  mutable state: creet_state;
  mutable spd_bonus: float;
  mutable is_grabbed: bool;
  id: int;
  mutable name: string;
  mutable top: float;
  mutable left: float;
  mutable max_left: float;
  mutable max_top: float;
  mutable step_top: float;
  mutable step_left: float;
  mutable scale: float;

  mutable elt : Html_types.div elt;
  mutable dom_elt : Dom_html.divElement Js.t;
}

type game = {
  mutable is_start: bool;
  mutable is_running: bool;
  mutable endless_mode: bool;
  mutable timer_ns: int;
  mutable iter: int;
  mutable total_speed: int;
  mutable creets: creet list;
  mutable infect_percent: float;
  mutable mean_percent: float;
  mutable berserk_percent: float;
  mutable init_healthy_cnt: int;
  mutable gamearea_top: int;
  mutable gamearea_btm: int;
  mutable gamearea_width: int;
  mutable gamearea_height: int;
}
]