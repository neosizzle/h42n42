[%%client
(* open Eliom_lib *)
open Eliom_content
open Html.D
open Js_of_ocaml_lwt
open Js_of_ocaml

type local_state = {
  mutable infect_percent_int: int;
  mutable berserk_percent_int: int;
  mutable mean_percent_int: int;
  mutable init_healthy_cnt: int;
  mutable endless_mode: bool;
}

let elt = div ~a:[a_class ["main__ctrlpnl"]] []

(* Extract input from a slider given an onchange event *)
let extract_input_slider ev =
  (*the ## operator is used to find to JS objects as shown here https://ocsigen.org/js_of_ocaml/latest/manual/bindings*)
  match Js.Opt.to_option (ev##.target) with
  (* Since JS objects are all nullable by default, we need to check for None everytime we bind *)
  | None -> None
  | Some target ->

    (*Js.Opt.bind is used to chain optional operations.
    It takes an optional value and a function that returns an optional value.
    If the first optional value is None, Js.Opt.bind returns None.
    If the first optional value is Some x, it applies the function to x and returns the result.*)

    (*Dom.CoerceTo.element will try to convert a raw JS object node (can be text, element or attribute) into an element type
      To cast that type into more specific types, like input field, we need to use Js.Unsafe.coerce so that we can access the value property in input field
    https://ocsigen.org/js_of_ocaml/latest/api/js_of_ocaml/Js_of_ocaml/Dom/CoerceTo/index.html

    *)
    let input_element = Js.Opt.to_option (Js.Opt.bind (Dom.CoerceTo.element target) (fun elem ->
      if Js.to_string elem##.tagName = "INPUT" then
        Js.Opt.return (Js.Unsafe.coerce elem)
      else
        Js.Opt.empty)) in

      match input_element with
      | Some input ->
          Some (Js.to_string (input##.value))
      | None -> None

let set_disabled_slider dom_node value = 
  let input_element = Js.Opt.to_option (Js.Opt.bind (Dom.CoerceTo.element dom_node) (fun elem ->
    if Js.to_string elem##.tagName = "INPUT" then
      Js.Opt.return (Js.Unsafe.coerce elem)
    else
      Js.Opt.empty)) in

    match input_element with
    | Some input ->
        input##.disabled := value;
    | _ -> print_endline "input expected @ set_disabled_slider"

let set_disabled_button dom_node value = 
  let input_element = Js.Opt.to_option (Js.Opt.bind (Dom.CoerceTo.element dom_node) (fun elem ->
    if Js.to_string elem##.tagName = "BUTTON" then
      Js.Opt.return (Js.Unsafe.coerce elem)
    else
      Js.Opt.empty)) in

    match input_element with
    | Some input ->
        input##.disabled := value;
    | _ -> print_endline "button expected @ set_disabled_button"

let rec loop (root_state: Types.game) = 
  let%lwt () = Lwt_js.sleep 0.001 in
    if root_state.is_start then begin
      let infect_slider = Dom_html.getElementById "infect_percent" in
      set_disabled_slider infect_slider Js._true ;

      let berserk_slider = Dom_html.getElementById "berserk_percent" in
      set_disabled_slider berserk_slider Js._true ;

      let mean_slider = Dom_html.getElementById "mean_percent" in
      set_disabled_slider mean_slider Js._true ;

      let healthy_slider = Dom_html.getElementById "init_healthy_cnt" in
      set_disabled_slider healthy_slider Js._true ;

      let endless_mode = Dom_html.getElementById "endless_mode" in
      set_disabled_slider endless_mode Js._true ;

      if root_state.endless_mode = false then
        begin
          let start_btn = Dom_html.getElementById "start_btn" in
          set_disabled_button start_btn Js._true ;
        end

    end else begin
      let berserk_slider = Dom_html.getElementById "berserk_percent" in
      set_disabled_slider berserk_slider Js._false ;

      let infect_slider = Dom_html.getElementById "infect_percent" in
      set_disabled_slider infect_slider Js._false ;

      let mean_slider = Dom_html.getElementById "mean_percent" in
      set_disabled_slider mean_slider Js._false ;

      let healthy_slider = Dom_html.getElementById "init_healthy_cnt" in
      set_disabled_slider healthy_slider Js._false ;

      let endless_mode = Dom_html.getElementById "endless_mode" in
      set_disabled_slider endless_mode Js._false ;
      
      if root_state.endless_mode = false then
        begin
          let start_btn = Dom_html.getElementById "start_btn" in
          set_disabled_button start_btn Js._false ;
        end
    end ;
    loop root_state


let init (root_state: Types.game) = 

  (* Declare initial local states *)
  let local_state = {
    infect_percent_int = 2;
    berserk_percent_int = 10;
    mean_percent_int = 10;
    init_healthy_cnt = 2;
    endless_mode = false;
  } in

  (* Start button *)
  let start_btn = button ~a:[
    a_id "start_btn"
    ; a_onclick (fun _ ->
    root_state.is_start <- if root_state.is_start then false else true ;
    root_state.infect_percent <- ((float_of_int local_state.infect_percent_int) /. 10000.0);
    root_state.berserk_percent <- ((float_of_int local_state.berserk_percent_int) /. 100.0);
    root_state.mean_percent <- ((float_of_int local_state.mean_percent_int) /. 100.0);
    root_state.init_healthy_cnt <- local_state.init_healthy_cnt;
    print_endline (string_of_bool local_state.endless_mode);
    root_state.endless_mode <- local_state.endless_mode
  )]  [txt "start/pause"] in

  let infect_percent_slider =
  Eliom_content.Html.D.Form.input
      ~a:
        [ Html.D.a_id "infect_percent"
        ; Html.D.a_input_min (`Number 0)
        ; Html.D.a_input_max (`Number 100)
        ; Html.D.a_value (string_of_int local_state.infect_percent_int)
        ; Html.D.a_onchange (fun ev -> 
          match extract_input_slider ev with
          | Some value -> local_state.infect_percent_int <- int_of_string value
          | None -> print_endline ":(" 
      )]
      ~input_type:`Range Html.D.Form.int in

  let berserk_percent_slider =
    Eliom_content.Html.D.Form.input
        ~a:
          [ Html.D.a_id "berserk_percent"
          ; Html.D.a_input_min (`Number 0)
          ; Html.D.a_input_max (`Number 100)
          ; Html.D.a_value (string_of_int local_state.berserk_percent_int)
          ; Html.D.a_onchange (fun ev -> 
            match extract_input_slider ev with
            | Some value -> local_state.berserk_percent_int <- int_of_string value
            | None -> print_endline ":(" 
        )]
      ~input_type:`Range Html.D.Form.int in    

  let mean_percent_slider =
    Eliom_content.Html.D.Form.input
        ~a:
          [ Html.D.a_id "mean_percent"
          ; Html.D.a_input_min (`Number 0)
          ; Html.D.a_input_max (`Number 100)
          ; Html.D.a_value (string_of_int local_state.mean_percent_int)
          ; Html.D.a_onchange (fun ev -> 
            match extract_input_slider ev with
            | Some value -> local_state.mean_percent_int <- int_of_string value
            | None -> print_endline ":(" 
        )]
      ~input_type:`Range Html.D.Form.int in  

    let healthy_cnt_slider =
      Eliom_content.Html.D.Form.input
          ~a:
            [ Html.D.a_id "init_healthy_cnt"
            ; Html.D.a_input_min (`Number 2)
            ; Html.D.a_input_max (`Number 100)
            ; Html.D.a_value (string_of_int local_state.init_healthy_cnt)
            ; Html.D.a_onchange (fun ev -> 
              match extract_input_slider ev with
              | Some value -> local_state.init_healthy_cnt <- int_of_string value
              | None -> print_endline ":(" 
          )]
        ~input_type:`Range Html.D.Form.int in  

let endless_mode_checkbox =
  Eliom_content.Html.D.Form.input
      ~a:
        [ Html.D.a_id "endless_mode"
        ; Html.D.a_value (string_of_bool local_state.endless_mode)
        ; Html.D.a_onchange (fun _ -> 
          local_state.endless_mode <- not local_state.endless_mode
      )]
      ~input_type:`Checkbox Html.D.Form.bool in

  Html.Manip.appendChild elt start_btn;
  Html.Manip.appendChild elt (div ~a:[a_class ["infect_percent_slider_wrapper"]] [span [txt "infect%: "; infect_percent_slider]]) ;
  Html.Manip.appendChild elt (div ~a:[a_class ["berserk_percent_slider_wrapper"]] [span [txt "berserk%: "; berserk_percent_slider]]) ;
  Html.Manip.appendChild elt (div ~a:[a_class ["mean_percent_slider_wrapper"]] [span [txt "mean%: "; mean_percent_slider]]) ;
  Html.Manip.appendChild elt (div ~a:[a_class ["healthy_cntslider_wrapper"]] [span [txt "init_healthy_cnt: "; healthy_cnt_slider]]) ;
  Html.Manip.appendChild elt (div ~a:[a_class ["endless_mode_wrapper"]] [span [txt "endless: "; endless_mode_checkbox]]) ;

  loop root_state
]
