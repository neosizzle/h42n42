[%%client
open Types

(* WET to avoid dependency cycle - bad practice*)
let size_const = 45.
let _get_size_px scale = size_const *. scale

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

let generate_quadtree_root max_levels size =
  Types.{
    max_levels = max_levels;
    top = 0.;
    left = 0.;
    size = size;
  }
]