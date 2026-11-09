class_name Cfg
extends RefCounted
## I numeri del gioco: dopo le prove si bilancia cambiando solo questo file.
## Le regole provate nel simulatore sono in docs/progetto.md.

const CANDLES := 4.0              # candele (vite) a inizio manche
const MANCHE := 3                 # manche in una partita; l'ultima vale doppio
const POINTS := [0, 1, 2, 3]      # punti per piazzamento: primo a morire ... ultimo vivo
const GHOST_HITS_PER_POINT := 2   # previsioni giuste dello spettro per 1 punto (max 1 a manche)
const TURN_TIME := 40.0           # secondi per scegliere la mossa; poi sceglie il caso
const UI_SCALE := 0.8            # grandezza di scritte e riquadri (1 = com'erano prima)
const BOT_TEMP := 0.3             # quanto sono imprevedibili gli avversari (più alto = più casuali)
const PACT_MIN_CANDLES := 3.0     # i bot accettano il Patto solo con almeno queste candele

# --- ritmo della rivelazione (secondi) ---
const T_REVEAL := 3.0             # mosse scoperte sopra le teste
const T_ORDER := 3.6              # scritta al centro con l'ordine dei colpi
const T_EVENT := 1.4              # ogni colpo, contrattacco, candela
const T_END_ROUND := 1.6
const T_OMEN := 3.2               # la carta del Presagio resta in vista
