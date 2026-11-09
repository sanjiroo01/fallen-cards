extends SceneTree
## Simulatore delle "Catene dell'altare" (docs/catene_altare.md): N manche con quattro avversari del computer che
## sospettano, mentono e passano il testimone. Misura durata, liberazioni, roghi, scoperta del sabotatore e punti;
## poi confronta alcune strategie fisse di un giocatore contro tre avversari normali.
## Senza argomenti usa le regole decise il 21/10/2026 (bot che "parlano" e chiedono il Guardiano dopo aver visto i voti).
## Uso: godot --headless --path . -s res://tests/sim_catene.gd -- [N] [candele=12] [catene=5] [penalita=2]
##      [maggioranza=3] [mazzo=base|piu_voti|meno_voti|piu_testimoni] [fermo=1|0] [respiro=1|0] [strategie=1|0]
##      [togli=30 aggiungi=28 aggiungi2=7 salta=12 voto=11 testimone=12: pesi del mazzo] [limite_respiro=3]

var N := 2000
var opts := {"candele": 12, "catene": 4, "penalita": 2, "maggioranza": 3, "mazzo": "base", "fermo": 1, "respiro": 1, "strategie": 1,
	"togli": -1, "aggiungi": -1, "aggiungi2": -1, "salta": -1, "voto": -1, "testimone": -1, "limite_respiro": 3, "tira_o_carta": 0, "fermo_scarto": 0, "punti_sab": 3, "guardiano": 3, "parlano": 1, "primo": 3, "premio": 0, "accelera": 0, "ultima_da_soli": 0, "passaggio_caso": 1, "mazzo_sab": "deciso", "sab_primo": 1, "punti_fuga": 0, "sab_solo_zero": 1, "segreta": 1, "fermo_max": 2, "modalita": "normale", "mescola": 1, "voto_morti": 0, "votano_legati": 1, "respiro_salta": 1, "ricarica": 3, "brucia_con_segreta": 1, "scambia_mani": 1, "sab_doppio": 0, "giocatori": 4, "sabotatori": -1, "bruciano": -1, "fermo_scarto_n": -1}
var st := {}
var given := {}               # opzioni scritte a mano: valgono anche sopra le regole per N giocatori

const SEC_TURNO := 25.0      # scelta (20 s al massimo) + rivelazione: stima per la durata


func _init() -> void:
	for a in OS.get_cmdline_user_args():
		if a.is_valid_int():
			N = int(a)
		elif "=" in a:
			var k := a.get_slice("=", 0)
			var v := a.get_slice("=", 1)
			opts[k] = int(v) if v.is_valid_int() else v
			given[k] = true
	print("CATENE DELL'ALTARE — %d manche per prova. %s" % [N, opts])
	st = {}
	_run_many(_styles("furbo"))
	_report()
	if opts["strategie"] == 1:
		print("\nStrategie fisse di UN giocatore contro tre avversari normali (punti medi a manche; riferimento: normale):")
		for s in ["furbo", "ingenuo", "sempre_tira", "mai_tira", "accumula", "aggressivo"]:
			st = {}
			_run_many(_styles(s))
			var m := float(N)
			print("  %-12s %.2f punti   (da sabotatore %.2f, da innocente %.2f; brucia %.0f%%)" % [s, st.get("p0", 0) / m,
				st.get("p0_sab", 0) / maxf(st.get("n0_sab", 0), 1), st.get("p0_inn", 0) / maxf(st.get("n0_inn", 0), 1),
				100 * st.get("b0", 0) / m])
	quit()


func _add(k: String, v := 1.0) -> void:
	st[k] = st.get(k, 0.0) + v


