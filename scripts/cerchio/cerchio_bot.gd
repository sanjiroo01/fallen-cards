class_name CerchioBot
extends RefCounted
## Avversari del prototipo: stimano chi li attaccherà, danno un valore a ogni mossa e scelgono
## con un po' di caso (softmax), così non diventano prevedibili.

const P_ATTACK := 0.55       # quanto spesso, in media, chi è libero sceglie di attaccare
const HIT := 0.7             # valore di una candela tolta a un avversario
const KILL := 0.6            # in più se la toglie per ultima
const COUNTER := 0.7         # valore di un contrattacco riuscito
const TIRED := 0.35          # costo della stanchezza
const SPECIAL_KEEP := 0.5    # valore di tenersi l'abilità per dopo
const HEAL_GAIN := 0.8       # valore di una candela riaccesa, rispetto a una persa


## Pesi con cui j sceglierebbe chi attaccare: vendetta, chi è debole, chi è stanco.
static func target_weights(r: CerchioRules, j: int) -> Dictionary:
	var w := {}
	var maxc := 0.0
	for t in r.alive_ids():
		maxc = maxf(maxc, r.players[t].candles)
	var sum := 0.0
	for t in r.attack_targets(j):
		var x := 1.0
		if r.players[j].attacked_me_last.has(t):
			x += 1.5
		x += (maxc - r.players[t].candles) * 0.6
		if r.players[t].tired:
			x += 0.8
		w[t] = x
		sum += x
	for t in w:
		w[t] /= sum
	return w


## Probabilità che j attacchi i, vista da fuori.
static func p_attack(r: CerchioRules, j: int, i: int) -> float:
	if not r.players[j].alive or j == i:
		return 0.0
	var pa := 1.0 if r.must_attack(j) else P_ATTACK
	return pa * target_weights(r, j).get(i, 0.0)


## Probabilità che t si difenda proprio da me.
static func p_defend_from(r: CerchioRules, t: int, me: int) -> float:
	if r.must_attack(t) or r.known_pact(t, CerchioRules.Pact.OCCHI):
		return 0.0                         # senza occhi non può difendersi
	var threat := {}
	var sum := 0.0
	for j in r.alive_ids():
		if j == t:
			continue
		var x := p_attack(r, j, t) + 0.05
		if r.players[t].attacked_me_last.has(j):
			x += 0.3
		threat[j] = x
		sum += x
	return (1.0 - P_ATTACK) * threat.get(me, 0.0) / sum


## Cosa farà davvero j, se la strega l'ha visto: {"attacks_me": 0/1, "defends_me": 0/1}.
static func _known(r: CerchioRules, j: int, c: Dictionary, me: int) -> Dictionary:
	var att := 0.0
	var dfn := 0.0
	match c["move"]:
		CerchioRules.Move.ATTACK:
			att = 1.0 if c["target"] == me else 0.0
		CerchioRules.Move.DEFEND:
			dfn = 1.0 if c["target"] == me else 0.0
		CerchioRules.Move.SPECIAL:
			if c.has("targets"):
				att = 1.0 if c["targets"].has(me) else 0.0
			elif r.players[j].cls == CerchioRules.Cls.DOMATORE:
				att = 1.0
	return {"attacks_me": att, "defends_me": dfn}


