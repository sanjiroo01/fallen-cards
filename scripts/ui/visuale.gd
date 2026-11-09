class_name Visuale
extends RefCounted
## Inquadratura della partita scelta dal giocatore (Audio e schermo > Visuale, oppure il tasto V in partita),
## salvata in user://visuale.cfg. Ogni voce: posizione della telecamera e punto guardato (r = raggio del cerchio).

const CFG := "user://visuale.cfg"
const NOMI := ["Classica", "Alta", "Di tre quarti", "Dall'alto", "Ravvicinata"]

static var livello := 0
static var _caricato := false


static func carica() -> void:
	if _caricato:
		return
	_caricato = true
	var cf := ConfigFile.new()
	if cf.load(CFG) == OK:
		livello = clampi(int(cf.get_value("visuale", "livello", 0)), 0, NOMI.size() - 1)


static func scegli(l: int) -> void:
	livello = posmod(l, NOMI.size())
	_caricato = true
	var cf := ConfigFile.new()
	cf.set_value("visuale", "livello", livello)
	cf.save(CFG)


## Posizione e orientamento della telecamera per l'inquadratura scelta.
static func transform(r: float) -> Transform3D:
	carica()
	var pos: Vector3
	var at: Vector3
	match livello:
		0:      # dietro di te, come all'inizio
			pos = Vector3(0, 4.1, r + 3.1)
			at = Vector3(0, 1.15, -1.5)        # un po' più in alto: dentro anche il trono del Custode
		1:      # alta: si vede sopra l'altare e il fuoco
			pos = Vector3(0, 6.4, r + 2.2)
			at = Vector3(0, 0.3, -1.1)
		2:      # di tre quarti: l'altare non copre mai chi sta davanti
			pos = Vector3(3.6, 4.6, r + 2.6)
			at = Vector3(-0.2, 0.5, -0.6)
		3:      # dall'alto, quasi a picco
			pos = Vector3(0, 9.0, r + 0.9)
			at = Vector3(0, 0.0, -0.3)
		_:      # ravvicinata, dietro le spalle
			pos = Vector3(0.7, 2.7, r + 1.7)
			at = Vector3(0, 1.0, -1.2)
	return Transform3D(Basis(), pos).looking_at(at, Vector3.UP)
