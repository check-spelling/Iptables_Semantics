theory SimpleFw_Semantics
imports Main "../Common/Negation_Type"
  "../Firewall_Common_Decision_State"
  "../Primitive_Matchers/IpAddresses"
  "../Primitive_Matchers/Iface"
  "../Primitive_Matchers/Protocol"
  "../Primitive_Matchers/Simple_Packet"
begin


section{*Simple Firewall Syntax (IPv4 only)*}


  datatype simple_action = Accept | Drop
  
  text{*Simple match expressions do not allow negated expressions.
        However, Most match expressions can still be transformed into simple match expressions.
        
        A negated IP address range can be represented as a set of non-negated IP ranges.
        For example @{text "!8 = {0..7} \<union> {8 .. ipv4max}"}.
        Using CIDR notation (i.e. the @{text "a.b.c.d/n"} notation), we can represent negated IP
        ranges as a set of non-negated IP ranges with only fair blowup.
        Another handy result is that the conjunction of two IP ranges in CIDR notation is 
        either the smaller of the two ranges or the empty set.
        An empty IP range cannot be represented.
        If one wants to represent the empty range, then the complete rule needs to be removed.

        The same holds for layer 4 ports.
        In addition, there exists an empty port range, e.g. @{text "(1,0)"}.
        The conjunction of two port ranges is again just one port range.
        
        But negation of interfaces is not supported. Since interfaces support a wildcard character,
        transforming a negated interface would either result in an infeasible blowup or requires
        knowledge about the existing interfaces (e.g. there only is eth0, eth1, wlan3, and vbox42)
        An empirical test shows that negated interfaces do not occur in our data sets.
        Negated interfaces can also be considered bad style: What is !eth0? Everything that is
        not eth0, experience shows that interfaces may come up randomly, in particular in combination 
        with virtual machines, so !eth0 might not be the desired match.
        At the moment, if an negated interface occurs which prevents translation to a simple match,
        we recommend to abstract the negated interface to unknown and remove it (upper or lower closure
        rule set) before translating to a simple match.
        The same discussion holds for negated protocols.

        Noteworthy, simple match expressions are both expressive and support conjunction:
        @{text "simple-match1 \<and> simple-match2 = simple-match3"}
        *}
        (*It took very long to design the simple match such that it can represent everything we need
        and that you can calculate with it. Disjunction is easy: just have two consecutive rules with the same action.
        Conjunction was a tough fight! It is needed to translate:
        common_primitive_match_to_simple_match (MatchAny e1 e2) =
          simple_match_and (common_primitive_match_to_simple_match e1) (common_primitive_match_to_simple_match e2)
        This is key to translate common_primitive_match to simple_match

        It may seem a simple enhancement to support iiface :: "iface negation_type", but then you
        can no longer for the conjunction of two simple_matches.
        *)
  record simple_match =
    iiface :: "iface" --"in-interface"
      (*we cannot (and don't want to, c.f. git history) express negated interfaces*)
      (*We could also drop interface wildcard support and try negated interfaces again \<dots>*)
    oiface :: "iface" --"out-interface"
    src :: "(ipv4addr \<times> nat) " --"source IP address"
    dst :: "(ipv4addr \<times> nat) " --"destination"
    proto :: "protocol"
    sports :: "(16 word \<times> 16 word)" --"source-port first:last"
    dports :: "(16 word \<times> 16 word)" --"destination-port first:last"


  datatype simple_rule = SimpleRule (match_sel: simple_match) (action_sel: simple_action)

subsection{*Simple Firewall Semantics*}

  fun simple_match_ip :: "(ipv4addr \<times> nat) \<Rightarrow> ipv4addr \<Rightarrow> bool" where
    "simple_match_ip (base, len) p_ip \<longleftrightarrow> p_ip \<in> ipv4range_set_from_prefix base len"

  --"by the way, the words do not wrap around"
  lemma "{(253::8 word) .. 8} = {}" by simp 

  fun simple_match_port :: "(16 word \<times> 16 word) \<Rightarrow> 16 word \<Rightarrow> bool" where
    "simple_match_port (s,e) p_p \<longleftrightarrow> p_p \<in> {s..e}"

  fun simple_matches :: "simple_match \<Rightarrow> 'a simple_packet_scheme \<Rightarrow> bool" where
    "simple_matches m p \<longleftrightarrow>
      (match_iface (iiface m) (p_iiface p)) \<and>
      (match_iface (oiface m) (p_oiface p)) \<and>
      (simple_match_ip (src m) (p_src p)) \<and>
      (simple_match_ip (dst m) (p_dst p)) \<and>
      (match_proto (proto m) (p_proto p)) \<and>
      (simple_match_port (sports m) (p_sport p)) \<and>
      (simple_match_port (dports m) (p_dport p))"


  text{*The semantics of a simple firewall: just iterate over the rules sequentially*}
  fun simple_fw :: "simple_rule list \<Rightarrow> 'a simple_packet_scheme \<Rightarrow> state" where
    "simple_fw [] _ = Undecided" |
    "simple_fw ((SimpleRule m Accept)#rs) p = (if simple_matches m p then Decision FinalAllow else simple_fw rs p)" |
    "simple_fw ((SimpleRule m Drop)#rs) p = (if simple_matches m p then Decision FinalDeny else simple_fw rs p)"
 
  fun simple_fw_alt where
    "simple_fw_alt [] _ = Undecided" |
    "simple_fw_alt (r#rs) p = (if simple_matches (match_sel r) p then 
    	(case action_sel r of Accept \<Rightarrow> Decision FinalAllow | Drop \<Rightarrow> Decision FinalDeny) else simple_fw_alt rs p)"
 
 lemma simple_fw_alt: "simple_fw r p = simple_fw_alt r p" by(induction rule: simple_fw.induct) simp_all


  definition simple_match_any :: "simple_match" where
    "simple_match_any \<equiv> \<lparr>iiface=ifaceAny, oiface=ifaceAny, src=(0,0), dst=(0,0), proto=ProtoAny, sports=(0,65535), dports=(0,65535) \<rparr>"
  lemma simple_match_any: "simple_matches simple_match_any p"
    proof -
      have "(65535::16 word) = max_word" by(simp add: max_word_def)
      thus ?thesis by(simp add: simple_match_any_def ipv4range_set_from_prefix_0 match_ifaceAny)
    qed

  text{*we specify only one empty port range*}
  definition simple_match_none :: "simple_match" where
    "simple_match_none \<equiv> \<lparr>iiface=ifaceAny, oiface=ifaceAny, src=(1,0), dst=(0,0), proto=ProtoAny, sports=(1,0), dports=(0,65535) \<rparr>"
  lemma simple_match_none: "\<not> simple_matches simple_match_none p"
    proof -
      show ?thesis by(simp add: simple_match_none_def)
    qed

  fun empty_match :: "simple_match \<Rightarrow> bool" where
    "empty_match \<lparr>iiface=_, oiface=_, src=_, dst=_, proto=_, sports=(sps1, sps2), dports=(dps1, dps2) \<rparr> \<longleftrightarrow> (sps1 > sps2) \<or> (dps1 > dps2)"

  lemma empty_match: "empty_match m \<longleftrightarrow> (\<forall>(p::'a simple_packet_scheme). \<not> simple_matches m p)"
    proof
      assume "empty_match m"
      thus "\<forall>p. \<not> simple_matches m p" by(cases m) fastforce
    next
      assume assm: "\<forall>(p::'a simple_packet_scheme). \<not> simple_matches m p"
      obtain iif oif sip dip protocol sps1 sps2 dps1 dps2 where m:
        "m = \<lparr>iiface = iif, oiface = oif, src = sip, dst = dip, proto = protocol, sports = (sps1, sps2), dports = (dps1, dps2)\<rparr>"
          by(cases m) force

      show "empty_match m"
        proof(simp add: m)
          let ?x="\<lambda>p. dps1 \<le> p_dport p \<longrightarrow> p_sport p \<le> sps2 \<longrightarrow> sps1 \<le> p_sport p \<longrightarrow> 
              match_proto protocol (p_proto p) \<longrightarrow> simple_match_ip dip (p_dst p) \<longrightarrow> simple_match_ip sip (p_src p) \<longrightarrow>
              match_iface oif (p_oiface p) \<longrightarrow> match_iface iif (p_iiface p) \<longrightarrow> \<not> p_dport p \<le> dps2"
          from assm have nomatch: "\<forall>(p::'a simple_packet_scheme). ?x p" by(simp add: m)
          { fix ips
            from ipv4range_set_from_prefix_lowest have "simple_match_ip ips (fst ips)" by(cases ips) simp
          } note ips=this
          have proto: "match_proto protocol (case protocol of ProtoAny \<Rightarrow> TCP | Proto p \<Rightarrow> p)"
            by(simp split: protocol.split)
          { fix ifce
            have " match_iface ifce (iface_sel ifce)"
            by(cases ifce) (simp add: match_iface_refl)
          } note ifaces=this
          { fix p::"'a simple_packet_scheme"
            from nomatch have "?x p" by blast
          } note pkt1=this
          obtain p::"'a simple_packet_scheme" where [simp]:
			  "p_iiface p = iface_sel iif"
			  "p_oiface p = iface_sel oif"
			  "p_src p = fst sip"
			  "p_dst p = fst dip"
			  "p_proto p = (case protocol of ProtoAny \<Rightarrow> TCP | Proto p \<Rightarrow> p)"
			  "p_sport p = sps1"
			  "p_dport p = dps1"
			  by (meson simple_packet.select_convs)
          note pkt=pkt1[of p, simplified]
          from pkt ips proto ifaces have " sps1 \<le> sps2 \<longrightarrow> \<not> dps1 \<le> dps2" by blast
          thus "sps2 < sps1 \<or> dps2 < dps1" by fastforce
      qed
  qed
    

subsection{*Simple Ports*}
  fun simpl_ports_conjunct :: "(16 word \<times> 16 word) \<Rightarrow> (16 word \<times> 16 word) \<Rightarrow> (16 word \<times> 16 word)" where
    "simpl_ports_conjunct (p1s, p1e) (p2s, p2e) = (max p1s p2s, min p1e p2e)"

  lemma "{(p1s:: 16 word) .. p1e} \<inter> {p2s .. p2e} = {max p1s p2s .. min p1e p2e}" by(simp)
  
  lemma simpl_ports_conjunct_correct: "simple_match_port p1 pkt \<and> simple_match_port p2 pkt \<longleftrightarrow> simple_match_port (simpl_ports_conjunct p1 p2) pkt"
    apply(cases p1, cases p2, simp)
    by blast

  lemma simple_match_port_code[code] :"simple_match_port (s,e) p_p = (s \<le> p_p \<and> p_p \<le> e)" by simp

subsection{*Simple IPs*}
  lemma simple_match_ip_conjunct: "simple_match_ip ip1 p_ip \<and> simple_match_ip ip2 p_ip \<longleftrightarrow> 
         (case ipv4cidr_conjunct ip1 ip2 of None \<Rightarrow> False | Some ipx \<Rightarrow> simple_match_ip ipx p_ip)"
  proof -
  {
    fix b1 m1 b2 m2
    have "simple_match_ip (b1, m1) p_ip \<and> simple_match_ip (b2, m2) p_ip \<longleftrightarrow> 
          p_ip \<in> ipv4range_set_from_prefix b1 m1 \<inter> ipv4range_set_from_prefix b2 m2"
    by simp
    also have "\<dots> \<longleftrightarrow> p_ip \<in> (case ipv4cidr_conjunct (b1, m1) (b2, m2) of None \<Rightarrow> {} | Some (bx, mx) \<Rightarrow> ipv4range_set_from_prefix bx mx)"
      using ipv4cidr_conjunct_correct by blast
    also have "\<dots> \<longleftrightarrow> (case ipv4cidr_conjunct (b1, m1) (b2, m2) of None \<Rightarrow> False | Some ipx \<Rightarrow> simple_match_ip ipx p_ip)"
      by(simp split: option.split)
    finally have "simple_match_ip (b1, m1) p_ip \<and> simple_match_ip (b2, m2) p_ip \<longleftrightarrow> 
         (case ipv4cidr_conjunct (b1, m1) (b2, m2) of None \<Rightarrow> False | Some ipx \<Rightarrow> simple_match_ip ipx p_ip)" .
   } thus ?thesis by(cases ip1, cases ip2, simp)
  qed


declare simple_matches.simps[simp del]


lemma nomatch: "\<not> simple_matches m p \<Longrightarrow> simple_fw (SimpleRule m a # rs) p = simple_fw rs p"
  by(cases a, simp_all)



definition "example_simple_match1 \<equiv> \<lparr>iiface = Iface ''+'', oiface = Iface ''+'', src = (0, 0), dst = (0, 0), proto = Proto TCP, sports = (0, 0x0), dports = (0, 0x0)\<rparr>"
(*export_code simple_fw in SML   not possible here*)
value[code] "simple_fw [
  SimpleRule example_simple_match1 simple_action.Drop]
  
  \<lparr>p_iiface = '''', p_oiface = '''',  p_src = 1, p_dst = 2, p_proto = TCP, p_sport = 8, p_dport = 9, p_tcp_flags = {}, p_tag_ctstate = CT_New\<rparr>"


