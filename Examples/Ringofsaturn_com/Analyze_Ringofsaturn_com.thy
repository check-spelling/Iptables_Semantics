theory Analyze_Ringofsaturn_com
imports
 "../Code_Interface"
 "../../Semantics_Ternary/Optimizing"
 "../../Semantics_Ternary/Packet_Set"
begin

section{*Example: ringofsaturn.com*}

(* Based on <http://networking.ringofsaturn.com/Unix/iptables.php> *)
(* Archived at <https://archive.today/3c309> *)

text{* We have directly executable approximating semantics: @{thm approximating_semantics_iff_fun}*}
  lemma "approximating_bigstep_fun (common_matcher, in_doubt_allow)
    \<lparr>p_iiface = ''eth0'', p_oiface = ''eth1'', p_src = ipv4addr_of_dotdecimal (192,168,2,45), p_dst= ipv4addr_of_dotdecimal (173,194,112,111),
         p_proto=TCP, p_sport=2065, p_dport=80\<rparr>
          (process_call [''FORWARD'' \<mapsto> [Rule (Match (Src (Ip4Addr(192,168,0,0)))) action.Drop, Rule MatchAny action.Accept], ''foo'' \<mapsto> []]
                        [Rule MatchAny (Call ''FORWARD'')])
         Undecided
     =
     Decision FinalAllow" by eval



subsection{*Ruleset 1*}

definition "firewall_chains = [''DUMP'' \<mapsto> [Rule (MatchAnd (Match (Src (Ip4AddrNetmask ((0,0,0,0)) (0)))) (MatchAnd (Match (Dst (Ip4AddrNetmask ((0,0,0,0)) (0)))) (MatchAnd (Match (Prot (Proto TCP))) (Match (Extra (''LOG flags 0 level 4'')))))) (action.Log),
Rule (MatchAnd (Match (Src (Ip4AddrNetmask ((0,0,0,0)) (0)))) (MatchAnd (Match (Dst (Ip4AddrNetmask ((0,0,0,0)) (0)))) (MatchAnd (Match (Prot (Proto UDP))) (Match (Extra (''LOG flags 0 level 4'')))))) (action.Log),
Rule (MatchAnd (Match (Src (Ip4AddrNetmask ((0,0,0,0)) (0)))) (MatchAnd (Match (Dst (Ip4AddrNetmask ((0,0,0,0)) (0)))) (MatchAnd (Match (Prot (Proto TCP))) (Match (Extra (''reject-with tcp-reset'')))))) (action.Reject),
Rule (MatchAnd (Match (Src (Ip4AddrNetmask ((0,0,0,0)) (0)))) (MatchAnd (Match (Dst (Ip4AddrNetmask ((0,0,0,0)) (0)))) (MatchAnd (Match (Prot (Proto UDP))) (Match (Extra (''reject-with icmp-port-unreachable'')))))) (action.Reject),
Rule (MatchAnd (Match (Src (Ip4AddrNetmask ((0,0,0,0)) (0)))) (MatchAnd (Match (Dst (Ip4AddrNetmask ((0,0,0,0)) (0)))) (MatchAnd (Match (Prot (ProtoAny))) (MatchAny)))) (action.Drop)],
''STATEFUL'' \<mapsto> [Rule (MatchAnd (Match (Src (Ip4AddrNetmask ((0,0,0,0)) (0)))) (MatchAnd (Match (Dst (Ip4AddrNetmask ((0,0,0,0)) (0)))) (MatchAnd (Match (Prot (ProtoAny))) (Match (Extra (''state RELATED,ESTABLISHED'')))))) (action.Accept),
Rule (MatchAnd (Match (Src (Ip4AddrNetmask ((0,0,0,0)) (0)))) (MatchAnd (Match (Dst (Ip4AddrNetmask ((0,0,0,0)) (0)))) (MatchAnd (Match (Prot (ProtoAny))) (Match (Extra (''state NEW'')))))) (action.Accept),
Rule (MatchAnd (Match (Src (Ip4AddrNetmask ((0,0,0,0)) (0)))) (MatchAnd (Match (Dst (Ip4AddrNetmask ((0,0,0,0)) (0)))) (MatchAnd (Match (Prot (ProtoAny))) (MatchAny)))) (Call (''DUMP''))],
''INPUT'' \<mapsto> [Rule (MatchAnd (Match (Src (Ip4AddrNetmask ((0,0,0,0)) (0)))) (MatchAnd (Match (Dst (Ip4AddrNetmask ((0,0,0,0)) (0)))) (MatchAnd (Match (Prot (ProtoAny))) (MatchAny)))) (Call (''STATEFUL'')),
Rule (MatchAnd (Match (Src (Ip4AddrNetmask ((0,0,0,0)) (0)))) (MatchAnd (Match (Dst (Ip4AddrNetmask ((0,0,0,0)) (0)))) (MatchAnd (Match (Prot (ProtoAny))) (MatchAny)))) (action.Accept),
Rule (MatchAnd (Match (Src (Ip4AddrNetmask ((0,0,0,0)) (8)))) (MatchAnd (Match (Dst (Ip4AddrNetmask ((0,0,0,0)) (0)))) (MatchAnd (Match (Prot (ProtoAny))) (MatchAny)))) (Call (''DUMP'')),
Rule (MatchAnd (Match (Src (Ip4AddrNetmask ((10,0,0,0)) (8)))) (MatchAnd (Match (Dst (Ip4AddrNetmask ((0,0,0,0)) (0)))) (MatchAnd (Match (Prot (ProtoAny))) (MatchAny)))) (Call (''DUMP'')),
Rule (MatchAnd (Match (Src (Ip4AddrNetmask ((127,0,0,0)) (8)))) (MatchAnd (Match (Dst (Ip4AddrNetmask ((0,0,0,0)) (0)))) (MatchAnd (Match (Prot (ProtoAny))) (MatchAny)))) (Call (''DUMP'')),
Rule (MatchAnd (Match (Src (Ip4AddrNetmask ((169,254,0,0)) (16)))) (MatchAnd (Match (Dst (Ip4AddrNetmask ((0,0,0,0)) (0)))) (MatchAnd (Match (Prot (ProtoAny))) (MatchAny)))) (Call (''DUMP'')),
Rule (MatchAnd (Match (Src (Ip4AddrNetmask ((172,16,0,0)) (12)))) (MatchAnd (Match (Dst (Ip4AddrNetmask ((0,0,0,0)) (0)))) (MatchAnd (Match (Prot (ProtoAny))) (MatchAny)))) (Call (''DUMP'')),
Rule (MatchAnd (Match (Src (Ip4AddrNetmask ((224,0,0,0)) (3)))) (MatchAnd (Match (Dst (Ip4AddrNetmask ((0,0,0,0)) (0)))) (MatchAnd (Match (Prot (ProtoAny))) (MatchAny)))) (Call (''DUMP'')),
Rule (MatchAnd (Match (Src (Ip4AddrNetmask ((240,0,0,0)) (8)))) (MatchAnd (Match (Dst (Ip4AddrNetmask ((0,0,0,0)) (0)))) (MatchAnd (Match (Prot (ProtoAny))) (MatchAny)))) (Call (''DUMP'')),
Rule (MatchAnd (Match (Src (Ip4AddrNetmask ((160,86,0,0)) (16)))) (MatchAnd (Match (Dst (Ip4AddrNetmask ((0,0,0,0)) (0)))) (MatchAnd (Match (Prot (ProtoAny))) (MatchAny)))) (action.Accept),
Rule (MatchAnd (Match (Src (Ip4AddrNetmask ((0,0,0,0)) (0)))) (MatchAnd (Match (Dst (Ip4AddrNetmask ((0,0,0,0)) (0)))) (MatchAnd (Match (Prot (ProtoAny))) (MatchAny)))) (action.Drop),
Rule (MatchAnd (Match (Src (Ip4AddrNetmask ((0,0,0,0)) (0)))) (MatchAnd (Match (Dst (Ip4AddrNetmask ((0,0,0,0)) (0)))) (MatchAnd (Match (Extra (''Prot icmp''))) (Match (Extra (''icmptype 3'')))))) (action.Accept),
Rule (MatchAnd (Match (Src (Ip4AddrNetmask ((0,0,0,0)) (0)))) (MatchAnd (Match (Dst (Ip4AddrNetmask ((0,0,0,0)) (0)))) (MatchAnd (Match (Extra (''Prot icmp''))) (Match (Extra (''icmptype 11'')))))) (action.Accept),
Rule (MatchAnd (Match (Src (Ip4AddrNetmask ((0,0,0,0)) (0)))) (MatchAnd (Match (Dst (Ip4AddrNetmask ((0,0,0,0)) (0)))) (MatchAnd (Match (Extra (''Prot icmp''))) (Match (Extra (''icmptype 0'')))))) (action.Accept),
Rule (MatchAnd (Match (Src (Ip4AddrNetmask ((0,0,0,0)) (0)))) (MatchAnd (Match (Dst (Ip4AddrNetmask ((0,0,0,0)) (0)))) (MatchAnd (Match (Extra (''Prot icmp''))) (Match (Extra (''icmptype 8'')))))) (action.Accept),
Rule (MatchAnd (Match (Src (Ip4AddrNetmask ((0,0,0,0)) (0)))) (MatchAnd (Match (Dst (Ip4AddrNetmask ((0,0,0,0)) (0)))) (MatchAnd (Match (Prot (Proto TCP))) (Match (Extra (''tcp dpt:111'')))))) (action.Drop),
Rule (MatchAnd (Match (Src (Ip4AddrNetmask ((0,0,0,0)) (0)))) (MatchAnd (Match (Dst (Ip4AddrNetmask ((0,0,0,0)) (0)))) (MatchAnd (Match (Prot (Proto TCP))) (Match (Extra (''tcp dpt:113 reject-with tcp-reset'')))))) (action.Reject),
Rule (MatchAnd (Match (Src (Ip4AddrNetmask ((0,0,0,0)) (0)))) (MatchAnd (Match (Dst (Ip4AddrNetmask ((0,0,0,0)) (0)))) (MatchAnd (Match (Prot (Proto TCP))) (Match (Extra (''tcp dpt:4'')))))) (action.Accept),
Rule (MatchAnd (Match (Src (Ip4AddrNetmask ((0,0,0,0)) (0)))) (MatchAnd (Match (Dst (Ip4AddrNetmask ((0,0,0,0)) (0)))) (MatchAnd (Match (Prot (Proto TCP))) (Match (Extra (''tcp dpt:20'')))))) (action.Accept),
Rule (MatchAnd (Match (Src (Ip4AddrNetmask ((0,0,0,0)) (0)))) (MatchAnd (Match (Dst (Ip4AddrNetmask ((0,0,0,0)) (0)))) (MatchAnd (Match (Prot (Proto TCP))) (Match (Extra (''tcp dpt:21'')))))) (action.Accept),
Rule (MatchAnd (Match (Src (Ip4AddrNetmask ((0,0,0,0)) (0)))) (MatchAnd (Match (Dst (Ip4AddrNetmask ((0,0,0,0)) (0)))) (MatchAnd (Match (Prot (Proto UDP))) (Match (Extra (''udp dpt:20'')))))) (action.Accept),
Rule (MatchAnd (Match (Src (Ip4AddrNetmask ((0,0,0,0)) (0)))) (MatchAnd (Match (Dst (Ip4AddrNetmask ((0,0,0,0)) (0)))) (MatchAnd (Match (Prot (Proto UDP))) (Match (Extra (''udp dpt:21'')))))) (action.Accept),
Rule (MatchAnd (Match (Src (Ip4AddrNetmask ((0,0,0,0)) (0)))) (MatchAnd (Match (Dst (Ip4AddrNetmask ((0,0,0,0)) (0)))) (MatchAnd (Match (Prot (Proto TCP))) (Match (Extra (''tcp dpt:22'')))))) (action.Accept),
Rule (MatchAnd (Match (Src (Ip4AddrNetmask ((0,0,0,0)) (0)))) (MatchAnd (Match (Dst (Ip4AddrNetmask ((0,0,0,0)) (0)))) (MatchAnd (Match (Prot (Proto UDP))) (Match (Extra (''udp dpt:22'')))))) (action.Accept),
Rule (MatchAnd (Match (Src (Ip4AddrNetmask ((0,0,0,0)) (0)))) (MatchAnd (Match (Dst (Ip4AddrNetmask ((0,0,0,0)) (0)))) (MatchAnd (Match (Prot (Proto TCP))) (Match (Extra (''tcp dpt:80'')))))) (action.Accept),
Rule (MatchAnd (Match (Src (Ip4AddrNetmask ((0,0,0,0)) (0)))) (MatchAnd (Match (Dst (Ip4AddrNetmask ((0,0,0,0)) (0)))) (MatchAnd (Match (Prot (Proto UDP))) (Match (Extra (''udp dpt:80'')))))) (action.Accept),
Rule (MatchAnd (Match (Src (Ip4AddrNetmask ((0,0,0,0)) (0)))) (MatchAnd (Match (Dst (Ip4AddrNetmask ((0,0,0,0)) (0)))) (MatchAnd (Match (Prot (Proto TCP))) (Match (Extra (''tcp dpt:443'')))))) (action.Accept),
Rule (MatchAnd (Match (Src (Ip4AddrNetmask ((0,0,0,0)) (0)))) (MatchAnd (Match (Dst (Ip4AddrNetmask ((0,0,0,0)) (0)))) (MatchAnd (Match (Prot (Proto UDP))) (Match (Extra (''udp dpt:443'')))))) (action.Accept),
Rule (MatchAnd (Match (Src (Ip4AddrNetmask ((0,0,0,0)) (0)))) (MatchAnd (Match (Dst (Ip4AddrNetmask ((0,0,0,0)) (0)))) (MatchAnd (Match (Prot (Proto UDP))) (Match (Extra (''udp dpt:520 reject-with icmp-port-unreachable'')))))) (action.Reject),
Rule (MatchAnd (Match (Src (Ip4AddrNetmask ((0,0,0,0)) (0)))) (MatchAnd (Match (Dst (Ip4AddrNetmask ((0,0,0,0)) (0)))) (MatchAnd (Match (Prot (Proto TCP))) (Match (Extra (''tcp dpts:137:139 reject-with icmp-port-unreachable'')))))) (action.Reject),
Rule (MatchAnd (Match (Src (Ip4AddrNetmask ((0,0,0,0)) (0)))) (MatchAnd (Match (Dst (Ip4AddrNetmask ((0,0,0,0)) (0)))) (MatchAnd (Match (Prot (Proto UDP))) (Match (Extra (''udp dpts:137:139 reject-with icmp-port-unreachable'')))))) (action.Reject),
Rule (MatchAnd (Match (Src (Ip4AddrNetmask ((0,0,0,0)) (0)))) (MatchAnd (Match (Dst (Ip4AddrNetmask ((0,0,0,0)) (0)))) (MatchAnd (Match (Prot (ProtoAny))) (MatchAny)))) (Call (''DUMP'')),
Rule (MatchAny) (action.Accept)],
''FORWARD'' \<mapsto> [Rule (MatchAny) (action.Accept)],
''OUTPUT'' \<mapsto> [Rule (MatchAnd (Match (Src (Ip4AddrNetmask ((0,0,0,0)) (0)))) (MatchAnd (Match (Dst (Ip4AddrNetmask ((0,0,0,0)) (0)))) (MatchAnd (Match (Prot (ProtoAny))) (MatchAny)))) (action.Accept),
Rule (MatchAny) (action.Accept)]]"