## adaptive: l'avversario ADATTIVO (difficoltà selezionabile). Usa solo informazioni pubbliche dei giri
## conclusi: le mosse rivelate di ognuno (history), mai le scelte segrete del giro in corso. In più:
## - stima chi lo attaccherà, chi si difenderà da lui e chi riaccende anche dalle ultime 8 mosse libere di
##   ognuno (più mosse ha visto, più se ne fida);
## - punisce chi riaccende spesso;
## - non si fa leggere: più una mossa è stata frequente nelle sue ultime 4 libere, meno gli piace (senza
##   divieti rigidi, così non diventa una sequenza prevedibile);
## - sceglie in modo più deciso.
static func choose(r: CerchioRules, me: int, rng: RandomNumberGenerator, temp := 0.3, known := {}, adaptive := false) -> Dictionary:
	var P := r.players[me]
	var opts := r.legal_choices(me)
	var v_loss := 1.0 + (1.5 if P.candles <= 1.0 else (0.5 if P.candles <= 2.0 else 0.0))
	if r.fragile(me):
		v_loss *= 1.7                     # ogni colpo su di me vale doppio
	var v_back := v_loss * (1.7 if r.counter_amount(me) > 1.0 else 1.0)   # rischio del contrattacco
	var inc := {}
	var pdef := {}
	var opp_heal := 0.0
	for j in r.alive_ids():
		if j == me:
			continue
		if known.has(j):
			var k := _known(r, j, known[j], me)
			inc[j] = k["attacks_me"]
			pdef[j] = k["defends_me"]
		elif r.alive_ids().size() == 2:
			# duello: l'avversario si legge dalle sue ultime mosse libere
			var m := duel_model(r, j)
			inc[j] = m["a"]
			pdef[j] = m["d"]
			opp_heal = m["h"]
		else:
			inc[j] = p_attack(r, j, me)
			pdef[j] = p_defend_from(r, j, me)
	var oheal := {}
	if adaptive:
		for j in inc:
			if known.has(j) or r.must_attack(j):
				continue
			var mem := _memory(r, j, me)
			var w: float = mem["n"] / (mem["n"] + 3.0)
			inc[j] = lerpf(inc[j], mem["a"], w)
			pdef[j] = lerpf(pdef[j], mem["d"], w)
			if r.can_heal(j):
				oheal[j] = mem["h"]
		opp_heal = 0.0
		for j in oheal:
			opp_heal = maxf(opp_heal, oheal[j])
	var mine := _my_recent(r, me) if adaptive else {}
	var total_inc := 0.0
	var none_attacks := 1.0
	for j in inc:
		total_inc += inc[j]
		none_attacks *= 1.0 - inc[j]
	# adattivo, ordine visibile: se chi colpisce prima di me può uccidermi, il mio colpo rischia di non partire
	var dead_first := 0.0
	if adaptive and r.initiative != "nessuna" and not r.order_hidden:
		for j in inc:
			if r.rank(j) < r.rank(me) and r.hit_amount(j, me) >= P.candles:
				dead_first += inc[j] * (1.0 - dead_first)
	var strike := 1.0 - dead_first
	var idle_cost := TIRED if r.fatigue == "B" else 0.5 * v_loss
	var keep := SPECIAL_KEEP * (0.4 if P.candles <= 1.0 or r.alive_ids().size() <= 2 else 1.0)
	var scores: Array[float] = []
	for c in opts:
		var s := 0.0
		match c["move"]:
			CerchioRules.Move.ATTACK:
				var t: int = c["target"]
				s = (_attack_value(r, t, pdef, v_back, me) + oheal.get(t, 0.0) * 0.7) * strike - total_inc * v_loss
				# iniziativa: se agisco prima e gli resta una candela, lo elimino prima che mi colpisca
				if r.initiative != "nessuna" and not r.order_hidden and r.rank(me) < r.rank(t) and r.players[t].candles <= 1.0:
					s += inc[t] * v_loss * (1.0 - pdef[t])
			CerchioRules.Move.DEFEND:
				var x: int = c["target"]
				s = inc[x] * (0.9 if adaptive else COUNTER) - (total_inc - inc[x]) * v_loss - (1.0 - inc[x]) * idle_cost
			CerchioRules.Move.HEAL:
				# la candela torna solo se nessuno mi attacca
				var n_gain := 1.0
				if r.use_altar and r.altar_take_all:
					n_gain = maxf(1.0, minf(r.altar, r.heal_take_cap - P.candles))
				s = none_attacks * HEAL_GAIN * v_loss * n_gain - total_inc * v_loss
			CerchioRules.Move.SPECIAL:
				match P.cls:
					CerchioRules.Cls.CAVALIERE:
						s = total_inc * 0.3 - none_attacks * TIRED - keep
					CerchioRules.Cls.ELFO:
						for t in c["targets"]:
							s += _attack_value(r, t, pdef, v_loss) * strike
						s -= total_inc * v_loss + keep
					CerchioRules.Cls.DOMATORE:
						for t in pdef:
							if r.fire_counter:
								s += _attack_value(r, t, pdef, v_loss) * strike
							else:
								s += (1.0 - pdef[t]) * (HIT + (KILL if r.players[t].candles <= 1.0 else 0.0))
						s -= total_inc * v_loss + keep
		# nel duello, se non lo attacco l'avversario può riaccendersi una candela
		if c["move"] != CerchioRules.Move.ATTACK and not (c["move"] == CerchioRules.Move.SPECIAL and P.cls != CerchioRules.Cls.CAVALIERE):
			s -= opp_heal * HEAL_GAIN * HIT
		# foresta: nel giro della bestia chi si nasconde viene preso
		if r.place == 0 and r.place_strikes_now() and (c["move"] == CerchioRules.Move.DEFEND or c["move"] == CerchioRules.Move.HEAL):
			s -= v_loss
		# cimitero: nel giro del risveglio chi ha già spento di più evita di colpire ancora
		if r.place == 1 and r.place_strikes_now() and c["move"] == CerchioRules.Move.ATTACK and P.spent > 0.0:
			s -= 0.4 * v_loss
		if adaptive:
			var share: float = mine.get(c["move"], 0.0)
			s -= 0.3 * share * share              # una mossa ripetuta spesso mi rende leggibile
		scores.append(s)
	return opts[_softmax(scores, temp * (0.6 if adaptive else 1.0), rng)]


