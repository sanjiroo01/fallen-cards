"""PROGETTO Live: Claude lavora dentro la finestra di Blender aperta dall'utente.

Sicurezza:
- ascolta solo su 127.0.0.1 (questo PC), su una porta scelta al momento, con una chiave segreta
  scritta in %LOCALAPPDATA%/PROGETTO_live/connessione.json e cancellata allo scollegamento;
- accetta solo i comandi dell'elenco COMANDI, con argomenti JSON semplici: nessun codice dalla rete;
- le modifiche girano solo come "azioni": file .py nella cartella azioni del progetto (versionata),
  scelti per nome; e solo se il file aperto sta nella cartella lavoro/ (una copia, mai l'originale);
- prima di ogni azione salva un punto di ripristino (gli ultimi 10) e un passo di annullamento.
"""

bl_info = {
    "name": "PROGETTO Live",
    "author": "Claude per il progetto PROGETTO",
    "version": (1, 0, 0),
    "blender": (4, 2, 0),
    "location": "Vista 3D > barra laterale (N) > PROGETTO",
    "description": "Collegamento locale con Claude: modifiche visibili dal vivo su una copia del personaggio",
    "category": "Interface",
}

import bpy
import datetime
import hmac
import importlib.util
import json
import os
import queue
import re
import secrets
import shutil
import socket
import threading
import time
import traceback

HOME = os.path.expanduser("~")
DEF_PROGETTO = os.path.join(HOME, "Desktop", "gioco claude", "GamePC")
DEF_RIFERIMENTI = os.path.join(HOME, "Documents", "BLENDER gioco claude")
CONN_DIR = os.path.join(os.environ.get("LOCALAPPDATA", HOME), "PROGETTO_live")
CONN_FILE = os.path.join(CONN_DIR, "connessione.json")
NOME_OK = re.compile(r"^[A-Za-z0-9_\-]{1,64}$")
MAX_MSG = 256 * 1024
MAX_CHECKPOINT = 10


# ------------------------------------------------------------------ stato condiviso

class Stato:
    server = None
    thread = None
    port = 0
    token = ""
    richieste = queue.Queue()
    operazione = "In attesa"
    log = []
    occupato = False


def _prefs():
    a = bpy.context.preferences.addons.get(__name__)
    return a.preferences if a else None


def cartella_azioni():
    p = _prefs()
    return os.path.join(p.progetto if p else DEF_PROGETTO, "tools", "blender", "live", "azioni")


def cartella_riferimenti():
    p = _prefs()
    return p.riferimenti if p else DEF_RIFERIMENTI


def cartella_lavoro():
    return os.path.join(cartella_riferimenti(), "lavoro")


def cartella_anteprime():
    return os.path.join(cartella_riferimenti(), "anteprime", "live")


def _dentro(path, cartella):
    try:
        return os.path.commonpath([os.path.realpath(path), os.path.realpath(cartella)]) == os.path.realpath(cartella)
    except ValueError:
        return False


def file_e_copia():
    f = bpy.data.filepath
    return bool(f) and _dentro(f, cartella_lavoro())


def scrivi(msg):
    riga = "%s  %s" % (datetime.datetime.now().strftime("%H:%M:%S"), msg)
    Stato.log.append(riga)
    del Stato.log[:-200]
    print("[PROGETTO Live]", msg)
    ridisegna()


def ridisegna():
    wm = bpy.context.window_manager
    if not wm:
        return
    for win in wm.windows:
        for area in win.screen.areas:
            area.tag_redraw()
    # forza l'aggiornamento della finestra anche nel mezzo di un'azione lunga
    try:
        win = wm.windows[0]
        with bpy.context.temp_override(window=win):
            bpy.ops.wm.redraw_timer(type="DRAW_WIN_SWAP", iterations=1)
    except Exception:
        pass


# ------------------------------------------------------------------ strumenti per le azioni

def _vista3d():
    for win in bpy.context.window_manager.windows:
        for area in win.screen.areas:
            if area.type == "VIEW_3D":
                reg = next((r for r in area.regions if r.type == "WINDOW"), None)
                if reg:
                    return win, area, reg
    return None, None, None


def inquadra(nomi):
    objs = [bpy.data.objects[n] for n in nomi if n in bpy.data.objects]
    if not objs:
        return "nessun oggetto trovato"
    win, area, reg = _vista3d()
    if not area:
        return "nessuna vista 3D aperta"
    vl = bpy.context.view_layer
    prima = [o for o in vl.objects if o.select_get()]
    attivo = vl.objects.active
    for o in prima:
        o.select_set(False)
    for o in objs:
        if o.name in vl.objects:
            o.select_set(True)
    with bpy.context.temp_override(window=win, area=area, region=reg):
        if area.spaces.active.region_3d.view_perspective == "CAMERA":
            area.spaces.active.region_3d.view_perspective = "PERSP"
        bpy.ops.view3d.view_selected(use_all_regions=False)
    for o in objs:
        o.select_set(False)
    for o in prima:
        o.select_set(True)
    vl.objects.active = attivo
    ridisegna()
    return "inquadrati: " + ", ".join(o.name for o in objs)