text{*It accepts everything in state RELATED,ESTABLISHED,NEW*}
value(code) "unfold_ruleset_INUPUT firewall_chains"
lemma "good_ruleset (unfold_ruleset_INUPUT firewall_chains)" by eval
lemma "simple_ruleset (unfold_ruleset_INUPUT firewall_chains)" by eval

(*Hmm, this ruleset is the Allow-All ruleset!*)
lemma upper: "upper_closure (unfold_ruleset_INUPUT firewall_chains) =
 [Rule MatchAny action.Accept, Rule MatchAny action.Accept, Rule MatchAny action.Drop, Rule MatchAny action.Accept,
  Rule (Match (Src (Ip4AddrNetmask (0, 0, 0, 0) 8))) action.Drop, Rule (Match (Src (Ip4AddrNetmask (10, 0, 0, 0) 8))) action.Drop,
  Rule (Match (Src (Ip4AddrNetmask (127, 0, 0, 0) 8))) action.Drop, Rule (Match (Src (Ip4AddrNetmask (169, 254, 0, 0) 16))) action.Drop,
  Rule (Match (Src (Ip4AddrNetmask (172, 16, 0, 0) 12))) action.Drop, Rule (Match (Src (Ip4AddrNetmask (224, 0, 0, 0) 3))) action.Drop,
  Rule (Match (Src (Ip4AddrNetmask (240, 0, 0, 0) 8))) action.Drop, Rule (Match (Src (Ip4AddrNetmask (160, 86, 0, 0) 16))) action.Accept, Rule MatchAny action.Drop,
  Rule MatchAny action.Accept, Rule MatchAny action.Accept, Rule MatchAny action.Accept, Rule MatchAny action.Accept, Rule (Match (Prot (Proto TCP))) action.Accept,
  Rule (Match (Prot (Proto TCP))) action.Accept, Rule (Match (Prot (Proto TCP))) action.Accept, Rule (Match (Prot (Proto UDP))) action.Accept,
  Rule (Match (Prot (Proto UDP))) action.Accept, Rule (Match (Prot (Proto TCP))) action.Accept, Rule (Match (Prot (Proto UDP))) action.Accept,
  Rule (Match (Prot (Proto TCP))) action.Accept, Rule (Match (Prot (Proto UDP))) action.Accept, Rule (Match (Prot (Proto TCP))) action.Accept,
  Rule (Match (Prot (Proto UDP))) action.Accept, Rule MatchAny action.Drop, Rule MatchAny action.Accept]" by eval

