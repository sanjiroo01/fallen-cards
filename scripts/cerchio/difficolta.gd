class_name Difficolta
extends RefCounted
## Difficoltà degli avversari scelta dal giocatore, salvata in user://difficolta.cfg.
## Normale: gli avversari di sempre. Adattivo: ricordano le tue mosse dei giri passati per prevederti e
## variano le loro per non farsi leggere (vedi CerchioBot.choose, adaptive). Nessuno dei due vede le
## scelte segrete del giro in corso.

const CFG := "user://difficolta.cfg"
const NOMI := ["Normale", "Adattivo"]
const NORMALE := 0
const ADATTIVO := 1

static var livello := NORMALE
static var _caricato := false


static func carica() -> void:
	if _caricato:
		return
	_caricato = true
	var cf := ConfigFile.new()
	if cf.load(CFG) == OK:
		livello = clampi(int(cf.get_value("avversari", "livello", NORMALE)), NORMALE, ADATTIVO)


static func scegli(l: int) -> void:
	livello = clampi(l, NORMALE, ADATTIVO)
	_caricato = true
	var cf := ConfigFile.new()
	cf.set_value("avversari", "livello", livello)
	cf.save(CFG)


static func adattivo() -> bool:
	carica()
	return livello == ADATTIVO
