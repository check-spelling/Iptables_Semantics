(*
 * Copyright (C) 2014, National ICT Australia Limited. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *  * Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *
 *  * Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 *  * The name of National ICT Australia Limited nor the names of its
 *    contributors may be used to endorse or promote products derived from
 *    this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
 * IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
 * TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 * PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *)

(*Alternate apply command which displays "used" theorems in refinement step*)

theory Apply_Trace_Cmd
imports Apply_Trace
keywords "apply_trace" :: prf_script
begin

ML{*

structure Filter_Thms = Named_Thms
(
  val name = @{binding no_trace}
  val description = "thms to be ignored from tracing"
)

datatype adjusted_name =
  FoundName of ((string * int option) * thm)
  | UnknownName of (string * term)


(* Parse the index of a theorem name in the form "x_1". *)
fun parse_thm_index name =
  case (String.tokens (fn c => c = #"_") name |> rev) of
      (possible_index::xs) =>
         (case Lexicon.read_nat possible_index of
            SOME n => (space_implode "_" (rev xs), SOME (n - 1))
          | NONE => (name, NONE))
    | _ => (name, NONE)

(*
 * Names stored in proof bodies may have the form "x_1" which can either
 * mean "x(1)" or "x_1". Attempt to determine the correct name for the
 * given theorem. If we can't find the correct theorem, or it is
 * ambiguous, return the original name.
 *)
fun adjust_thm_name ctxt name term =
let
  val possible_names = distinct (op =) [(name, NONE), parse_thm_index name]
  fun match (n, i) =
  let
    val idx = the_default 0 i
    val thms = Proof_Context.get_fact ctxt (Facts.named n) handle ERROR _ => []
  in
    if idx >= 0 andalso length thms > idx then
      SOME ((n, i), nth thms idx)
    else
      NONE
  end
in
  case map_filter match possible_names of
    [x] => FoundName x
    | _ => UnknownName (name, term)
end

(* Render the given fact. *)
fun pretty_fact ctxt (FoundName ((name, idx), thm)) =
      Pretty.block
        [Pretty.mark_str (Facts.markup_extern ctxt (Proof_Context.facts_of ctxt) name),
          case idx of
            SOME n => Pretty.str ("(" ^ string_of_int (n + 1) ^ "):")
          | NONE => Pretty.str ":",
          Pretty.brk 1, Display.pretty_thm ctxt thm]
  | pretty_fact ctxt (UnknownName (name, prop)) =
      Pretty.block
        [Pretty.str name, Pretty.str "(?) :", Pretty.brk 1,
          Syntax.unparse_term ctxt prop]

(* Print out the found dependencies. *)
fun print_deps ctxt text thm deps =
let
  (* Remove duplicates. *)
  val deps = sort_distinct (prod_ord string_ord Term_Ord.term_ord) deps

  (* Retrieve facts which are explicitly mentioned in the method invocation. *)
  val mentioned_facts = Apply_Trace.mentioned_facts ctxt text
  |> map (fn thm => (Thm.get_name_hint thm, prop_of thm))

  (* Fetch canonical names and theorems. *)
  val (deps,mentioned_facts) = chop (length deps) (map (fn (name, term) => adjust_thm_name ctxt name term) (deps @ mentioned_facts))

  (* Find mentioned, but unused facts *)
  val unused_facts = subtract (fn (FoundName ((nm,_),_),FoundName ((nm',_),_)) => nm = nm' 
                               | _ => false) deps mentioned_facts

  (* Remove "boring" theorems. *)
  val deps = subtract (fn (a, FoundName (_, thm)) => Thm.eq_thm (thm, a)
                          | _ => false) (Filter_Thms.get ctxt) deps

  val _ = if null unused_facts then () else
  (Pretty.writeln (
    Pretty.big_list "mentioned, but unused theorems:"
      (map (Pretty.item o single o pretty_fact ctxt) unused_facts)))

in
  (* Pretty-print resulting theorems. *)
  Pretty.writeln (
    Pretty.big_list "used theorems:"
      (map (Pretty.item o single o pretty_fact ctxt) deps))

end

val _ =
  Outer_Syntax.command @{command_spec "apply_trace"} "initial refinement step (unstructured)"
    (Method.parse >> (Toplevel.proofs o (Apply_Trace.apply_results {localize_facts = true, silent_fail = false} print_deps)));

*}

setup {* Filter_Thms.setup *}

lemmas [no_trace] = protectI protectD TrueI Eq_TrueI eq_reflection

end
