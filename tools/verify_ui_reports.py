"""Check containment; content clipped inside a scroll viewport is intentional."""
import json
import sys
from pathlib import Path


def main(paths: list[str]) -> int:
    failures = []
    for name in paths:
        report = json.loads(Path(name).read_text(encoding="utf-8"))
        width, height = report["viewport"]["width"], report["viewport"]["height"]
        scrolls = [item for item in report["controls"] if item["class"] == "ScrollContainer"]
        scroll_paths = [item["path"] for item in scrolls]
        for item in report["findings"]:
            nodes = item.get("nodes", [])
            clipped_inside_scroll = (
                item.get("kind") == "offscreen"
                and nodes
                and all(any(node.startswith(path + "/") for path in scroll_paths) for node in nodes)
            )
            if not clipped_inside_scroll:
                failures.append((name, item["message"]))
        for control in report["controls"]:
            if any(control["path"].startswith(scroll["path"] + "/") for scroll in scrolls):
                continue
            x, y, w, h = control["rect"]
            if x < -1 or y < -1 or x + w > width + 1 or y + h > height + 1:
                failures.append((name, f'{control["path"]} is partially clipped: {control["rect"]}'))
    for name, message in failures:
        print(f"FAIL {name}: {message}")
    print(f"Full UI containment: {'FAIL' if failures else 'PASS'} ({len(paths)} reports)")
    return int(bool(failures) or not paths)


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
