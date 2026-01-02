# Downloads Intake — 2025-11-20

## Overview
- Snapshot of `/home/cbwinslow/Downloads` captured on 2025-11-20; no files were moved.
- Proposed destinations assume the curated `Organized/` hierarchy so kingdom-monorepo can point to a stable layout.
- Hidden caches (for example `.mypy_cache/`) can be deleted once nothing is using them.

## Directories
- `51d8b490bdbfb31663bc397278ad2e4039a8224a109f462f781884af1fa3527c-2025-11-15-08-16-45-67d5176ed4a74597812e8fab34ef0bdc/` — ChatGPT export with conversation JSON and media; move to `Organized/Conversations/chatgpt/2025-11-15/` and pull notable prompts into `docs/journals/` if needed.
- `bigdatatools-common-253.28294.51/` — JetBrains BigData Tools plugin libs; archive under `Organized/Programs/Packages/jetbrains/` or remove after installing.
- `cbw-knowledge-base/` — personal knowledge repo; consider linking or mirroring into `Organized/Projects/` (and referenced in `kingdom-monorepo` docs) instead of keeping a stray copy here.
- `cloudcurio-tui-with-scripts (1)/` — duplicate project checkout; park under `Organized/Projects/Monorepos/cloudcurio-tui/` and dedupe with the primary source.
- `ej-release-253.487.77/` — IntelliJ plugin release payload; store in `Organized/Programs/Packages/jetbrains/`.
- `grav-admin-v1.8.0-beta.22/` — Grav CMS beta; archive to `Organized/Archives/TarGzArchives/grav/`.
- `ideaIU-2025.2 (2).4/`, `ideaIU-2025.2 (3).4/`, `ideaIU-2025.2.4/` — multiple IntelliJ IDEA builds; keep `ideaIU-2025.2.4/` under `Organized/Programs/Installers/jetbrains/` and drop older duplicates.
- `infisical-main/` — source tree; relocate to `Organized/Projects/OpenSource/infisical/` or add as a tracked external in kingdom-monorepo.
- `logs_49983169625/` — multi-agent how-tos and logs; file under `Organized/Docs/Guides/multi-agent/` and link any reusable SOPs into `docs/tasks/TASKS.md`.
- `Organized/` — current curated archive; treat as the canonical storage root kingdom-monorepo points to.
- `serendipity-2.5.0/` — Serendipity blog installer; archive to `Organized/Archives/ZipArchives/serendipity/` or `Organized/Programs/Packages/serendipity/`.

## Loose files (grouped by handling)
- Archives/backups: `_personal-20251120T031848Z-1-001.zip`, `books-20251120T031841Z-1-001.zip`, `dev-20251120T031908Z-1-001.zip`, `dev-20251120T031908Z-1-002.zip`, `dev-20251120T031908Z-1-003.zip`, `Google AI Studio-20251120T031900Z-1-001.zip` → move to `Organized/Archives/ZipArchives/` with tags noting contents.
- Packages/binaries: `bazelisk-amd64.deb`, `bazelisk-linux-amd64`, `midori_11.6-1_amd64.deb` → store under `Organized/Programs/Installers/` (keep the raw bazelisk binary in `Organized/Programs/Binaries/` if you want a ready-to-run copy).
- Notebooks: `Animated_Story_Video_Generation_gemini.ipynb` → place in `Organized/Projects/Notebooks/animated-story/` and index in kingdom-monorepo if reused.
- Scripts and source: `cbw_bubbletea_wish_tui_main.go` (+ duplicate), `cbw_find.sh` (+ duplicate), `cbwtools.py` (+ duplicate), `cbwtools_tui_main.go`, `google_photos_video_downloader.py`, `ssh_profile_manager.py`, `prism.css`, `prism.js` → sort into `Organized/Scripts/Go|Python|Shell/` (or upstream into `tools/` here) after deduping the `(1)` copies.
- Docs and PDFs: `Best Practices for Organizing SSH Configurations A.md`, `this isnt. please scrape the website for all 118 e.md`, `cbwinslow@tutamail.com - Tuta Mail_ Login & Sign up for free.pdf`, `temp.pdf`, `temp (1|2|3).pdf` → move to `Organized/Docs/Guides/` (create subfolders like `email/` or `ssh/` as needed).
- Media: `1600w-mJUsixtsWv8.webp`, `20220914_220213.jpg`, `4523.jpg`, `photo-1505699261378-c372af38134c.jpeg`, `photo-1687593883595-6b678fc5c413.jpeg` → corral into `Organized/Docs/Media/` (or `Organized/Misc/Media/` if they are reference images).

## Suggested next actions
- Move the grouped items into their target `Organized/` locations, then regenerate metadata with `cd Organized && python gen_catalog.py`.
- For the ChatGPT export, extract a few high-signal conversations into `docs/journals/` entries so they become searchable in kingdom-monorepo.
- Trim duplicate installers (`ideaIU-2025.2 (2).4/`, `ideaIU-2025.2 (3).4/`, script files with `(1)`) to keep the archive lean.
