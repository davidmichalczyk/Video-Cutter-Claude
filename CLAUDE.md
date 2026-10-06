# Reel-Schnitt mit video-use

Setup (macOS oder Linux): `bash scripts/setup.sh`, danach ElevenLabs-Key in `~/Developer/video-use/.env` (nie committen).
Python für alle Helpers/Skripte: `~/Developer/video-use/.venv/bin/python`.
Skill: `~/.claude/skills/video-use` (SKILL.md + helpers/). Assets: `~/Developer/video-use-assets/` (Fonts, mediapipe-Modell).

## Arbeitsweise mit David
Gilt universell für alle Claude-Sessions und alle Projekte, nicht nur für den Videoschnitt.
- Immer direkt die am besten geeignete Lösung nennen und empfehlen, auch wenn David etwas anderes vorschlägt. Wenn sein Vorschlag ein Umweg ist, das offen sagen und den besseren Weg begründet empfehlen.
- Einschränkungen der Umgebung (Upload-Limits, Cloud vs. lokal, fehlende Berechtigungen) sofort ansprechen, bevor er Zeit investiert.

## Vor jedem Reel
**Immer zuerst kurz fragen, für welches Unternehmen das Reel ist** (DaFITs, Young Athletic Nation oder ROOM14).
Logo, Handle und Caption-Akzentfarben kommen aus `brands/brands.json` — nie zwischen Marken mischen.
Nicht ohne Footage transkribieren (Scribe kostet Credits). Keine Zwischenfreigaben einholen: fertiges Video liefern, danach Änderungsoptionen nennen.

## Schnitt-Standard
1. Hook: erste 2 s halten, Start mit Zoom, der in 0,6 s aufzieht.
2. Pausen, Versprecher, Füllsätze, doppelte Takes raus. Schnitte nur an Wortgrenzen, nie zwischen Wörtern ohne Pause.
3. Schnitt framegenau selbst bauen (Frames per Index, Audio sample-genau) — Untertitel dürfen nicht driften.
4. Captions: fette weiße Montserrat-Wörter mit Pop, zwei Akzentfarben (pro Marke) mit dunklem Rand, ausgewählte Keywords groß in Instrument Serif Italic mit kleinen Wörtern darüber. Zusammengehörige Begriffe nie über zwei Zeilen trennen.
5. Text hinter der Person: Keywords groß in Anton hinter dem Kopf (mediapipe selfie_multiclass_256x256), Position an Kopfoberkante, nie in den oberen 200 px.
6. Zooms: Jump-Cuts innerhalb einer Szene abwechselnd normal / 12 % näher, Fokus auf Kopf. Punch-Zooms auf Keywords, kurze Monochrom-Sequenzen an emotionalen Stellen.
7. Sound: dezente Klicks, Pops, Whooshes, tiefe Hits alle ca. 3–5 s. Clip-Lautstärken angleichen, Endmix -14 LUFS / -1,5 dBTP.
8. Outro 2,4 s: Zoom + Abblende auf Schwarz, Markenlogo mit leichtem Glow, darunter Instagram-Handle, ausklingender Sound.
9. Keine Farbfilter. iPhone-HDR (HLG) bleibt HDR: HEVC 10 Bit, HLG, BT.2020; Captions/Grafiken in HDR-Farbraum umrechnen; Farbtreue numerisch prüfen.
10. Lange Renders im Hintergrund (Befehle brechen nach 5 min ab). Vor Export Stichproben-Frames an allen Effektstellen und Schnittkanten auf abgeschnittene Wörter prüfen.
