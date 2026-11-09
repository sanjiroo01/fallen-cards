class_name CateneRules
extends RefCounted
## Regole delle "Catene dell'altare" (docs/catene_altare.md), senza grafica: una manche alla volta.
## Le usa il simulatore (tests/sim_catene.gd) e più avanti il gioco. Le scelte arrivano da fuori (bot o giocatore).
##
## Un turno: begin_turn() (pesca) -> scelte segrete {pull, card, target, burn} -> resolve(choices, vote_fn)
## -> se is_last_breath(): final_burst(play_fn) -> finish(). Gli eventi pubblici del turno sono in `events`.

enum Card { TOGLI, AGGIUNGI, AGGIUNGI2, SALTA, VOTO, TESTIMONE }
const SECRET := -2                # indice "carta" per il Togli nascosto del sabotatore
const NOMI := ["Togli una catena", "Aggiungi una catena", "Aggiungi due catene", "Salta un turno", "Voto", "Passa il testimone"]

# ------------------------------------------------------------------ numeri: valori decisi il 21/10/2026 (docs/catene_altare.md)
var start_chains := 4
var max_chains := 9
var start_candles := 12
var hand_max := 3
var unmask_penalty := 2         # catene in più al sabotatore scoperto
var majority := 3               # voti necessari su 4
var deck := {Card.TOGLI: 50, Card.AGGIUNGI: 8, Card.AGGIUNGI2: 3, Card.SALTA: 12, Card.VOTO: 16, Card.TESTIMONE: 12}
var hold_rule := true           # se tutti i legati tirano, la candela non si spegne
var final_burst := true         # ultimo respiro: all'ultima candela si giocano subito tutte le carte
var burst_limit := 3            # carte che ognuno può giocare nell'ultimo respiro
var pull_or_card := false       # ogni turno O tiri O giochi una carta (chi gioca non tira: indizio per tutti)
var sab_double := false         # le carte del sabotatore (Aggiungi, Salta) colpiscono due bersagli: target e target2
var sab_win_points := 3         # sabotatore mai scoperto che si salva
var hold_slack := 0             # l'altare resta fermo se non tirano al massimo questi legati (0 = devono tirare tutti)
var guardian := true            # "Includi il Guardiano": una volta per manche aggiunge un voto, 50% vero e 50% falso
var guardian_by_vote := true    # il Guardiano entra solo se almeno 2 votanti lo chiedono (altrimenti quando manca un voto)
var guardian_after := false     # con guardian_by_vote: si chiede solo dopo aver visto i voti, se ne manca uno
var guardian_ask_fn := Callable()   # (votante, conteggio) -> chiede il Guardiano?
var unmask_speed := false      # la scoperta del sabotatore fa spegnere una candela in più a turno
var unmask_reward := 0          # catene tolte subito a ogni innocente legato che ha votato giusto
var first_free_points := 3      # punti del primo che si libera (gli altri liberi ne prendono 2)
var random_pass := true         # il testimone passa a un legato a caso: chi lo passa non sa a chi
var sab_deck := {Card.AGGIUNGI: 35, Card.SALTA: 35, Card.TESTIMONE: 30} # mazzo del sabotatore (vuoto = lo stesso degli altri): carte per sabotare
var sab_can_free_first := true  # il sabotatore può liberarsi per primo: il ruolo passa da solo e lui è penalizzato
var sab_escape_points := 0      # punti del sabotatore che è scappato per primo
var escaped: Array[int] = []    # sabotatori scappati per primi (il ruolo è passato a un altro)
var sab_alone_zero := true      # il sabotatore che brucia da solo prende 0 (1 solo se brucia insieme a un innocente)
var last_chain_self := false   # l'ultima catena se la toglie solo il diretto interessato ("Togli" altrui non ha effetto)
var sab_secret := 1             # "Togli" nascosti dati al sabotatore a inizio manche (passano con il ruolo)
var hold_max_streak := 2        # turni di fila in cui l'altare può restare fermo (0 = senza limite)
var shuffle_cards := true       # le carte del turno escono mescolate, non nell'ordine dei posti
var dead_vote := false          # gli eliminati (seconda modalità) continuano a votare, come chi è libero
var voters_chained := true      # votano solo i legati; serve la maggioranza dei votanti (4 -> 3, 3 -> 2, 2 -> 2)
var burst_salta := true         # nell'ultimo respiro si può giocare anche "Salta": il bersaglio non gioca più carte
var secret_every := 3           # ogni quanti turni il sabotatore senza carta nascosta ne riceve una nuova (0 = mai)
var secret_burns_card := true   # usando la carta nascosta brucia anche una sua carta: il conteggio cala come sempre
var swap_hands := true          # al passaggio del testimone le carte in mano si scambiano fra vecchio e nuovo sabotatore
var defer_votes := false        # il gioco: i voti chiamati nel turno si fanno dopo le carte, con run_vote()
var pending_votes := 0
var last_tally := {}            # voti dell'ultima votazione (votato -> quanti), Guardiano compreso
var last_votes := {}            # chi ha votato chi nell'ultima votazione (votante -> votato): il voto è pubblico
var wrong_vote_kills := false# seconda modalità: chi viene votato a maggioranza e non è il sabotatore è eliminato
# quanti si gioca (22/10/2026, richiesta dell'utente: da 4 a 8). Fino a 5 valgono le regole definitive; da 6 in su il
# piano "dei due sabotatori" (vedi for_players e docs/catene_altare.md in fondo)
var n := 4                      # campioni al tavolo
var n_sabs := 1                 # sabotatori: si conoscono fra loro
var burn_top := 1               # alla fine bruciano i `burn_top` più legati (a pari merito anche chi è pari all'ultimo)