## Ultime 8 mosse libere (rivelate, giri conclusi) di j: quota di attacchi a me, difese da me, riaccensioni.
static func _memory(r: CerchioRules, j: int, me: int) -> Dictionary:
	var n := 0.0
	var a := 0.0
	var d := 0.0
	var h := 0.0
	var hist := r.players[j].history
	for i in range(hist.size() - 1, -1, -1):
		if n >= 8.0:
			break
		var c: Dictionary = hist[i]
		if c.get("forced", false):
			continue
		n += 1.0
		match c["move"]:
			CerchioRules.Move.ATTACK:
				if c.get("target", -1) == me:
					a += 1.0
			CerchioRules.Move.DEFEND:
				if c.get("target", -1) == me:
					d += 1.0
			CerchioRules.Move.HEAL:
				h += 1.0
			CerchioRules.Move.SPECIAL:
				if c.has("targets") and c["targets"].has(me):
					a += 1.0
	var k := maxf(n, 1.0)
	return {"n": n, "a": a / k, "d": d / k, "h": h / k}


## Quanto ho usato ogni tipo di mossa nelle mie ultime 4 mosse libere (0..1).
static func _my_recent(r: CerchioRules, me: int) -> Dictionary:
	var out := {}
	var n := 0
	var hist := r.players[me].history
	for i in range(hist.size() - 1, -1, -1):
		if n >= 4:
			break
		if hist[i].get("forced", false):
			continue
		n += 1
		out[hist[i]["move"]] = out.get(hist[i]["move"], 0.0) + 1.0
	for k in out:
		out[k] /= float(n)
	return out


## Duello: frequenze delle ultime mosse libere dell'avversario (con una base uguale per le mosse possibili).
static func duel_model(r: CerchioRules, j: int) -> Dictionary:
	if r.must_attack(j):
		return {"a": 1.0, "d": 0.0, "h": 0.0}
	var n := {"a": 1.0, "d": 1.0, "h": 1.0 if r.heal else 0.0}
	var seen := 0
	var hist := r.players[j].history
	for i in range(hist.size() - 1, -1, -1):
		if seen >= 6:
			break
		var c: Dictionary = hist[i]
		if c.get("forced", false):
			continue
		match c["move"]:
			CerchioRules.Move.ATTACK:
				n["a"] += 1.0
			CerchioRules.Move.DEFEND:
				n["d"] += 1.0
			CerchioRules.Move.HEAL:
				n["h"] += 1.0
			_:
				continue
		seen += 1
	var tot: float = n["a"] + n["d"] + n["h"]
	return {"a": n["a"] / tot, "d": n["d"] / tot, "h": n["h"] / tot}