func _rules(seed_value: int) -> CateneRules:
	var r := CateneRules.new()
	r.for_players(opts["giocatori"])
	if given.has("candele") or r.n < 6:
		r.start_candles = opts["candele"]
	r.start_chains = opts["catene"]
	r.unmask_penalty = opts["penalita"]
	r.majority = opts["maggioranza"]
	r.hold_rule = opts["fermo"] == 1
	r.final_burst = opts["respiro"] == 1
	var C := CateneRules.Card
	match opts["mazzo"]:
		"piu_voti":
			r.deck = {C.TOGLI: 28, C.AGGIUNGI: 26, C.AGGIUNGI2: 7, C.SALTA: 11, C.VOTO: 16, C.TESTIMONE: 12}
		"meno_voti":
			r.deck = {C.TOGLI: 31, C.AGGIUNGI: 29, C.AGGIUNGI2: 7, C.SALTA: 13, C.VOTO: 7, C.TESTIMONE: 13}
		"piu_testimoni":
			r.deck = {C.TOGLI: 28, C.AGGIUNGI: 26, C.AGGIUNGI2: 7, C.SALTA: 11, C.VOTO: 11, C.TESTIMONE: 17}
	# pesi singoli del mazzo (sovrascrivono il preset)
	for kv in [["togli", C.TOGLI], ["aggiungi", C.AGGIUNGI], ["aggiungi2", C.AGGIUNGI2], ["salta", C.SALTA], ["voto", C.VOTO], ["testimone", C.TESTIMONE]]:
		if int(opts[kv[0]]) >= 0:
			r.deck[kv[1]] = int(opts[kv[0]])
	r.burst_limit = opts["limite_respiro"]
	r.pull_or_card = opts["tira_o_carta"] == 1
	if given.has("sab_doppio") or r.n < 6:
		r.sab_double = opts["sab_doppio"] == 1
	if given.has("fermo_scarto") or r.n < 6:
		r.hold_slack = opts["fermo_scarto"]
	if given.has("punti_sab") or r.n < 5:
		r.sab_win_points = opts["punti_sab"]
	r.guardian = opts["guardiano"] >= 1
	r.guardian_by_vote = opts["guardiano"] >= 2
	r.guardian_after = opts["guardiano"] == 3
	r.first_free_points = opts["primo"]
	r.unmask_reward = opts["premio"]
	r.unmask_speed = opts["accelera"] == 1
	r.last_chain_self = opts["ultima_da_soli"] == 1
	r.random_pass = opts["passaggio_caso"] == 1
	r.sab_can_free_first = opts["sab_primo"] == 1
	r.sab_escape_points = opts["punti_fuga"]
	r.sab_alone_zero = opts["sab_solo_zero"] == 1
	r.sab_secret = opts["segreta"]
	r.hold_max_streak = opts["fermo_max"]
	r.wrong_vote_kills = opts["modalita"] == "elimina"
	r.shuffle_cards = opts["mescola"] == 1
	r.dead_vote = opts["voto_morti"] == 1
	r.voters_chained = opts["votano_legati"] == 1
	r.burst_salta = opts["respiro_salta"] == 1
	r.secret_every = opts["ricarica"]
	r.secret_burns_card = opts["brucia_con_segreta"] == 1
	r.swap_hands = opts["scambia_mani"] == 1
	match opts["mazzo_sab"]:
		"solo":
			r.sab_deck = {C.AGGIUNGI: 40, C.AGGIUNGI2: 15, C.SALTA: 25, C.TESTIMONE: 20}
		"uguale":
			r.sab_deck = {}
		"leggero":
			r.sab_deck = {C.AGGIUNGI: 35, C.SALTA: 35, C.TESTIMONE: 30}
		"leggero2":
			r.sab_deck = {C.AGGIUNGI: 30, C.AGGIUNGI2: 5, C.SALTA: 35, C.TESTIMONE: 30}
		"misto":
			r.sab_deck = {C.TOGLI: 20, C.AGGIUNGI: 30, C.AGGIUNGI2: 12, C.SALTA: 18, C.TESTIMONE: 15, C.VOTO: 5}
	if opts["sabotatori"] >= 0:
		r.n_sabs = opts["sabotatori"]
	if opts["bruciano"] >= 0:
		r.burn_top = opts["bruciano"]
	if opts["fermo_scarto_n"] >= 0:
		r.hold_slack = opts["fermo_scarto_n"]
	r.setup(seed_value)
	return r