class Player:
	var chains := 5
	var hand: Array[int] = []
	var free := false
	var skip := false            # salta la mossa di questo turno (colpito da "Salta un turno" il turno prima)
	var skip_next := false
	var nopull := 0              # turni in cui poteva tirare e non l'ha fatto (pubblico)
	var dead := false            # eliminato da un voto sbagliato (seconda modalità)
	var secret := 0              # "Togli" nascosti del sabotatore (dono del Guardiano, fuori dal conteggio delle carte)
	var sab := false             # è un sabotatore (segreto)
	var unmasked := false        # sabotatore scoperto dal voto


var players: Array[Player] = []
var unmasked := false           # almeno un sabotatore è stato scoperto
var candles := 12
var turn := 0
var first := 0                  # chi apre l'ordine dei colpi (ruota fra i legati)
var anyone_free := false
var over := false
var burned: Array[int] = []
var rng := RandomNumberGenerator.new()
var passes := 0                 # cambi di testimone (segreti)
var events: Array = []          # eventi pubblici dell'ultimo turno
var cleared := {}               # pid -> turno: un voto sbagliato ha mostrato che in quel momento non era lui
var hold_count := 0             # turni in cui l'altare è rimasto fermo
var first_free_turn := -1
var unmask_turn := -1
var votes_played := 0
var votes_right := 0
var guardian_used := false
var first_freed := -1
var guardian_lied := false
var eliminated: Array[int] = []
var _hold_streak := 0
var _deck_total := 0


## Regole per `count` campioni (4-8). Fino a 5: le regole definitive del 21/10, un sabotatore. Da 6 in su il piano
## "dei due sabotatori": due sabotatori che si conoscono, e alla fine bruciano i due più legati. I numeri vengono dal
## simulatore (tests/sim_catene.gd giocatori=N, prove del 22/10 in docs/catene_altare.md).
func for_players(count: int) -> CateneRules:
	n = clampi(count, 4, 8)
	if n >= 5:
		sab_win_points = 2              # da 5 in su il sabotatore nascosto si salva più spesso: 3 punti erano troppi
	if n >= 6:
		n_sabs = 2
		burn_top = 2
		sab_double = false              # in due bastano: col doppio colpo il tavolo non si libera quasi mai
		start_candles = 14
		hold_slack = 1                  # l'altare resta fermo se non tira al massimo uno dei legati
	return self