static func _attack_value(r: CerchioRules, t: int, pdef: Dictionary, v_loss: float, me := -1) -> float:
	var pd: float = pdef.get(t, 0.0)
	var n := r.hit_amount(me, t) if me >= 0 else 1.0
	if r.players[t].shield > 0 and r.known_pact(t, CerchioRules.Pact.CUORE):
		return -pd * v_loss                # il Cuore di cenere lo protegge: il colpo va a vuoto
	var gain := HIT * minf(n, r.players[t].candles) + (KILL if r.players[t].candles <= n else 0.0)
	return (1.0 - pd) * gain - pd * v_loss


## Quali dei due patti mostrati prendere: {"picks": [...], "target": avversario per l'Ultima maledizione}.
## policy: "furbo" (valuta la situazione), "caso", "uno" (sempre il migliore), "mai", "due" (sempre tutti e due).
static func pact_choice(r: CerchioRules, me: int, rng: RandomNumberGenerator, policy := "furbo") -> Dictionary:
	var P := r.players[me]
	var shown: Array = r.offers.get(me, [])
	var others := r.attack_targets(me)
	if others.is_empty():
		return {"picks": [], "target": -1}
	var richest: int = others[0]
	for j in others:
		if r.players[j].candles > r.players[richest].candles:
			richest = j
	var out := {"picks": [], "target": richest}
	if shown.is_empty():
		return out
	var c := P.candles
	var low := c <= 2.0
	var val := {}
	for k in shown:
		var v := 0.0
		match k:
			CerchioRules.Pact.OCCHI:
				v = 0.55 * minf(2.0, r.heal_cap - c) - 0.3
			CerchioRules.Pact.MANO:
				v = 0.45 + (0.15 if c >= 2.0 else 0.0)
			CerchioRules.Pact.CUORE:
				v = 0.5 + (0.2 if low else 0.0)
			CerchioRules.Pact.SANGUE:
				var n := 0
				for j in others:
					if r.players[j].candles > 1.0:
						n += 1
				v = 0.3 * n - 0.4 + (0.15 if low else 0.0)
			CerchioRules.Pact.PELLE:
				v = 0.6 if low else 0.35
			CerchioRules.Pact.NOME:
				v = 1.2 if c <= 1.0 and r.players[richest].candles >= 3.0 else -2.0
		val[k] = v + rng.randf() * 0.3
	var best: int = shown[0] if val[shown[0]] >= val[shown[1]] else shown[1]
	var both_ok := c >= 2.0 and not shown.has(CerchioRules.Pact.NOME)
	match policy:
		"mai":
			return out
		"uno":
			out["picks"] = [best]
			return out
		"due":
			out["picks"] = shown.duplicate() if both_ok else [best]
			return out
		"caso":
			var x := rng.randf()
			if x < 0.33:
				return out
			if x < 0.66 or not both_ok:
				out["picks"] = [shown[rng.randi() % 2]]
			else:
				out["picks"] = shown.duplicate()
			return out
	# furbo: niente, il migliore, o tutti e due pagando metà delle candele
	var one: float = val[best]
	var two: float = val[shown[0]] + val[shown[1]] - (c - floorf(c / 2.0)) * 0.5 if both_ok else -9.0
	if two > one and two > 0.35:
		out["picks"] = shown.duplicate()
	elif one > 0.35:
		out["picks"] = [best]
	return out


## La strega decide se usare l'Occhio e su chi: sul più minaccioso, se la minaccia è seria.
static func witch_peek(r: CerchioRules, me: int, rng: RandomNumberGenerator) -> int:
	var P := r.players[me]
	if P.cls != CerchioRules.Cls.STREGA or not P.special_left:
		return -1
	var best := -1
	var best_p := 0.0
	for j in r.alive_ids():
		if j == me:
			continue
		var pj := p_attack(r, j, me)
		if pj > best_p:
			best_p = pj
			best = j
	if P.candles <= 1.0 or (best_p >= 0.35 and rng.randf() < 0.6):
		return best
	return -1


static func _softmax(scores: Array[float], temp: float, rng: RandomNumberGenerator) -> int:
	var m: float = scores.max()
	var ws: Array[float] = []
	var sum := 0.0
	for s in scores:
		var w := exp((s - m) / temp)
		ws.append(w)
		sum += w
	var x := rng.randf() * sum
	for i in ws.size():
		x -= ws[i]
		if x <= 0.0:
			return i
	return ws.size() - 1


