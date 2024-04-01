# /dev/log for h42n42
This project is about making a simulation of an infectious virus propogation represented by a web game made with Ocsigen's eliom

> This document assumes basic programming and ocaml knowledge

## Installation and project initialization
An eliom project is initialized using the `ocsigen-start` CLI tool; which is a bootstrap software to get started with eliom projects.

```
opam install ocsigen-start
sudo apt-get update
sudo apt-get upgrade
sudo apt get install imagemagick libgmp-dev npm postgresql postgresql-common ruby-sass # optional?
eval $(opam config env)
eliom-distillery -name h42n42 -template client-server.basic
```
Upon running the bootstrap command, I get the following folder structure ;
```
h42n42/
├── Makefile
├── Makefile.eliom
├── Makefile.options
├── README.md
├── assets
│   └── example
├── client
│   └── dune
├── dune
├── dune-project
├── h42n42.conf.in
├── h42n42.eliom
├── h42n42.opam
├── static
│   └── css
│       └── h42n42.css
└── tools
    ├── check_modules.ml
    ├── dune
    ├── gen_dune.ml
    └── sort_deps.ml
```

Since we are developing locally and dont have a public exposed hostname, we will need to change `<host hostfilter="*">` to `<host defaulthostname="localhost" hostfilter="*">` in our `h42n42.conf.in` file. (This file specifies the configuration for oscigenserver, which is a seperate program what serves your files to the client when you run your code.); failture to do this will result in an error like so: `ocsigenserver: main: Fatal - Error in configuration file: Incorrect hostname PC_NAME.`

To run the example, one can do `make test.byte`, and the default port should be `8080`.