func setup(seed_value: int, first_seat := -1) -> void:
	rng.seed = seed_value
	players.clear()
	for i in n:
		var p := Player.new()
		p.chains = start_chains
		players.append(p)
	var pool := range(n)
	_shuffle(pool)
	for k in mini(n_sabs, n - 1):
		players[pool[k]].sab = true
		players[pool[k]].secret = sab_secret
	candles = start_candles
	first = first_seat if first_seat >= 0 else rng.randi() % n
	_deck_total = 0
	for k in deck:
		_deck_total += deck[k]


## I sabotatori di adesso (ruolo passato compreso), in ordine di posto.
func sabs() -> Array[int]:
	var out: Array[int] = []
	for i in n:
		if players[i].sab:
			out.append(i)
	return out


func is_sab(pid: int) -> bool:
	return pid >= 0 and pid < n and players[pid].sab


## Sabotatore non ancora scoperto.
func hidden_sab(pid: int) -> bool:
	return is_sab(pid) and not players[pid].unmasked


## Il primo sabotatore (con le regole fino a 5 campioni è l'unico).
var saboteur: int:
	get:
		var s := sabs()
		return s[0] if not s.is_empty() else -1


func chained() -> Array[int]:
	var out: Array[int] = []
	for i in n:
		if not players[i].free and not players[i].dead:
			out.append(i)
	return out


## Carte in gioco in totale (l'unico numero di carte che tutti vedono).
func cards_total() -> int:
	var n := 0
	for p in players:
		n += p.hand.size()
	return n


## Candele che si spengono a fine turno se l'altare non resta fermo.
func burn_rate() -> int:
	return 1 + int(anyone_free) + int(unmasked and unmask_speed)


func _draw(pid := -1) -> int:
	var d: Dictionary = sab_deck if is_sab(pid) and not sab_deck.is_empty() else deck
	var total := 0
	for k in d:
		total += d[k]
	var x := rng.randi() % total
	for k in d:
		x -= d[k]
		if x < 0:
			return k
	return Card.TOGLI


## Ordine dei colpi del turno: dai legati, a partire da `first`.
func order() -> Array[int]:
	var out: Array[int] = []
	for k in n:
		var pid := (first + k) % n
		if not players[pid].free and not players[pid].dead:
			out.append(pid)
	return out


## Inizio turno: ogni legato pesca 1 carta (scelta alla cieca fra 3 coperte = una carta a caso).
func begin_turn() -> void:
	turn += 1
	events = []
	for pid in chained():
		var p := players[pid]
		p.skip = p.skip_next
		p.skip_next = false
		p.hand.append(_draw(pid))
	# il Guardiano ricarica la carta nascosta del sabotatore ogni `secret_every` turni (se l'ha già usata)
	if secret_every > 0 and turn % secret_every == 0:
		for s in sabs():
			if players[s].secret == 0:
				players[s].secret = 1