subsection{*Reality check*}
text{* While it is possible to construct a @{text "simple_fw"} expression that only matches a source
or destination port, such a match is not meaningful, as the presence of the port information is 
dependent on the protocol. Thus, a match for a port should always include the match for a protocol.
Additionally, prefixes should be zero on bits beyond the prefix length.
*}

definition "valid_prefix_fw m = valid_prefix (split PrefixMatch m)"

definition "simple_match_valid m \<equiv> 
(((({p. simple_match_port (sports m) p} \<noteq> UNIV (*\<and> {p. simple_match_port (sports m) p} \<noteq> {}*)) \<or> 
({p. simple_match_port (dports m) p} \<noteq> UNIV (*\<and> {p. simple_match_port (dports m) p} \<noteq> {}*))) 
\<longrightarrow> (proto m \<in> Proto `{TCP, UDP, SCTP})) \<and>
valid_prefix_fw (src m) \<and> valid_prefix_fw (dst m)
)" 

lemma simple_match_valid_alt_hlp1: "{p. simple_match_port x p} \<noteq> UNIV \<longleftrightarrow> (case x of (s,e) \<Rightarrow> s \<noteq> 0 \<or> e \<noteq> max_word)"
	apply(clarsimp simp: set_eq_UNIV split: prod.splits)
	apply(auto)
	 using word_le_0_iff apply blast
	using antisym_conv apply blast
done
lemma simple_match_valid_alt_hlp2: "{p. simple_match_port x p} \<noteq> {} \<longleftrightarrow> (case x of (s,e) \<Rightarrow> s \<le> e)" by auto
lemma simple_match_valid_alt[code_unfold]: "simple_match_valid = (\<lambda> m.
	(let c = (\<lambda>(s,e). (*s \<le> e \<and>*) (s \<noteq> 0 \<or> e \<noteq> max_word)) in (
	if c (sports m) \<or> c (dports m) then proto m = Proto TCP \<or> proto m = Proto UDP \<or> proto m = Proto SCTP else True)) \<and>
valid_prefix_fw (src m) \<and> valid_prefix_fw (dst m))
" 
unfolding fun_eq_iff
unfolding simple_match_valid_def Let_def
unfolding simple_match_valid_alt_hlp1 simple_match_valid_alt_hlp2
by(clarify, rename_tac m, case_tac "sports m"; case_tac "dports m"; case_tac "proto m") auto

definition "example_simple_match2 \<equiv> (proto_update (const ProtoAny) example_simple_match1)"
text{* Thus, @{text "example_simple_match1"} is valid, but if we set its protocol match to any, it no longer is. *}
lemma "simple_match_valid example_simple_match1" by eval
lemma "\<not>simple_match_valid example_simple_match2" by eval

definition "simple_firewall_valid \<equiv> list_all (simple_match_valid \<circ> match_sel)"

end