## Scommessa dello spettro: punta sul vivo più esposto (meno candele, poi chi è stanco).
static func ghost_pick(r: CerchioRules, rng: RandomNumberGenerator) -> int:
	var best := -1
	var best_v := 1e9
	for pid in r.alive_ids():
		var v := r.players[pid].candles - (0.5 if r.players[pid].tired else 0.0) + rng.randf() * 0.3
		if v < best_v:
			best_v = v
			best = pid
	return best


## Carta del Custode da giocare insieme alla mossa c (o nessuna). Regole semplici, con un po' di caso:
## le carte forti si tengono per il momento giusto, alla fine della manche si spende tutto.
static func pick_card(r: CerchioRules, me: int, c: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	if not r.can_play_card(me):
		return c
	var P := r.players[me]
	var others: Array[int] = r.attack_targets(me)
	if others.is_empty():
		return c
	var inc := 0.0
	for j in others:
		inc += p_attack(r, j, me)
	var low := P.candles <= 2.0
	var duel := others.size() == 1
	# a parità si sceglie a caso (prima vinceva sempre il primo della lista, cioè il posto del giocatore umano)
	var pool: Array = others.duplicate()
	for i in range(pool.size() - 1, 0, -1):
		var q := rng.randi() % (i + 1)
		var tmp = pool[i]
		pool[i] = pool[q]
		pool[q] = tmp
	var richest: int = pool[0]
	var weakest: int = pool[0]
	var most_cards: int = pool[0]
	for j in pool:
		if r.players[j].candles > r.players[richest].candles:
			richest = j
		if r.players[j].candles < r.players[weakest].candles:
			weakest = j
		if r.players[j].hand.size() > r.players[most_cards].hand.size():
			most_cards = j
	var best := {}
	var best_v := 0.0
	for k in P.hand:
		var v := 0.0
		var t := -1
		match k:
			CerchioRules.Card.SPECCHIO:
				v = inc * (1.6 if low else 0.9)
			CerchioRules.Card.OMBRA:
				v = inc * (1.4 if low else 0.6) + (0.3 if c["move"] == CerchioRules.Move.HEAL else 0.0)
			CerchioRules.Card.RESPIRO:
				v = inc * 2.0 if P.candles <= 1.0 else 0.0
			CerchioRules.Card.LAMA:
				if c["move"] == CerchioRules.Move.ATTACK:
					v = 0.8 if r.players[c["target"]].candles <= 2.0 else 0.4
				elif c["move"] == CerchioRules.Move.SPECIAL and P.cls != CerchioRules.Cls.CAVALIERE:
					v = 1.2
			CerchioRules.Card.SETE:
				if c["move"] == CerchioRules.Move.ATTACK or (c["move"] == CerchioRules.Move.SPECIAL and P.cls != CerchioRules.Cls.CAVALIERE):
					v = 0.7 if low else 0.25
			CerchioRules.Card.CATENA:
				if c["move"] == CerchioRules.Move.DEFEND:
					t = c["target"]
					v = 1.0
			CerchioRules.Card.PATTO:
				t = richest
				v = (r.players[richest].candles - P.candles) * 0.45
			CerchioRules.Card.FIAMMA:
				t = weakest
				v = 1.2 if r.players[weakest].candles <= 1.0 else (0.6 if low else 0.3)
			CerchioRules.Card.FURTO:
				t = most_cards
				v = 0.15 * r.players[most_cards].hand.size()
			CerchioRules.Card.MALEDIZIONE:
				t = most_cards
				v = 0.18 * r.players[most_cards].hand.size()
		if duel:
			v += 0.4          # nel duello finale si spende tutto
		v += rng.randf() * 0.3
		if v > best_v:
			best_v = v
			best = {"card": k, "card_target": t}
	if best.is_empty() or best_v < 0.75:
		return c
	var out := c.duplicate()
	out["card"] = best["card"]
	if best["card_target"] >= 0:
		out["card_target"] = best["card_target"]
	return out
