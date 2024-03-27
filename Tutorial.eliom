[%%client
open Eliom_content
open Html.D


let elt = div ~a:[a_class ["main__tutorial"]] [
  div [
    h1 [
      txt "How to play";
    ];
    h3 [
      txt "Objective: preserve the creet civilization.";
    ];
    p [
      span ~a:[a_class ["green"]] [txt "HEALTHY "];
      txt "creets will spawn overtime and walk randomly, they get";
      span ~a:[a_class ["yellow"]] [txt " SICK "];
      txt "when they touch the AIDS river"
    ];
    p [
      txt "Sick creets infect other ";
      span ~a:[a_class ["green"]] [txt " HEALTHY "];
      txt "creets when they touch them."
    ];
    p [
      txt "When a";
      span ~a:[a_class ["green"]] [txt " HEALTHY "];
      txt "creet gets sick, it may mutate to a";
      span ~a:[a_class ["purple"]] [txt " MEAN "];
      txt "creet which, shrinks in size and chases down other";
      span ~a:[a_class ["green"]] [txt " HEALTHY "];
      txt "creets to infect them. Sick creets can also mutate to a ";
      span ~a:[a_class ["red"]] [txt " BERSERK "];
      txt "creet which, grows up to 4x in size and then dies.";
    ];
    p [
      txt "Drag any unhealthy creets to MALAYSIA 🇲🇾🇲🇾 To heal them.";
    ];
    p [
      txt "When there are no healthy creets left, the civilization is demoslished.";
    ];
    p [
      span ~a:[a_class ["bonus"]] [txt "* you can manually tune the parameters in the control panel"];
    ];
    p [
      span ~a:[a_class ["bonus"]] [txt "* endless mode = no game over, enjoy the particles"];
    ];
  ]
]
]