## choices: pid -> {pull: bool, card: indice in mano o -1, target: pid, burn: indice da bruciare se la mano supera il massimo}
## vote_fn(pid) -> pid votato (tutti e 4 votano, anche i liberi).
func resolve(choices: Dictionary, vote_fn: Callable) -> void:
	var ord := order()
	var pulled: Array[int] = []
	var plays: Array = []           # [chi, carta, bersaglio]: le carte giocate coperte in questo turno
	for pid in ord:
		var p := players[pid]
		var c: Dictionary = choices.get(pid, {})
		if p.skip:
			events.append({"t": "saltato", "pid": pid})
			_burn_extra(pid, c)
			continue
		var ci: int = c.get("card", -1)
		if c.get("pull", false) and not (pull_or_card and ci >= 0):
			pulled.append(pid)
		else:
			p.nopull += 1
		if ci >= 0 and ci < p.hand.size():
			plays.append([pid, p.hand[ci], c.get("target", pid), c.get("target2", -1), false])
			p.hand.remove_at(ci)
		elif ci == SECRET and p.secret > 0:
			_use_secret(p)
			plays.append([pid, Card.TOGLI, c.get("target", pid), -1, true])
		_burn_extra(pid, c)
	events.append({"t": "tirano", "pids": pulled, "chi": ord})
	# le carte si mescolano ed escono in ordine casuale; chi arriva a zero catene si libera subito
	if shuffle_cards:
		_shuffle(plays)
	# il dono del Guardiano resta nel fuoco e si gioca per ultimo
	plays.sort_custom(func(x: Array, y: Array) -> bool: return not x[4] and y[4])
	for pl in plays:
		var n0 := events.size()
		_play(pl[0], pl[1], pl[2], vote_fn)
		_mark(n0, "segreta", pl[4])
		if _doubles(pl[0], pl[1], pl[2], pl[3]):
			n0 = events.size()
			_play(pl[0], pl[1], pl[3], vote_fn)
			_mark(n0, "bis", true)
		_check_free()
	# l'altare
	var streak_ok := hold_max_streak <= 0 or _hold_streak < hold_max_streak
	if hold_rule and pulled.size() >= ord.size() - hold_slack and pulled.size() >= 2 and streak_ok:
		hold_count += 1
		_hold_streak += 1
		events.append({"t": "altare_fermo"})
	else:
		_hold_streak = 0
		candles = maxi(candles - burn_rate(), 1)   # l'ultimo respiro arriva sempre con l'ultima candela accesa
	_rotate_first()
	var left := chained()
	if left.size() <= 1:
		finish()


## Segna gli eventi aggiunti da `from` in poi (per l'animazione: carta segreta, secondo colpo della stessa carta).
func _mark(from: int, key: String, v: bool) -> void:
	for i in range(from, events.size()):
		events[i][key] = v


## La carta colpisce anche un secondo bersaglio? (sab_double: solo le carte da sabotaggio giocate dal sabotatore)
func _doubles(pid: int, card: int, target: int, target2: int) -> bool:
	return sab_double and is_sab(pid) and card in [Card.AGGIUNGI, Card.AGGIUNGI2, Card.SALTA] \
		and target2 >= 0 and target2 < n and target2 != target


func _check_free() -> void:
	for pid in chained():
		var p := players[pid]
		if p.chains <= 0:
			p.free = true
			p.hand.clear()
			events.append({"t": "libero", "pid": pid})
			if not anyone_free:
				first_free_turn = turn
			_on_free(pid)


func _shuffle(a: Array) -> void:
	for i in range(a.size() - 1, 0, -1):
		var j := rng.randi() % (i + 1)
		var tmp = a[i]
		a[i] = a[j]
		a[j] = tmp


## Applica una carta; true se il suo effetto si vede (le carte senza effetto visibile: testimone, inutili).
func _play(pid: int, card: int, target: int, vote_fn: Callable) -> bool:
	var t: Player = null
	if target >= 0 and target < n:
		t = players[target]
	match card:
		Card.TOGLI:
			if t == null or t.free:
				return false
			if last_chain_self and target != pid and t.chains <= 1:
				return false                         # l'ultima catena se la toglie solo lui: vale per tutti
			if is_sab(target) and not anyone_free and t.chains <= 1 and not sab_can_free_first:
				# il sabotatore non può liberarsi per primo: l'anello resta (indizio involontario)
				events.append({"t": "togli_nulla", "pid": target})
				return true
			t.chains = maxi(t.chains - 1, 0)
			events.append({"t": "togli", "pid": target})
			return true
		Card.AGGIUNGI, Card.AGGIUNGI2:
			if t == null or t.free:
				return false
			var n := 1 if card == Card.AGGIUNGI else 2
			t.chains = mini(t.chains + n, max_chains)
			events.append({"t": "aggiungi", "pid": target, "n": n})
			return true
		Card.SALTA:
			if t == null or t.free:
				return false
			t.skip_next = true
			events.append({"t": "salta", "pid": target})
			return true
		Card.VOTO:
			if defer_votes:
				pending_votes += 1           # nel gioco il voto si fa dopo le carte, aspettando chi vota
				events.append({"t": "voto_chiamato"})
			else:
				_vote(vote_fn)
			return true
		Card.TESTIMONE:
			if hidden_sab(pid) and t != null and not t.free and target != pid:
				# il ruolo va a un legato che non è già sabotatore (con due sabotatori: mai al complice)
				var pool := chained().filter(func(q: int) -> bool: return not is_sab(q))
				if pool.is_empty():
					return false
				if random_pass or is_sab(target):
					target = pool[rng.randi() % pool.size()]
				_move_role(pid, target)
			return false
	return false


