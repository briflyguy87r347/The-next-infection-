# Install Module 010 in THE NEXT INFECTION GitHub repository

This is a **GitHub-ready Godot source snapshot**, not a ZIP that GitHub automatically imports as code.
Do **not** upload only this ZIP to the repository's `main` branch and expect Godot to run it.

## Version and safe branch

- Project: THE NEXT INFECTION / OUTBREAK ZERO, Module 010.
- Current connected repository: https://github.com/briflyguy87r347/The-next-infection-
- Existing verified source branch: `feature/module-003-combat` (pull request #1).
- **Do not merge or replace `main` directly.** Create `feature/module-010-gameplay` from `feature/module-003-combat`.
- Module 010 includes all cumulative source files for features introduced after Module 003, including open-world mode, permanent bank, plots, guns, and zombie variants.
- Your game save is **not** in this GitHub package. Back up saves via the in-game export feature before importing another Godot project.

## Instructions for GitHub Codespaces (Android Chrome)

1. Open repository on GitHub -> green **Code** button -> **Codespaces** -> open your existing Codespace.
2. In the terminal, run `git status --short`. If you have pending changes, **do not overwrite them**. Commit those to their own backup branch or use `git stash push -u -m "Pre-Module-010-backup"` to safeguard them. Remember that a stash remains local to that Codespace, not on GitHub.
3. With a clean working tree, run:

   ```bash
   git fetch origin
   git switch -c feature/module-010-gameplay origin/feature/module-003-combat
   ```

4. Use the VS Code Explorer's **Upload Files** action to upload `TNI_Module_010_GitHub_Ready.zip` to the repository root in Codespaces. Do not upload it just to GitHub's web file list.
5. In the Codespaces terminal, extract it, keeping the folder paths intact:

   ```bash
   unzip -o TNI_Module_010_GitHub_Ready.zip -d .
   python3 tools/verify_repository.py
   git status --short
   ```

   This overwrites older source files **on your new development branch only**, after you preserved any unfinished edits in step 2. It does not remove original files or old Git history.

6. Run a Godot editor/startup check if Godot is available in the Codespace:

   ```bash
   godot --headless --editor --path . --quit
   godot --headless --path . --quit-after 180
   ```

   If `godot` isn't installed, the included GitHub Actions workflow will attempt a headless test after pushing. Always test on your Android tablet as well.

7. Stage and push source, not the uploaded ZIP:

   ```bash
   rm -f TNI_Module_010_GitHub_Ready.zip
   git add -A
   git diff --cached --stat
   git diff --cached --check
   git commit -m "Integrate Module 010 three-weapon gameplay and Florida world"
   git push -u origin feature/module-010-gameplay
   ```

8. Open a draft pull request targeting `feature/module-003-combat`:

   https://github.com/briflyguy87r347/The-next-infection-/compare/feature/module-003-combat...feature/module-010-gameplay?expand=1

   When Module 003 has been merged into `main`, you can retarget the new pull request to `main`, verify the changed-file list, and merge after testing.

## Important safeguards

- Do not delete `.gd.uid` files that already exist on GitHub; this package adds source without removing the existing UID files.
- `.godot/` cache should remain ignored.
- Do not commit personal save JSON, tokens, API secrets, or game account data.
- If the new branch name already exists, do **not** force push. Check its contents before choosing a new branch name.
- Godot source and exported Android APKs are separate: committing the source does not deploy a playable app to Google Play.
- The offline plot ownership and banking systems are only local prototypes, not authenticated multiplayer or real-money features.