func _run_many(styles: Array) -> void:
	for g in N:
		_one(g * 7919 + 13, styles)


func _styles(first: String) -> Array:
	var out := [first]
	for i in range(1, int(opts["giocatori"])):
		out.append("furbo")
	return out


func _one(seed_value: int, styles: Array) -> void:
	var r := _rules(seed_value)
	var bots: Array[CateneBot] = []
	for i in r.n:
		bots.append(CateneBot.new(i, styles[i], seed_value * 31 + i))
	r.guardian_ask_fn = func(v: int, tally: Dictionary) -> bool: return bots[v].asks_guardian_after(r, tally)
	var sab_start := r.sabs()
	var guard := 0
	while not r.over and guard < 100:
		guard += 1
		for b in bots:
			b.before_turn(r)
		var drawn := r.chained().size()
		r.begin_turn()
		var choices := {}
		for pid in r.chained():
			choices[pid] = bots[pid].choose(r)
		r.resolve(choices, func(v: int) -> Variant: return _vote(r, bots, v))
		for b in bots:
			b.observe(r, drawn)
		if r.is_last_breath():
			_add("respiro")
			r.run_final_burst(func(pid: int) -> Dictionary: return bots[pid].burst(r))
	r.guardian_ask_fn = Callable()     # rompe il giro lambda -> regole -> lambda
	# statistiche
	_add("manche")
	_add("turni", r.turn)
	_add("bruciati", r.burned.size())
	var libs := 0
	for p in r.players:
		if p.free:
			libs += 1
	_add("liberati", libs)
	if r.first_free_turn > 0:
		_add("prima_lib", r.first_free_turn)
		_add("n_prima_lib")
	if r.chained().size() <= 1 and r.candles > 1:
		_add("fine_un_legato")
	if r.burned.size() >= 2:
		_add("roghi_multipli")
	if r.unmasked:
		_add("scoperto")
		_add("turno_scoperta", r.unmask_turn)
	_add("passaggi", r.passes)
	_add("voti", r.votes_played)
	_add("voti_giusti", r.votes_right)
	if r.guardian_used:
		_add("guardiano")
		if not r.guardian_lied:
			_add("guardiano_vero")
	_add("fermo", r.hold_count)
	if r.sabs() != sab_start:
		_add("ruolo_cambiato")
	_add("eliminati", r.eliminated.size())
	if not r.escaped.is_empty():
		_add("sab_fuga")
	# punti: ogni sabotatore di fine manche, e la media degli innocenti
	var sabs := r.sabs()
	for sab in sabs:
		_add("p_sab", r.score(sab) / float(sabs.size()))
		if sab in r.burned:
			_add("sab_brucia", 1.0 / sabs.size())
		if r.score(sab) == r.sab_win_points:
			_add("sab_3", 1.0 / sabs.size())
	var inn := 0.0
	for pid in r.n:
		if not r.is_sab(pid):
			inn += r.score(pid)
	_add("p_inn", inn / float(r.n - sabs.size()))
	# giocatore 0 (per le strategie)
	var p0 := r.score(0)
	_add("p0", p0)
	if 0 in r.burned:
		_add("b0")
	if r.is_sab(0):
		_add("p0_sab", p0)
		_add("n0_sab")
	else:
		_add("p0_inn", p0)
		_add("n0_inn")


## Voto di un bot. Con parlano=1 si imita un tavolo che parla: gli innocenti si mettono d'accordo sul più sospettato
## secondo tutti (sospetto medio del tavolo); il sabotatore si accoda se non è lui né il complice, altrimenti incastra
## un altro. Chi conosce il sabotatore (ha appena passato il testimone) lo dice, ma non sempre gli altri gli credono.
func _vote(r: CateneRules, bots: Array[CateneBot], v: int) -> Variant:
	var who := _pick(r, bots, v)
	if r.guardian_by_vote:
		return {"v": who, "g": bots[v].wants_guardian(r)}
	return who