func _vote(vote_fn: Callable) -> void:
	votes_played += 1
	var tally := {}
	var voted := {}                 # votante -> votato
	var asks := 0                   # quanti chiedono il Guardiano
	var voters: Array[int] = []
	voters.assign(range(n))
	var need := majority if n == 4 else n / 2 + 1
	if voters_chained:              # votano solo i legati, a maggioranza (4 -> 3, 3 -> 2, 2 -> 2)
		voters = chained()
		need = voters.size() / 2 + 1
	for v in voters:
		if players[v].dead and not dead_vote:
			continue                # gli eliminati non votano più
		var res = vote_fn.call(v)   # pid votato, oppure {v: pid, g: chiede il Guardiano}
		var who: int = res["v"] if res is Dictionary else res
		if res is Dictionary and res.get("g", false):
			asks += 1
		voted[v] = who
		tally[who] = tally.get(who, 0) + 1
	# il Guardiano (una volta per manche): metà delle volte indica il vero sabotatore, metà un innocente a caso.
	# Entra se almeno 2 lo chiedono, oppure (regola semplice) quando manca un solo voto
	var hidden: Array[int] = []
	for q in sabs():
		if hidden_sab(q):
			hidden.append(q)
	if guardian and not guardian_used and not hidden.is_empty():
		var most := 0
		for who in tally:
			most = maxi(most, tally[who])
		if guardian_after and most == need - 1 and guardian_ask_fn.is_valid():
			# voti mostrati prima: manca un voto, e si chiede a tutti se chiamare il Guardiano
			asks = 0
			for v in voters:
				if (dead_vote or not players[v].dead) and guardian_ask_fn.call(v, tally):
					asks += 1
		var call_it := most == need - 1 and not guardian_by_vote
		if guardian_by_vote:
			call_it = asks >= 2 and (most == need - 1 or not guardian_after)
		if call_it:
			guardian_used = true
			var g: int = hidden[rng.randi() % hidden.size()]
			if rng.randf() < 0.5:
				var inn: Array[int] = []
				for q in n:
					if not is_sab(q):
						inn.append(q)
				g = inn[rng.randi() % inn.size()]
				guardian_lied = true
			tally[g] = tally.get(g, 0) + 1
			events.append({"t": "guardiano", "pid": g})
	last_tally = tally.duplicate()
	last_votes = voted.duplicate()
	# serve un solo più votato, con almeno `majority` voti
	var top := -1
	var best := 0
	var tie := false
	for who in tally:
		if tally[who] > best:
			best = tally[who]
			top = who
			tie = false
		elif tally[who] == best:
			tie = true
	if tie or best < need:
		top = -1
	if top < 0:
		events.append({"t": "voto", "esito": "nessuna maggioranza"})
		return
	if is_sab(top) and players[top].unmasked:
		events.append({"t": "voto", "esito": "già scoperto", "pid": top})
		return
	if is_sab(top):
		unmasked = true
		players[top].unmasked = true
		unmask_turn = turn
		votes_right += 1
		var s := players[top]
		s.chains = mini(s.chains + unmask_penalty, max_chains)
		var keep: Array[int] = []
		for c in s.hand:
			if c != Card.TESTIMONE:
				keep.append(c)
		s.hand = keep
		events.append({"t": "voto", "esito": "scoperto", "pid": top})
		# premio per chi ha visto giusto: ogni innocente legato che l'ha votato perde subito delle catene
		if unmask_reward > 0:
			for v in voted:
				if voted[v] == top and v != top and not players[v].free:
					players[v].chains = maxi(players[v].chains - unmask_reward, 0)
					events.append({"t": "premio", "pid": v})
	else:
		cleared[top] = turn
		events.append({"t": "voto", "esito": "innocente", "pid": top})
		# seconda modalità: l'innocente condannato a torto è eliminato (brucia subito), il sabotatore resta nascosto
		if wrong_vote_kills and not players[top].free and not players[top].dead:
			players[top].dead = true
			players[top].hand.clear()
			eliminated.append(top)
			events.append({"t": "eliminato", "pid": top})