![image](https://hackmd.io/_uploads/SyDWJeDJA.png)

## Eliom basics
Like the docs suggest, eliom is a full-stack web and mobile application framework with OCaml as its language. The special thing about eliom is that it follows a multi-tier architecture, which enables the user to generate server side and client side code with just one program.

This is acheiveable by using `[%%client]` and `[%%server]` directives. Though we will only be using client side code for this project.

![image](https://hackmd.io/_uploads/B1g9ZevJA.png)
*multi-tier*
*Image credit: https://ocsigen.org/tuto/latest/manual/basics*

We will be writing source code in .eliom files; the makefile rule will then generate server side code ran by ocamlopt and client side code run by a js engine.

More in-depth explanation can be found in the docs. Now that we have a rough idea on how our code compiles, we can write a simple client side widget that changes some state 

![image](https://raw.githubusercontent.com/neosizzle/h42n42/main/assets/h42n42-statedemo.gif)
*A simple switch*

Unlike other frameworks that handle the reactive binding for you, eliom and OCaml works closer to the native JS; which means for us to listen or react to some events, we need to **keep the reacting component in a loop** which continiously checks a state.

In the the example above, the function that renders the `is_start?` block is in a loop which replaces itself with the actual value of the `is_start` variable. This loop will run forever as long as the webpage is still open.

![image](https://hackmd.io/_uploads/r1tX_YvJ0.png)


As for the buttons and user input, we need to develop our own transmuter between the JS DOM to our eliom app due to the strong typing in ocaml, we are unable to treat an element like a JS DOM object where we can change its elements and properties at our will. An example procedure to get input from a slider would be : 

```ocaml
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
```

And at the rendering part, this function would be used like so : 
```ocaml
  let slider =
  Eliom_content.Html.D.Form.input
      ~a:
        [ Html.D.a_id "sldier_1"
        ; Html.D.a_input_min (`Number 0)
        ; Html.D.a_input_max (`Number 100)
        ; Html.D.a_value (string_of_int local_state.value)
        ; Html.D.a_onchange (fun ev -> 
          match extract_input_slider ev with
          | Some value -> local_state.value <- int_of_string value
          | None -> print_endline ":(" 
      )]
      ~input_type:`Range Html.D.Form.int in
```

## LWT
As we mentioned above, we need to have a loop to constantly update states in the DOM tree. This would cause a problem where it would not be easy to keep track and sequence the updates as the application gets complex. LWT allows us to do these updates concurrently. 

![image](https://hackmd.io/_uploads/SyMt5YvJ0.png)
*The diagram on the right is representing the use of concurrency*

To use concurrency in eliom, it provides us with a [LWT (LightWeight Thread) thread library](https://ocsigen.org/lwt/latest/manual/manual) which does async-pseudo concurrency under the hood. 

For example, if we have a control panel section of the website and a game area of the website with a common state, we can spawn the threads respectively like so 

```ocaml=
let main ()= 
  let init_state = {
    (*initial state...*)
    } in
    
    (*Add to dom..*)
  Html.Manip.appendChildren ~%elt [Gamearea.elt; ControlPanel.elt; Tutorial.elt] ;
  Lwt.async (fun () -> Gamearea.init init_state);
  Lwt.async (fun () -> ControlPanel.init init_state);
]

```

And to return from a thread, one can use `Lwt.return`. This will stop the thread from executing further and return the value which will be called by the async handler in the parent.

## Base game
With the newfound knowledge, I have made 2 seperate sections of the game, one to control the game parameters and another is where the actual game takes place. 

Every loop iteration of the game area, I would check if the game has started by the actions in the control panel. If its started, proceed by updating the game state by drawing the creets (Adding / updating the creet doms in the gamearea) and calculate its next position (top and left) then store it in the local state where we store the information for all the creets.

```ocaml=
(* Update game state *)
(* Types.game is a record which stores information of the game, including all the creets in the game *)
let update_game (root_state: Types.game)  =
  Creet.update_creets root_state.creets root_state; (*Calculate movement*)
  let creet_doms = List.map (fun (x: Types.creet) -> x.elt) root_state.creets in
  List.iter (fun new_creet_dom -> Html.Manip.replaceSelf new_creet_dom new_creet_dom ) creet_doms

let rec loop (root_state: Types.game)  = 
  let%lwt () = Lwt_js.sleep 0.001 in

  if root_state.is_start && (root_state.is_running = false) then begin
      root_state.is_running <- true;
  end;

  if root_state.is_start && root_state.is_running then begin
    update_game root_state 
  end;

  loop root_state
```

Which will result in a simple lava lamp like display

![image](https://raw.githubusercontent.com/neosizzle/h42n42/main/assets/h42n42-creetdemo.gif)

On top of that, the implementation of infections and mutations can also be implemented in the update_game function. The special mean mutation is implemented by changing the color and size of the element along with the position, and instead of a random direction, it selects another healthy creet and calculates the position based on that instead.

![image](https://raw.githubusercontent.com/neosizzle/h42n42/main/assets/h42n42-meandemo.gif)

Mouse events for the creets can be implemented using the `Js_of_ocaml_lwt.Lwt_js_events` module. Since there are 3 actions involving the mouse for the creets, `mousedown`, `mousemove` and `mouseup`, we will have to register multiple handlers for the creet DOM elements.

They are sequential as well, we only need to register the `mousemove` and `mouseup` handlers once the `mousedown` handler had been tripped, so that we dont have any handler code running when we are just hovering over the creet elements; it can be done like so

```ocaml=
(* Handles grabbing of creet *)
let _handle_mousedown creet _ _ =
  creet.is_grabbed <- true;
  (* Other things... *)
  
  (*Lwt.pick will run both function, and if one returns, the other one gets terminated.*)
  (*Spawns mousemove and mouseup handlers*)
  Lwt.pick
  [
    Lwt_js_events.mousemoves Dom_html.document (fun mouse_move _ ->
      _handle_mousemove creet mouse_move;
        Lwt.return ());
    (let%lwt mouse_up = Lwt_js_events.mouseup Dom_html.document in
    _handle_mouseup creet mouse_up;
     Lwt.return ());
  ]
  
(* Cretes a new creet object *)
let _create_creet creet_id =
  let elt = div ~a:[ a_class [ "creet" ]; a_id ("creet_" ^ (string_of_int creet_id)) ] [] in
  let init_size = _get_size_px 1. in
  let creet = Types.{
    (* Properties of the creet *)
  
    elt = elt;
    dom_elt = Html.To_dom.of_div elt
  } in
  (* Spawn mousedown handler *)
  Lwt.async (fun () -> Lwt_js_events.mousedowns creet.dom_elt (_handle_mousedown creet));


```

With the appropriate logic on top of the handlers, we can drag the creets now 
![image](https://raw.githubusercontent.com/neosizzle/h42n42/main/assets/h42n42-finaldemo.gif)
*This is also implemented with a timer which increments every iteration, to calculate the score and gameover condition*

## Collision detection with a quadtree
Since sick creets should be able to infect other creets upon contact, a way to detect of creets collide is needed. The follow is the algorithm to determine if 2 square creets are colliding :
```ocaml=
(* Determine if 2 creets are colliding (overlapping) *)
let _is_creet_colliding creet_a creet_b = 
  let a_size = _get_size_px creet_a.scale in 
  let b_size = _get_size_px creet_b.scale in

  (((creet_b.left > creet_a.left) && (creet_b.left <= (creet_a.left +. a_size))) || 
  (((creet_b.left +. b_size) >= creet_a.left) && (creet_b.left +. b_size) < (creet_a.left +. a_size)))
  &&
  (((creet_b.top > creet_a.top) && (creet_b.top <= (creet_a.top +. a_size))) || 
  (((creet_b.top +. b_size) >= creet_a.top) && ((creet_b.top +. b_size) < (creet_a.top +. a_size))))

```

This would need to be run for every other creet to know which creets are colliding with a single creet.
This approach would be inefficient since it still needs to compute the collision of creets which are far away, which are not colliding for sure; it would be more efficient if we only run this algorithm on creets which are closer instead.

We can do so using a quadtree; by seperating the game canvas into parts of 4, we are able to eliminate the 3 other parts which the creet does not belong in, since they are far from the creet we want to measure.

![image](https://hackmd.io/_uploads/rJZHU5vyR.png)
*image credit: https://stackoverflow.com/questions/41946007/efficient-and-well-explained-implementation-of-a-quadtree-for-2d-collision-det*

Say we want to know which particles are colliding with the blue particle, we can split the canvas into 4 quadrants, and we only run the detection algorithm on the particles on the bottom left quadrant since they have a closer proximity with the blue particle; All other particles are ignored

This is acheiveable by calculating the quadrants of each particle (by comparing midpoints of the bounds); **This is possible due to our bounds are constant and we know the dimensions**; to match the quadrant of the blue particle. If the said particle is not in the same quadrant, the collition detection algorithm wont be run.

We can also be more granular by splitting the canvas further into more fine quadrants, we just need to keep track of the quadrant path took by the blue particle to achive a more finer comparison.

```ocaml=
(* Find out which quadrant a creet is in, and add it to the trace aka path it took. We will define a maximum level here so we wont go forever. *)
let rec calculate_quadrant creet trace tree_node =
  if List.length trace = tree_node.max_levels then
    Types.{
      level = List.length trace;
      quadrant_trace = trace
    }
  else
    let top_midpoint = (tree_node.size /. 2.) +. tree_node.top in
    let left_midpoint = (tree_node.size /. 2.) +. tree_node.left in
    let does_not_fit = (creet.top < top_midpoint && creet.top +. _get_size_px creet.scale > top_midpoint) ||
    (creet.left < left_midpoint && creet.left +. _get_size_px creet.scale > left_midpoint) in
    let is_top_quadrant = creet.top <= top_midpoint in
    let is_left_quadrant = creet.left <= left_midpoint in
    let quadrant_id = 
      if does_not_fit then (-1) else
      if is_top_quadrant && is_left_quadrant = false then 1 else
      if is_top_quadrant = false && is_left_quadrant = false then 2 else
      if is_top_quadrant = false && is_left_quadrant then 3 else
     4 in
     let new_trace = trace@[quadrant_id] in
     let new_treenode = Types.{
      max_levels = tree_node.max_levels;
      top = if is_top_quadrant then tree_node.top else top_midpoint;
      left = if is_left_quadrant then tree_node.left else left_midpoint;
      size = tree_node.size /. 2.
     } in
     calculate_quadrant creet new_trace new_treenode

(* compare two traces to make sure creet node and cmp node are in same quadrant. This returns false immediately once a difference is detected *)
let rec compare_trace creet trace tree_node cmp =
  let last_elem_idx = List.length trace - 1 in
  if last_elem_idx >= 0 && List.length trace >= tree_node.max_levels then
    List.nth trace last_elem_idx == List.nth cmp last_elem_idx
  else if last_elem_idx >= 0 && List.nth trace last_elem_idx = -1 then
    true
  else if last_elem_idx >= 0 && List.nth trace last_elem_idx != List.nth cmp last_elem_idx then 
    false
  else if last_elem_idx >= 0 && List.length trace >= List.length cmp then
    true
  else
    let top_midpoint = (tree_node.size /. 2.) +. tree_node.top in
    let left_midpoint = (tree_node.size /. 2.) +. tree_node.left in
    let does_not_fit = (creet.top < top_midpoint && creet.top +. _get_size_px creet.scale > top_midpoint) ||
    (creet.left < left_midpoint && creet.left +. _get_size_px creet.scale > left_midpoint) in
    let is_top_quadrant = creet.top <= top_midpoint in
    let is_left_quadrant = creet.left <= left_midpoint in
    let quadrant_id = 
    if does_not_fit then (-1) else
    if is_top_quadrant && is_left_quadrant = false then 1 else
    if is_top_quadrant = false && is_left_quadrant = false then 2 else
    if is_top_quadrant = false && is_left_quadrant then 3 else
   4 in
   let new_trace = trace@[quadrant_id] in
   let new_treenode = Types.{
    max_levels = tree_node.max_levels;
    top = if is_top_quadrant then tree_node.top else top_midpoint;
    left = if is_left_quadrant then tree_node.left else left_midpoint;
    size = tree_node.size /. 2.
   } in
    compare_trace creet new_trace new_treenode cmp

```

The idea behind this approach instead of the clear-write-split approach is to prevent unessasary copies when bookeeping other states of the creet is done by another data structure.