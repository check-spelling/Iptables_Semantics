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

theory CTranslation
imports
  "PackedTypes"
  "PrettyProgs"
  "StaticFun"
  "IndirectCalls"
keywords
  "install_C_file"
  "install_C_types"
  "new_C_include_dir":: thy_decl
and
  "memsafe"
  "c_types"
  "c_defs"
begin

lemma TWO: "Suc (Suc 0) = 2"
by arith

definition
  fun_addr_of :: "int \<Rightarrow> unit ptr" where
  "fun_addr_of i \<equiv> Ptr (word_of_int i)"

definition
  ptr_range :: "'a::c_type ptr \<Rightarrow> addr set" where
  "ptr_range p \<equiv> {ptr_val (p::'a ptr) ..<
      ptr_val p + word_of_int(int(size_of (TYPE('a)))) }"

definition
  creturn :: "((c_exntype \<Rightarrow> c_exntype) \<Rightarrow> ('c, 'd) state_scheme \<Rightarrow> ('c, 'd) state_scheme)
      \<Rightarrow> (('a \<Rightarrow> 'a) \<Rightarrow> ('c, 'd) state_scheme \<Rightarrow> ('c, 'd) state_scheme)
      \<Rightarrow> (('c, 'd) state_scheme \<Rightarrow> 'a) \<Rightarrow> (('c, 'd) state_scheme,'p,'f) com"
where
  "creturn rtu xfu v \<equiv> (Basic (\<lambda>s. xfu (\<lambda>_. v s) s);; (Basic (rtu (\<lambda>_. Return));; THROW))"

definition
  creturn_void :: "((c_exntype \<Rightarrow> c_exntype) \<Rightarrow> ('c, 'd) state_scheme
      \<Rightarrow> ('c, 'd) state_scheme) \<Rightarrow> (('c, 'd) state_scheme,'p,'f) com"
where
  "creturn_void rtu \<equiv> (Basic (rtu (\<lambda>_. Return));; THROW)"

definition
  cbreak :: "((c_exntype \<Rightarrow> c_exntype) \<Rightarrow> ('c, 'd) state_scheme
      \<Rightarrow> ('c, 'd) state_scheme) \<Rightarrow> (('c, 'd) state_scheme,'p,'f) com"
where
  "cbreak rtu \<equiv> (Basic (rtu (\<lambda>_. Break));; THROW)"

definition
  ccatchbrk :: "( ('c, 'd) state_scheme \<Rightarrow> c_exntype) \<Rightarrow> (('c, 'd) state_scheme,'p,'f) com"
where
  "ccatchbrk rt \<equiv> Cond {s. rt s = Break} SKIP THROW"

ML_file "tools/mlyacc/mlyacclib/MLY_base-sig.ML"
ML_file "tools/mlyacc/mlyacclib/MLY_join.ML"
ML_file "tools/mlyacc/mlyacclib/MLY_lrtable.ML"
ML_file "tools/mlyacc/mlyacclib/MLY_stream.ML"
ML_file "tools/mlyacc/mlyacclib/MLY_parser2.ML"
ML_file "FunctionalRecordUpdate.ML"
ML_file "topo_sort.ML"

definition
  cchaos :: "('b \<Rightarrow> 'a \<Rightarrow> 'a) \<Rightarrow> ('a,'c,'d) com"
where
  "cchaos upd \<equiv> Spec { (s0,s) . \<exists>v. s = upd v s0 }"

ML_file "StrictC.grm.sig"
ML_file "StrictC.grm.sml"
ML_file "StrictC.lex.sml"
ML_file "StrictCParser.ML"
ML_file "complit.ML"
ML_file "hp_termstypes.ML"
ML_file "termstypes-sig.ML"
ML_file "termstypes.ML"
ML_file "UMM_termstypes.ML"
ML_file "recursive_records/recursive_record_pp.ML"
ML_file "recursive_records/recursive_record_package.ML"
ML_file "expression_typing.ML"
ML_file "UMM_Proofs.ML"
ML_file "program_analysis.ML"
ML_file "heapstatetype.ML"
ML_file "MemoryModelExtras-sig.ML"
ML_file "MemoryModelExtras.ML"
ML_file "calculate_state.ML"
ML_file "syntax_transforms.ML"
ML_file "expression_translation.ML"
ML_file "modifies_proofs.ML"
ML_file "HPInter.ML"
ML_file "stmt_translation.ML"
ML_file "isar_install.ML" 

declare typ_info_word [simp del]
declare typ_info_ptr [simp del]

lemma creturn_wp [vcg_hoare]:
  assumes "P \<subseteq> {s. (exnupd (\<lambda>_. Return)) (rvupd (\<lambda>_. v s) s) \<in> A}"
  shows "\<Gamma>,\<Theta>\<turnstile>\<^bsub>/F \<^esub>P creturn exnupd rvupd v Q, A"
  unfolding creturn_def
  by vcg

lemma creturn_void_wp [vcg_hoare]:
  assumes "P \<subseteq> {s. (exnupd (\<lambda>_. Return)) s \<in> A}"
  shows "\<Gamma>,\<Theta>\<turnstile>\<^bsub>/F \<^esub>P creturn_void exnupd Q, A"
  unfolding creturn_void_def
  by vcg

lemma cbreak_wp [vcg_hoare]:
  assumes "P \<subseteq> {s. (exnupd (\<lambda>_. Break)) s \<in> A}"
  shows "\<Gamma>,\<Theta>\<turnstile>\<^bsub>/F \<^esub>P cbreak exnupd Q, A"
  unfolding cbreak_def
  by vcg

lemma ccatchbrk_wp [vcg_hoare]:
  assumes "P \<subseteq> {s. (exnupd s = Break \<longrightarrow> s \<in> Q) \<and>
                    (exnupd s \<noteq> Break \<longrightarrow> s \<in> A)}"
  shows "\<Gamma>,\<Theta>\<turnstile>\<^bsub>/F \<^esub>P ccatchbrk exnupd Q, A"
  unfolding ccatchbrk_def
  by vcg

lemma lvar_nondet_init_wp [vcg_hoare]:
  "P \<subseteq> {s. \<forall>v. (upd (\<lambda>_. v)) s \<in> Q} \<Longrightarrow> \<Gamma>,\<Theta>\<turnstile>\<^bsub>/F \<^esub> P lvar_nondet_init accessor upd Q, A"
  unfolding lvar_nondet_init_def
  by (rule HoarePartialDef.conseqPre, vcg, auto)

lemma mem_safe_lvar_init [simp,intro]:
  assumes upd: "\<And>g v s. globals_update g (upd (\<lambda>_. v) s) = upd (\<lambda>_. v) (globals_update g s)"
  assumes acc: "\<And>v s. globals (upd (\<lambda>_. v) s) = globals s"
  assumes upd_acc: "\<And>s. upd (\<lambda>_. accessor s) s = s"
  shows "mem_safe (lvar_nondet_init accessor upd) x"
  apply (clarsimp simp: mem_safe_def lvar_nondet_init_def)
  apply (erule exec.cases, simp_all)
   apply clarsimp
   apply (clarsimp simp: restrict_safe_def restrict_safe_OK_def acc)
   apply (rule exec.Spec)
   apply clarsimp
   apply (rule exI)
   apply (simp add: restrict_htd_def upd acc)
  apply (clarsimp simp: restrict_safe_def)
  apply (simp add: exec_fatal_def)
  apply (rule disjI2)
  apply (rule exec.SpecStuck)
  apply (clarsimp simp: restrict_htd_def upd acc)
  apply (erule allE)+
  apply (erule notE)
  apply (rule sym)
  apply (rule upd_acc)
  done

lemma intra_safe_lvar_nondet_init [simp]:
  "intra_safe (lvar_nondet_init accessor upd :: (('a::heap_state_type','d) state_scheme,'b,'c) com) =
  (\<forall>\<Gamma>. mem_safe (lvar_nondet_init accessor upd :: (('a::heap_state_type','d) state_scheme,'b,'c) com) (\<Gamma> :: (('a,'d) state_scheme,'b,'c) body))"
  by (simp add: lvar_nondet_init_def)

lemma proc_deps_lvar_nondet_init [simp]:
  "proc_deps (lvar_nondet_init accessor upd) \<Gamma> = {}"
  by (simp add: lvar_nondet_init_def)

end