def anteprima(nome="vista", tipo="vista", camera=None):
    if not NOME_OK.match(nome):
        raise ValueError("nome anteprima non valido")
    os.makedirs(cartella_anteprime(), exist_ok=True)
    path = os.path.join(cartella_anteprime(), "%s_%s.png" % (datetime.datetime.now().strftime("%Y%m%d-%H%M%S"), nome))
    scn = bpy.context.scene
    if tipo == "render":
        old_cam, old_path = scn.camera, scn.render.filepath
        if camera:
            scn.camera = bpy.data.objects[camera]
        scn.render.filepath = path
        bpy.ops.render.render(write_still=True)
        scn.camera, scn.render.filepath = old_cam, old_path
    else:
        win, area, reg = _vista3d()
        if not area:
            raise RuntimeError("nessuna vista 3D aperta per l'anteprima")
        ov = area.spaces.active.overlay
        prima = ov.show_overlays
        ov.show_overlays = False          # niente griglia, luci e selezioni nell'immagine
        try:
            with bpy.context.temp_override(window=win, area=area, region=reg):
                bpy.ops.render.opengl(write_still=False, view_context=True)
        finally:
            ov.show_overlays = prima
        bpy.data.images["Render Result"].save_render(path)
    scrivi("Anteprima salvata: " + os.path.basename(path))
    return path


class Live:
    """Quello che un'azione può usare: passi visibili, inquadrature, anteprime."""

    def passo(self, msg):
        Stato.operazione = msg
        scrivi("▶ " + msg)

    inquadra = staticmethod(inquadra)
    anteprima = staticmethod(anteprima)
    ridisegna = staticmethod(ridisegna)


# ------------------------------------------------------------------ comandi ammessi

def checkpoint():
    d = os.path.join(cartella_lavoro(), "ripristino")
    os.makedirs(d, exist_ok=True)
    base = os.path.splitext(os.path.basename(bpy.data.filepath))[0]
    path = os.path.join(d, "%s_%s.blend" % (base, datetime.datetime.now().strftime("%Y%m%d-%H%M%S")))
    bpy.ops.wm.save_as_mainfile(filepath=path, copy=True, compress=True)
    vecchi = sorted(f for f in os.listdir(d) if f.startswith(base + "_") and f.endswith(".blend"))
    for f in vecchi[:-MAX_CHECKPOINT]:
        os.remove(os.path.join(d, f))
    return path


def cmd_stato(a):
    return {"file": bpy.data.filepath, "copia_di_lavoro": file_e_copia(), "operazione": Stato.operazione,
            "oggetti": len(bpy.data.objects), "azioni": sorted(f[:-3] for f in os.listdir(cartella_azioni())
                                                             if f.endswith(".py") and not f.startswith("_"))
            if os.path.isdir(cartella_azioni()) else [], "log": Stato.log[-15:]}


def cmd_messaggio(a):
    testo = str(a.get("testo", ""))[:300]
    Stato.operazione = testo
    scrivi("💬 " + testo)
    return {"ok": True}


def cmd_apri_copia(a):
    nome = a.get("originale", "")
    if not NOME_OK.match(nome):
        raise ValueError("nome originale non valido")
    orig = os.path.join(cartella_riferimenti(), nome + ".blend")
    if not os.path.isfile(orig):
        raise FileNotFoundError("originale non trovato: " + orig)
    os.makedirs(cartella_lavoro(), exist_ok=True)
    copia = os.path.join(cartella_lavoro(), nome + "_live.blend")
    if a.get("nuova") or not os.path.isfile(copia):
        if os.path.isfile(copia):
            d = os.path.join(cartella_lavoro(), "ripristino")
            os.makedirs(d, exist_ok=True)
            shutil.copy2(copia, os.path.join(d, "%s_live_%s.blend" % (nome, datetime.datetime.now().strftime("%Y%m%d-%H%M%S"))))
        shutil.copy2(orig, copia)
        scrivi("Copia creata da %s (originale intatto)" % os.path.basename(orig))
    _apri(copia)
    return {"aperto": copia}


def _apri(path):
    win = bpy.context.window_manager.windows[0]
    with bpy.context.temp_override(window=win):
        bpy.ops.wm.open_mainfile(filepath=path, load_ui=False)
    scrivi("Aperto: " + os.path.basename(path))


