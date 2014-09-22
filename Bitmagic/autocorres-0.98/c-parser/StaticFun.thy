(*
 * Copyright (C) 2014 NICTA
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions, and the following disclaimer,
 *    without modification.
 *
 * 2. Redistributions in binary form must reproduce at minimum a disclaimer
 *    substantially similar to the "NO WARRANTY" disclaimer below
 *    ("Disclaimer") and any redistribution must be conditioned upon
 *    including a substantially similar Disclaimer requirement for further
 *    binary redistribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
 * IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
 * TO, THE IMPLIED WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * HOLDERS OR CONTRIBUTORS BE LIABLE FOR SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
 * THE POSSIBILITY OF SUCH DAMAGES.
 *)

theory StaticFun
imports
  "../lib/StringOrd"
  "../lib/WordLib"
  "~~/src/HOL/Library/Numeral_Type"
keywords
  "test_tree" "test_tree2" :: thy_decl
begin

datatype ('a, 'b) Tree = Node 'a 'b "('a, 'b) Tree" "('a, 'b) Tree" | Leaf

primrec
  lookup_tree :: "('a, 'b) Tree \<Rightarrow> ('a \<Rightarrow> 'c :: linorder) \<Rightarrow> 'a \<Rightarrow> 'b option"
where
  "lookup_tree Leaf fn x = None"
| "lookup_tree (Node y v l r) fn x = (if fn x = fn y then Some v
                                      else if fn x < fn y then lookup_tree l fn x
                                      else lookup_tree r fn x)"

definition
  tree_gives_vals :: "('a, 'b) Tree \<Rightarrow> ('a \<Rightarrow> 'c :: linorder) \<Rightarrow> ('a \<rightharpoonup> 'b) \<Rightarrow> 'c set \<Rightarrow> bool"
where
 "tree_gives_vals T ord f S \<equiv> \<forall>x. (ord x \<in> S) \<longrightarrow> f x = lookup_tree T ord x"

lemma tree_gives_valsI:
 "\<lbrakk> f \<equiv> lookup_tree T ord \<rbrakk> \<Longrightarrow> tree_gives_vals T ord f UNIV"
  by (simp add: tree_gives_vals_def)

lemma tree_gives_valsD:
  assumes "tree_gives_vals (Node y v l r) ord f S"
  shows "ord y \<in> S \<longrightarrow> f y = Some v"
  and   "tree_gives_vals l ord f (S \<inter> {..<ord y})"
  and   "tree_gives_vals r ord f (S \<inter> {ord y<..})"
  using assms
  apply -
    apply (simp add: tree_gives_vals_def)+
  apply fastforce
  done

lemma tree_gives_vals_setonly_cong:
  "\<lbrakk> S = S' \<rbrakk> \<Longrightarrow> tree_gives_vals T ord f S = tree_gives_vals T ord f S'"
  by simp

lemma tree_vals_set_Int_simps:
  "UNIV \<inter> S = S"
  "({..<(x :: 'a :: linorder)} \<inter> {..<y}) = (if x < y then {..<x} else {..<y})"
  "({x<..} \<inter> {y<..}) = (if x < y then {y<..} else {x<..})"
  "({..<x} \<inter> {y<..}) = ({y<..} \<inter> {..<x})"
  "(({y<..} \<inter> {..<x}) \<inter> {z<..}) = ((if y < z then {z<..} else {y<..}) \<inter> {..<x})"
  "(({y<..} \<inter> {..<x}) \<inter> {..<z}) = ((if x < z then {..<x} else {..<z}) \<inter> {y<..})"
  by auto

lemmas tree_vals_set_simps =
  Int_iff greaterThan_iff lessThan_iff simp_thms UNIV_I
  tree_vals_set_Int_simps if_True if_False

lemma int_0_less_1: "0 < (1::int)" by simp

lemmas int_simpset = arith_simps rel_simps id_apply arith_special int_0_less_1

ML_file "isa_termstypes.ML"
ML_file "static-fun.ML"

(*
test_tree "gamma" 100
locale foo =
  fixes x :: int
;
context foo
begin
;
 test_tree "gamma" 100

Timing:

  test_tree "gamma" 10000

  int/\<longrightarrow>/700 = 32.582
  nat/\<longrightarrow>/700 = 49.643
  int/700    = 33. \<dots>
  int/simps/700 = 6.123
  int/simps/5000 = 65.184 secs
  int/simps/10000 = 154.166
  int/allsimps/700 = 3.00
  int/allsimps/5000 = 26.00 (TS: simps ran in 50sec on mine)
  string/allsimps/700 = 5.76
  string/allsimps/5000 = 47.53
 *)

end
