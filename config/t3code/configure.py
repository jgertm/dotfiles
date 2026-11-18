"""Merge Home Manager preferences without replacing T3's private app state."""

import hashlib
import json
import os
from pathlib import Path
import sys
import tempfile


def with_preferences(existing, preferences):
    result = existing.copy()
    for key, value in preferences.items():
        result[key] = (
            with_preferences(existing.get(key, {}), value)
            if isinstance(value, dict) else value
        )
    return result


def merge(path, preferences):
    existing = json.loads(path.read_text()) if path.exists() else {}
    # T3 also accepts the legacy client-settings envelope.
    target = existing.get("settings", existing)
    if not isinstance(target, dict):
        raise ValueError(f"Expected an object in {path}")
    updated = with_preferences(target, preferences)
    if target == updated:
        return
    target.update(updated)
    fd, temporary = tempfile.mkstemp(dir=path.parent, prefix=path.name + ".")
    try:
        with os.fdopen(fd, "w") as output:
            json.dump(existing, output, indent=2)
            output.write("\n")
        os.replace(temporary, path)
    finally:
        Path(temporary).unlink(missing_ok=True)


state = Path(sys.argv[1])
state.mkdir(parents=True, exist_ok=True)
font = sys.argv[2]
merge(state / "client-settings.json", {
    "fontFamilyCode": font,
    "fontFamilyTerminal": font,
    "fontFamilyComposer": font,
    "fontFamilySans": font,
    "threadDetailsItems": {"context": True},
})
theme = state / "themes/dotfiles-tokyo-night.json"
theme.parent.mkdir(parents=True, exist_ok=True)
# T3 deliberately rejects symlinked themes, including Home Manager store links.
merge(theme, json.loads(Path(sys.argv[3]).read_text()))
# A stable revision reapplies the theme only when the managed palette changes.
revision = hashlib.sha256(theme.read_bytes()).hexdigest()
merge(state / "settings.json", {
    "defaultTheme": "dotfiles-tokyo-night",
    "defaultThemeSetAt": revision,
    "defaultAppearance": "dark",
    "defaultAppearanceSetAt": revision,
})