def cmd_azione(a):
    nome = a.get("nome", "")
    if not NOME_OK.match(nome) or nome.startswith("_"):
        raise ValueError("nome azione non valido")
    if not file_e_copia():
        raise PermissionError("le azioni girano solo su una copia in %s: usa prima apri_copia" % cartella_lavoro())
    path = os.path.join(cartella_azioni(), nome + ".py")
    if not os.path.isfile(path) or not _dentro(path, cartella_azioni()):
        raise FileNotFoundError("azione inesistente: " + nome)
    args = a.get("args", {}) or {}
    if not isinstance(args, dict) or not all(isinstance(v, (str, int, float, bool, list, type(None))) for v in args.values()):
        raise ValueError("argomenti ammessi: solo testi, numeri, vero/falso, liste")
    cp = checkpoint()
    bpy.ops.ed.undo_push(message="PROGETTO Live: prima di " + nome)
    spec = importlib.util.spec_from_file_location("progetto_azione_" + nome, path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    scrivi("Azione: %s %s" % (nome, json.dumps(args, ensure_ascii=False) if args else ""))
    t = time.time()
    out = mod.run(Live(), **args)
    bpy.ops.ed.undo_push(message="PROGETTO Live: " + nome)
    Stato.operazione = "Fatto: " + nome
    scrivi("✔ %s (%.1f s)" % (nome, time.time() - t))
    return {"risultato": out, "ripristino": cp}


def cmd_anteprima(a):
    return {"file": anteprima(a.get("nome", "vista"), a.get("tipo", "vista"), a.get("camera"))}


def cmd_inquadra(a):
    nomi = a.get("oggetti", [])
    if not isinstance(nomi, list):
        raise ValueError("oggetti: lista di nomi")
    return {"esito": inquadra([str(n) for n in nomi])}


def cmd_annulla(a):
    if not file_e_copia():
        raise PermissionError("annulla funziona solo sulla copia di lavoro")
    d = os.path.join(cartella_lavoro(), "ripristino")
    base = os.path.splitext(os.path.basename(bpy.data.filepath))[0]
    cps = sorted(f for f in os.listdir(d) if f.startswith(base + "_")) if os.path.isdir(d) else []
    if not cps:
        raise FileNotFoundError("nessun punto di ripristino")
    corrente = bpy.data.filepath
    shutil.copy2(os.path.join(d, cps[-1]), corrente)
    os.remove(os.path.join(d, cps[-1]))
    _apri(corrente)
    return {"ripristinato": cps[-1]}


def cmd_salva(a):
    if not file_e_copia():
        raise PermissionError("si salva solo la copia di lavoro, mai un originale")
    bpy.ops.wm.save_mainfile()
    scrivi("Copia salvata")
    return {"salvato": bpy.data.filepath}


COMANDI = {"stato": cmd_stato, "messaggio": cmd_messaggio, "apri_copia": cmd_apri_copia, "azione": cmd_azione,
           "anteprima": cmd_anteprima, "inquadra": cmd_inquadra, "annulla": cmd_annulla, "salva": cmd_salva}


# ------------------------------------------------------------------ server locale

def _gestisci(conn):
    try:
        conn.settimeout(15)
        dati = b""
        while not dati.endswith(b"\n"):
            pezzo = conn.recv(65536)
            if not pezzo:
                return
            dati += pezzo
            if len(dati) > MAX_MSG:
                raise ValueError("messaggio troppo lungo")
        req = json.loads(dati.decode("utf8"))
        if not hmac.compare_digest(str(req.get("token", "")), Stato.token):
            risp = {"ok": False, "errore": "chiave non valida"}
        elif req.get("cmd") not in COMANDI:
            risp = {"ok": False, "errore": "comando non ammesso", "ammessi": sorted(COMANDI)}
        else:
            ev = threading.Event()
            box = {}
            Stato.richieste.put((req["cmd"], req.get("args") or {}, ev, box))
            if not ev.wait(1800):
                risp = {"ok": False, "errore": "tempo scaduto"}
            else:
                risp = box["risp"]
        conn.settimeout(None)
        conn.sendall((json.dumps(risp, ensure_ascii=False, default=str) + "\n").encode("utf8"))
    except Exception as e:
        try:
            conn.sendall((json.dumps({"ok": False, "errore": str(e)}) + "\n").encode("utf8"))
        except Exception:
            pass
    finally:
        conn.close()


def _ascolta(srv):
    while Stato.server is srv:
        try:
            conn, addr = srv.accept()
        except OSError:
            break
        if addr[0] != "127.0.0.1":
            conn.close()
            continue
        threading.Thread(target=_gestisci, args=(conn,), daemon=True).start()


def _esegui_coda():
    """Timer nel thread principale di Blender: qui (e solo qui) si tocca la scena."""
    try:
        while True:
            cmd, args, ev, box = Stato.richieste.get_nowait()
            Stato.occupato = True
            try:
                box["risp"] = {"ok": True, **COMANDI[cmd](args)}
            except Exception as e:
                scrivi("✖ %s: %s" % (cmd, e))
                box["risp"] = {"ok": False, "errore": "%s: %s" % (type(e).__name__, e),
                               "traccia": traceback.format_exc()[-2000:]}
            finally:
                Stato.occupato = False
                ev.set()
    except queue.Empty:
        pass
    return 0.1 if Stato.server else None


def collega():
    if Stato.server:
        return
    srv = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    srv.bind(("127.0.0.1", 0))
    srv.listen(4)
    Stato.server = srv
    Stato.port = srv.getsockname()[1]
    Stato.token = secrets.token_urlsafe(32)
    os.makedirs(CONN_DIR, exist_ok=True)
    with open(CONN_FILE, "w", encoding="utf8") as f:
        json.dump({"port": Stato.port, "token": Stato.token, "pid": os.getpid()}, f)
    Stato.thread = threading.Thread(target=_ascolta, args=(srv,), daemon=True)
    Stato.thread.start()
    if not bpy.app.timers.is_registered(_esegui_coda):
        bpy.app.timers.register(_esegui_coda, first_interval=0.1, persistent=True)
    Stato.operazione = "Collegato, in attesa di Claude"
    scrivi("Collegato su 127.0.0.1:%d (solo questo PC)" % Stato.port)


def scollega():
    srv, Stato.server = Stato.server, None
    if srv:
        try:
            srv.close()
        except OSError:
            pass
    Stato.token = ""
    try:
        os.remove(CONN_FILE)
    except OSError:
        pass
    Stato.operazione = "Scollegato"
    scrivi("Scollegato")


# ------------------------------------------------------------------ interfaccia

class PROGETTO_Prefs(bpy.types.AddonPreferences):
    bl_idname = __name__
    progetto: bpy.props.StringProperty(name="Progetto GamePC", subtype="DIR_PATH", default=DEF_PROGETTO)
    riferimenti: bpy.props.StringProperty(name="Cartella personaggi", subtype="DIR_PATH", default=DEF_RIFERIMENTI)

    def draw(self, context):
        self.layout.prop(self, "progetto")
        self.layout.prop(self, "riferimenti")


class PROGETTO_OT_collega(bpy.types.Operator):
    bl_idname = "progetto.collega"
    bl_label = "Collega Claude"
    bl_description = "Accetta i comandi di Claude da questo PC (solo locale)"

    def execute(self, context):
        collega()
        return {"FINISHED"}


class PROGETTO_OT_scollega(bpy.types.Operator):
    bl_idname = "progetto.scollega"
    bl_label = "Scollega"

    def execute(self, context):
        scollega()
        return {"FINISHED"}


class PROGETTO_OT_anteprime(bpy.types.Operator):
    bl_idname = "progetto.apri_anteprime"
    bl_label = "Apri cartella anteprime"

    def execute(self, context):
        os.makedirs(cartella_anteprime(), exist_ok=True)
        bpy.ops.wm.path_open(filepath=cartella_anteprime())
        return {"FINISHED"}


class PROGETTO_PT_live(bpy.types.Panel):
    bl_label = "PROGETTO Live"
    bl_space_type = "VIEW_3D"
    bl_region_type = "UI"
    bl_category = "PROGETTO"

    def draw(self, context):
        L = self.layout
        if Stato.server:
            L.label(text="Collegato (solo questo PC)", icon="LINKED")
            L.operator("progetto.scollega", icon="UNLINKED")
        else:
            L.label(text="Non collegato", icon="UNLINKED")
            L.operator("progetto.collega", icon="LINKED")
        box = L.box()
        f = bpy.data.filepath
        if not f:
            box.label(text="Nessun file aperto", icon="FILE")
        elif file_e_copia():
            box.label(text="Copia di lavoro: " + os.path.basename(f), icon="CHECKMARK")
        else:
            box.label(text="Originale: Claude non lo modifica", icon="LOCKED")
            box.label(text=os.path.basename(f))
        box = L.box()
        box.label(text=("⏳ " if Stato.occupato else "") + Stato.operazione, icon="INFO")
        col = box.column(align=True)
        col.scale_y = 0.8
        for riga in Stato.log[-10:]:
            col.label(text=riga)
        L.operator("progetto.apri_anteprime", icon="IMAGE_DATA")


CLASSI = (PROGETTO_Prefs, PROGETTO_OT_collega, PROGETTO_OT_scollega, PROGETTO_OT_anteprime, PROGETTO_PT_live)


def register():
    for c in CLASSI:
        bpy.utils.register_class(c)


def unregister():
    scollega()
    if bpy.app.timers.is_registered(_esegui_coda):
        bpy.app.timers.unregister(_esegui_coda)
    for c in reversed(CLASSI):
        bpy.utils.unregister_class(c)
