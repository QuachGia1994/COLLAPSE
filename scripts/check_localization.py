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


def ios_keys(path: Path) -> set[str]:
    text = path.read_text(encoding="utf-8")
    reject_replacement_character(path, text)
    return set(re.findall(r'^\s*"([^"]+)"\s*=', text, flags=re.MULTILINE))


def android_keys(path: Path) -> set[str]:
    text = path.read_text(encoding="utf-8")
    reject_replacement_character(path, text)
    return set(re.findall(r'<string\s+name="([^"]+)"', text))


def reject_replacement_character(path: Path, text: str) -> None:
    if "\ufffd" in text:
        raise ValueError(f"Unicode replacement character found in {path}")


def verify_group(paths: list[Path], reader) -> list[str]:
    baseline = reader(paths[0])
    errors: list[str] = []
    for path in paths[1:]:
        keys = reader(path)
        missing = sorted(baseline - keys)
        extra = sorted(keys - baseline)
        if missing:
            errors.append(f"{path}: missing {missing}")
        if extra:
            errors.append(f"{path}: extra {extra}")
    return errors


def main() -> int:
    try:
        errors = verify_group(IOS_FILES, ios_keys) + verify_group(ANDROID_FILES, android_keys)
    except (OSError, UnicodeError, ValueError) as error:
        print(error)
        return 1
    if errors:
        print("\n".join(errors))
        return 1
    print("Localization keys match across EN/VI/JA/zh-Hans on iOS and Android.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
