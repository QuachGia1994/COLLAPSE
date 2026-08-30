from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
IOS_FILES = [
    ROOT / "Resources/en.lproj/Localizable.strings",
    ROOT / "Resources/vi.lproj/Localizable.strings",
    ROOT / "Resources/ja.lproj/Localizable.strings",
    ROOT / "Resources/zh-Hans.lproj/Localizable.strings",
]
ANDROID_FILES = [
    ROOT / "android/app/src/main/res/values/strings.xml",
    ROOT / "android/app/src/main/res/values-vi/strings.xml",
    ROOT / "android/app/src/main/res/values-ja/strings.xml",
    ROOT / "android/app/src/main/res/values-zh-rCN/strings.xml",
]

# Dynamic iOS key templates (keys built with string interpolation in Swift)
# mapped to the concrete keys each expansion must resolve to. A dynamic
# template found in code but missing here is a hard error so new dynamic
# keys cannot silently bypass verification.
IOS_DYNAMIC_KEY_TEMPLATES: dict[str, list[str]] = {
    "mode.\\(rawValue).detail": [
        "mode.classic.detail",
        "mode.rush.detail",
        "mode.precision.detail",
        "mode.daily.detail",
        "mode.zen.detail",
    ],
}

IOS_SOURCES_GLOB = "Sources/**/*.swift"
IOS_USED_KEY_RE = re.compile(r'language\.text\("([^"]+)"\)')
# C-style format specifiers: %@, %d, %lld, %1$s, %% is an escape and ignored.
FORMAT_SPECIFIER_RE = re.compile(r"%(?:\d+\$)?(?:ll|l|h|hh)?[@a-zA-Z]")


def ios_entries(path: Path) -> dict[str, str]:
    text = path.read_text(encoding="utf-8")
    reject_replacement_character(path, text)
    return dict(re.findall(r'^\s*"([^"]+)"\s*=\s*"((?:[^"\\]|\\.)*)"\s*;', text, flags=re.MULTILINE))


def android_entries(path: Path) -> dict[str, str]:
    text = path.read_text(encoding="utf-8")
    reject_replacement_character(path, text)
    return dict(re.findall(r'<string\s+name="([^"]+)"[^>]*>(.*?)</string>', text, flags=re.DOTALL))


def reject_replacement_character(path: Path, text: str) -> None:
    if "\ufffd" in text:
        raise ValueError(f"Unicode replacement character found in {path}")


def format_specifiers(value: str) -> list[str]:
    return sorted(FORMAT_SPECIFIER_RE.findall(value))


def verify_key_parity(group: str, entries: list[dict[str, str]]) -> list[str]:
    baseline = entries[0]
    errors: list[str] = []
    for entry in entries[1:]:
        missing = sorted(baseline.keys() - entry.keys())
        extra = sorted(entry.keys() - baseline.keys())
        if missing:
            errors.append(f"{group}: missing {missing}")
        if extra:
            errors.append(f"{group}: extra {extra}")
    return errors


def verify_format_parity(group: str, entries: list[dict[str, str]]) -> list[str]:
    baseline = entries[0]
    errors: list[str] = []
    for key, value in baseline.items():
        expected = format_specifiers(value)
        for entry in entries[1:]:
            if key not in entry:
                continue
            actual = format_specifiers(entry[key])
            if actual != expected:
                errors.append(
                    f"{group}: format specifier mismatch for {key}: "
                    f"baseline {expected} vs {actual}"
                )
    return errors


def ios_used_key_errors(baseline_keys: set[str]) -> list[str]:
    errors: list[str] = []
    seen_templates: set[str] = set()
    for path in sorted(ROOT.glob(IOS_SOURCES_GLOB)):
        text = path.read_text(encoding="utf-8")
        for key in IOS_USED_KEY_RE.findall(text):
            if "\\(" in key:
                if key not in IOS_DYNAMIC_KEY_TEMPLATES:
                    errors.append(f"{path}: unregistered dynamic key template \"{key}\"")
                seen_templates.add(key)
                continue
            if key not in baseline_keys:
                errors.append(f"{path}: key \"{key}\" used in code but missing from EN strings")
    for template in IOS_DYNAMIC_KEY_TEMPLATES:
        if template not in seen_templates:
            errors.append(f"stale dynamic key template \"{template}\" (not used in code anymore)")
    return errors


def verify_dynamic_template_expansions(baseline_keys: set[str]) -> list[str]:
    errors: list[str] = []
    for template, expansions in IOS_DYNAMIC_KEY_TEMPLATES.items():
        for key in expansions:
            if key not in baseline_keys:
                errors.append(f"dynamic template \"{template}\" expands to missing key \"{key}\"")
    return errors


def main() -> int:
    try:
        ios = [ios_entries(path) for path in IOS_FILES]
        android = [android_entries(path) for path in ANDROID_FILES]
    except (OSError, UnicodeError, ValueError) as error:
        print(error)
        return 1

    errors: list[str] = []
    errors += verify_key_parity("iOS", ios)
    errors += verify_key_parity("Android", android)
    errors += verify_format_parity("iOS", ios)
    errors += verify_format_parity("Android", android)

    ios_baseline_keys = set(ios[0])
    errors += ios_used_key_errors(ios_baseline_keys)
    errors += verify_dynamic_template_expansions(ios_baseline_keys)

    if errors:
        print("\n".join(errors))
        return 1
    print("Localization keys match across EN/VI/JA/zh-Hans on iOS and Android.")
    print("Format specifiers match per key; all iOS code-referenced keys resolve.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