(*<*)
(*please skip over this one!*)
(*>*)

lemma "rmshadow (common_matcher, in_doubt_allow) (upper_closure (unfold_ruleset_INUPUT firewall_chains)) UNIV = 
      [Rule MatchAny action.Accept]"
unfolding upper
apply(subst rmshadow.simps)
apply(simp del: rmshadow.simps)
apply(simp add: Matching_Ternary.matches_def)
done




lemma "approximating_bigstep_fun (common_matcher, in_doubt_allow)
        \<lparr>p_iiface = ''eth0'', p_oiface = ''eth1'', p_src = ipv4addr_of_dotdecimal (192,168,2,45), p_dst= ipv4addr_of_dotdecimal (173,194,112,111),
         p_proto=TCP, p_sport=2065, p_dport=80\<rparr>
          (unfold_ruleset_INUPUT firewall_chains)
         Undecided
        = Decision FinalAllow" by eval






text{*We removed the first matches on state*}
definition "example_firewall2 \<equiv> firewall_chains(''INPUT'' \<mapsto> tl (the (firewall_chains ''INPUT'')))"


value(code) "(unfold_ruleset_INUPUT example_firewall2)"
value(code) "zip (upto 0 (int (length (unfold_ruleset_INUPUT example_firewall2)))) (unfold_ruleset_INUPUT example_firewall2)"
lemma "good_ruleset (unfold_ruleset_INUPUT example_firewall2)" by eval
lemma "simple_ruleset (unfold_ruleset_INUPUT example_firewall2)" by eval

text{*in doubt allow closure*}
value(code) "upper_closure (unfold_ruleset_INUPUT example_firewall2)"

text{*in doubt deny closure*}
value(code) "lower_closure (unfold_ruleset_INUPUT example_firewall2)"


text{*Allowed Packets*}
lemma "collect_allow_impl_v2 (unfold_ruleset_INUPUT example_firewall2) packet_set_UNIV = packet_set_UNIV" by eval

value(code) "allow_set_not_inter (unfold_ruleset_INUPUT example_firewall2)"

value(code) "map packet_set_opt (allow_set_not_inter (unfold_ruleset_INUPUT example_firewall2))"


end