## Un voto rimasto in sospeso (defer_votes). Gli eventi del voto si aggiungono a `events` dopo `from`; restituisce
## l'indice da cui leggerli.
func run_vote(vote_fn: Callable) -> int:
	var from := events.size()
	if pending_votes <= 0 or over:
		return from
	pending_votes -= 1
	_vote(vote_fn)
	if chained().size() <= 1:
		finish()
	return from


func _burn_extra(pid: int, c: Dictionary) -> void:
	var p := players[pid]
	while p.hand.size() > hand_max:
		var bi: int = c.get("burn", 0)
		if bi < 0 or bi >= p.hand.size():
			bi = 0
		p.hand.remove_at(bi)


func _rotate_first() -> void:
	for k in range(1, n + 1):
		var pid := (first + k) % n
		if not players[pid].free and not players[pid].dead:
			first = pid
			return


## Ultimo respiro: resta l'ultima candela (o meno).
func is_last_breath() -> bool:
	return not over and candles <= 1


## 30 secondi in tempo reale: a turno casuale ogni legato può giocare una carta di catene, finché nessuno ne vuole
## più giocare. play_fn(pid) -> {card: indice, target: pid} oppure {} per fermarsi. (Il simulatore; il gioco usa
## burst_begin / burst_play / burst_end mentre scorre il tempo vero.)
func run_final_burst(play_fn: Callable) -> void:
	if final_burst:
		burst_begin()
		var guard := 0
		while not burst_active.is_empty() and guard < 200:
			guard += 1
			var pid: int = burst_active[rng.randi() % burst_active.size()]
			var c: Dictionary = play_fn.call(pid)
			if not burst_play(pid, c.get("card", -1), c.get("target", pid), c.get("target2", -1)):
				burst_active.erase(pid)
			if chained().size() <= 1:
				break
	finish()


var burst_active: Array[int] = []   # chi può ancora giocare carte nell'ultimo respiro
var _burst_used := {}


func burst_begin() -> void:
	burst_active = chained()
	_burst_used = {}


## Carte giocabili nell'ultimo respiro.
func burst_allowed(card: int) -> bool:
	return card in [Card.TOGLI, Card.AGGIUNGI, Card.AGGIUNGI2] or (burst_salta and card == Card.SALTA)


