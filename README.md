# PROGETTO (nome provvisorio)

Gioco 3D per PC (Godot 4.6). Quattro campioni fantasy si affrontano attorno al cerchio rituale del
Custode. Ogni giro tutti scelgono in segreto chi attaccare, da chi difendersi, se riaccendere una candela
o usare la propria abilità; poi si rivela tutto insieme. Tre manche a punti, la terza vale doppio.

- Regole, classi, scenari e piano: `docs/progetto.md`.
- Diario del lavoro: `devlog.md`.
- Istruzioni per gli agenti: `CLAUDE.md`.

## Avviare
Apri `project.godot` con Godot 4.6 e premi Avvia, oppure dalla cartella superiore:

    godot/Godot_v4.6-stable_win64_console.exe --path GamePC

## Prove
    godot --headless --audio-driver Dummy --path . -- --auto --veloce=0.05 --esci   # partita automatica
    godot --headless --audio-driver Dummy --path . -- --clic --veloce=0.05 --esci   # interfaccia a caso
    godot --headless --path . -s res://tests/sim_cerchio_manche.gd -- ordine        # simulatore delle regole