func _pick(r: CateneRules, bots: Array[CateneBot], v: int) -> int:
	var hidden := r.sabs().filter(func(q: int) -> bool: return not r.players[q].unmasked)
	if opts["parlano"] != 1 or hidden.is_empty():
		return bots[v].vote(r)
	var avg := []
	avg.resize(r.n)
	avg.fill(0.0)
	for b in bots:
		if b.sus.size() == r.n:   # tutti parlano, anche i sabotatori (che fingono): nessuno sa chi è innocente
			for q in r.n:
				avg[q] += b.sus[q]
	var order := range(r.n)
	order.sort_custom(func(a: int, b: int) -> bool: return avg[a] > avg[b])
	var pick := -1
	for q in order:
		if q != v and (not r.voters_chained or q in r.chained()) and not (r.is_sab(q) and r.players[q].unmasked):
			pick = q
			break
	if pick < 0:
		return bots[v].vote(r)
	if r.is_sab(v) and r.is_sab(pick):
		return bots[v].vote(r)
	if not r.is_sab(v) and bots[v].known >= 0 and bots[v].known != v:
		return bots[v].known
	return pick


func _report() -> void:
	var m: float = st["manche"]
	var turni: float = st["turni"] / m
	print("Durata: %.1f turni a manche (~%.1f minuti a manche, ~%.0f a partita di 3 manche)" % [
		turni, (turni * SEC_TURNO + 30.0 * st.get("respiro", 0) / m) / 60.0, 3 * (turni * SEC_TURNO + 30.0 * st.get("respiro", 0) / m) / 60.0])
	print("Fine manche: %.0f%% un solo legato rimasto, %.0f%% ultimo respiro; altare tenuto fermo %.1f turni a manche" % [
		100 * st.get("fine_un_legato", 0) / m, 100 * st.get("respiro", 0) / m, st.get("fermo", 0) / m])
	print("Liberati %.2f a manche; prima liberazione al turno %.1f (in %.0f%% delle manche)" % [
		st["liberati"] / m, st.get("prima_lib", 0) / maxf(st.get("n_prima_lib", 0), 1), 100 * st.get("n_prima_lib", 0) / m])
	print("Bruciati %.2f a manche; roghi con 2+ campioni %.0f%%" % [st["bruciati"] / m, 100 * st.get("roghi_multipli", 0) / m])
	print("Sabotatore: scoperto %.0f%% (in media al turno %.1f); testimone passato %.2f volte a manche (ruolo cambiato nel %.0f%%)" % [
		100 * st.get("scoperto", 0) / m, st.get("turno_scoperta", 0) / maxf(st.get("scoperto", 0), 1), st.get("passaggi", 0) / m,
		100 * st.get("ruolo_cambiato", 0) / m])
	print("Sabotatore scappato per primo (ruolo passato da solo): %.0f%%; innocenti eliminati dal voto %.2f a manche" % [100 * st.get("sab_fuga", 0) / m, st.get("eliminati", 0) / m])
	print("Voti: %.2f a manche, indovinati %.0f%%" % [st.get("voti", 0) / m, 100 * st.get("voti_giusti", 0) / maxf(st.get("voti", 0), 1)])
	if opts["guardiano"] >= 1:
		print("Guardiano chiamato nel %.0f%% delle manche (ha detto il vero nel %.0f%% delle chiamate)" % [
			100 * st.get("guardiano", 0) / m, 100 * st.get("guardiano_vero", 0) / maxf(st.get("guardiano", 0), 1)])
	print("Punti medi a manche: sabotatore %.2f (punti pieni nel %.0f%%, brucia nel %.0f%%), innocente %.2f" % [
		st["p_sab"] / m, 100 * st.get("sab_3", 0) / m, 100 * st.get("sab_brucia", 0) / m, st["p_inn"] / m])