## Una carta giocata subito nell'ultimo respiro; false se non è valida (chi la gioca si ferma).
## Gli eventi (togli, aggiungi, salta, libero) si aggiungono a `events`.
func burst_play(pid: int, ci: int, target: int, target2 := -1) -> bool:
	if not pid in burst_active:
		return false
	var p := players[pid]
	var card: int
	if ci == SECRET and p.secret > 0:
		_use_secret(p)
		card = Card.TOGLI
	elif ci < 0 or ci >= p.hand.size() or not burst_allowed(p.hand[ci]):
		return false
	else:
		card = p.hand[ci]
		p.hand.remove_at(ci)
	if card == Card.SALTA:
		# nell'ultimo respiro "Salta" ferma il bersaglio: non gioca più carte
		if target in burst_active:
			burst_active.erase(target)
			events.append({"t": "salta", "pid": target})
	else:
		_play(pid, card, target, Callable())
		if _doubles(pid, card, target, target2):
			_play(pid, card, target2, Callable())
	_burst_used[pid] = _burst_used.get(pid, 0) + 1
	if _burst_used[pid] >= burst_limit:
		burst_active.erase(pid)
	# chi arriva a zero nell'ultimo respiro si libera subito
	var before := chained()
	_check_free()
	for q in before:
		if players[q].free:
			burst_active.erase(q)
	return true


func burst_end() -> void:
	burst_active.clear()
	finish()



## Qualcuno si è appena liberato. Se è il sabotatore e nessuno era ancora libero (permesso solo con
## sab_can_free_first): il ruolo passa da solo a un altro legato, anche se era stato scoperto (il nuovo sabotatore
## torna nascosto), e lui è penalizzato nei punti.
func _on_free(pid: int) -> void:
	if not anyone_free:
		first_freed = pid
		if is_sab(pid) and sab_can_free_first:
			escaped.append(pid)
			var pool := chained().filter(func(q: int) -> bool: return not is_sab(q))
			if not pool.is_empty():
				_move_role(pid, pool[rng.randi() % pool.size()])
			else:
				players[pid].sab = false
			unmasked = false
			for q in sabs():
				unmasked = unmasked or players[q].unmasked
	anyone_free = true


## Usa la carta nascosta. Con secret_burns_card brucia anche una carta della mano, così il totale delle carte cala
## come per una carta normale e nessuno nota un "Togli" in più.
func _use_secret(p: Player) -> void:
	p.secret -= 1
	if secret_burns_card and not p.hand.is_empty():
		p.hand.remove_at(rng.randi() % p.hand.size())


## Il ruolo di sabotatore passa a `to`, insieme ai "Togli" nascosti non ancora usati (e, con swap_hands, alle carte
## in mano: il vecchio sabotatore prende quelle del nuovo, il totale non cambia).
## Il nuovo sabotatore è nascosto (anche se chi cede il ruolo era stato scoperto) e conosce il complice.
func _move_role(from: int, to: int) -> void:
	players[to].secret += players[from].secret
	players[from].secret = 0
	if swap_hands and to != from:
		var h := players[to].hand
		players[to].hand = players[from].hand
		players[from].hand = h
	players[from].sab = false
	players[from].unmasked = false
	players[to].sab = true
	players[to].unmasked = false
	passes += 1


## Fine manche: fra i legati brucia chi ha più catene (a pari merito tutti). Con burn_top 2 bruciano i due più legati,
## e chi è pari al secondo (con due soli legati ne brucia uno, salvo parità).
func finish() -> void:
	if over:
		return
	over = true
	burned.clear()
	burned.append_array(eliminated)
	var left := chained()
	if left.is_empty():
		return
	var counts: Array[int] = []
	for pid in left:
		counts.append(players[pid].chains)
	counts.sort()
	counts.reverse()
	var k := clampi(mini(burn_top, left.size() - 1), 1, left.size())
	var line := counts[k - 1]
	for pid in left:
		if players[pid].chains >= line:
			burned.append(pid)


## Punti della manche (docs/catene_altare.md). Il sabotatore mai scoperto che brucia prende 1 solo se con lui brucia
## anche un innocente (il complice non conta).
func score(pid: int) -> int:
	var b := pid in burned
	if hidden_sab(pid):
		if b:
			var with_inn := burned.any(func(q: int) -> bool: return not is_sab(q))
			return 1 if (not sab_alone_zero or with_inn) else 0
		return sab_win_points
	if b:
		return 0
	if pid in escaped:
		return sab_escape_points
	if players[pid].free:
		return first_free_points if pid == first_freed else 2
	return 1
