#!/usr/bin/env python3

from __future__ import annotations

import json
import os
import shutil
import sys
import textwrap
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
SKILL_DIR = SCRIPT_DIR.parent
CONFIG_PATH = SKILL_DIR / "config" / "providers.json"
ROLE_ORDER = ["most-capable", "general-executor"]
ROLE_USAGE = {
    "most-capable": "Plan, Review",
    "general-executor": "Execute",
}
DEFAULT_TTY_BOX_WIDTH = 78
DEFAULT_NON_TTY_BOX_WIDTH = 60
MIN_BOX_WIDTH = 44


class Style:
    def __init__(self) -> None:
        use_color = sys.stdout.isatty() and "NO_COLOR" not in os.environ
        if use_color:
            self.reset = "\033[0m"
            self.bold = "\033[1m"
            self.dim = "\033[2m"
            self.title = "\033[38;5;33m"
            self.provider = "\033[38;5;81m"
            self.label = "\033[38;5;245m"
            self.value = "\033[38;5;223m"
            self.command = "\033[38;5;120m"
            self.border = "\033[38;5;240m"
            self.accent = "\033[38;5;110m"
            self.success = "\033[38;5;78m"
        else:
            self.reset = ""
            self.bold = ""
            self.dim = ""
            self.title = ""
            self.provider = ""
            self.label = ""
            self.value = ""
            self.command = ""
            self.border = ""
            self.accent = ""
            self.success = ""


STYLE = Style()


def resolve_box_width() -> int:
    override = os.environ.get("SUBAGENT_ORCHESTRATION_BANNER_WIDTH")
    if override:
        try:
            width = int(override)
        except ValueError as exc:
            raise SystemExit(
                "ERROR: SUBAGENT_ORCHESTRATION_BANNER_WIDTH must be an integer"
            ) from exc
        if width < MIN_BOX_WIDTH:
            raise SystemExit(
                f"ERROR: SUBAGENT_ORCHESTRATION_BANNER_WIDTH must be >= {MIN_BOX_WIDTH}"
            )
        return width

    if sys.stdout.isatty():
        columns = shutil.get_terminal_size(
            fallback=(DEFAULT_TTY_BOX_WIDTH, 24)
        ).columns
        return max(MIN_BOX_WIDTH, min(DEFAULT_TTY_BOX_WIDTH, columns))

    return DEFAULT_NON_TTY_BOX_WIDTH


BOX_WIDTH = resolve_box_width()


def load_config() -> dict:
    try:
        return json.loads(CONFIG_PATH.read_text())
    except FileNotFoundError as exc:
        raise SystemExit(f"ERROR: missing config file: {CONFIG_PATH}") from exc
    except json.JSONDecodeError as exc:
        raise SystemExit(f"ERROR: invalid JSON in {CONFIG_PATH}: {exc}") from exc


def save_config(data: dict) -> None:
    CONFIG_PATH.write_text(json.dumps(data, indent=2) + "\n")


def providers(data: dict) -> dict:
    result = data.get("providers")
    if not isinstance(result, dict) or not result:
        raise SystemExit("ERROR: config/providers.json has no providers")
    return result


def get_provider(data: dict, provider_key: str) -> dict:
    all_providers = providers(data)
    if provider_key not in all_providers:
        valid = ", ".join(all_providers.keys())
        raise SystemExit(f"ERROR: unknown provider '{provider_key}'. Valid: {valid}")
    return all_providers[provider_key]


def build_commands(provider_key: str, provider: dict) -> tuple[str, str]:
    prefix = provider["invocation_prefix"]
    skill_name = provider["skill_name"]
    run_command = f"{prefix}{skill_name} <plan-path-or-instructions>"
    config_command = f"{prefix}{skill_name} config"
    return run_command, config_command


def styled(text: str, *styles: str) -> str:
    prefix = "".join(styles)
    return f"{prefix}{text}{STYLE.reset}" if prefix else text


def visible_len(text: str) -> int:
    length = 0
    skip = False
    for char in text:
        if skip:
            if char == "m":
                skip = False
            continue
        if char == "\033":
            skip = True
            continue
        length += 1
    return length


def wrap_plain(text: str, max_len: int) -> list[str]:
    if not text:
        return [""]

    return textwrap.wrap(
        text,
        width=max_len,
        break_long_words=True,
        break_on_hyphens=False,
    ) or [""]


def truncate_visible(text: str, max_len: int) -> str:
    if visible_len(text) <= max_len:
        return text

    output: list[str] = []
    visible = 0
    skip = False
    for char in text:
        output.append(char)
        if skip:
            if char == "m":
                skip = False
            continue
        if char == "\033":
            skip = True
            continue
        visible += 1
        if visible >= max_len - 1:
            break
    output.append("…")
    if STYLE.reset and not "".join(output).endswith(STYLE.reset):
        output.append(STYLE.reset)
    return "".join(output)


def box_line(text: str = "") -> str:
    inner_width = BOX_WIDTH - 4
    content = truncate_visible(text, inner_width)
    padding = " " * max(0, inner_width - visible_len(content))
    return f"{styled('│', STYLE.border)} {content}{padding} {styled('│', STYLE.border)}"


def box_rule(title: str) -> str:
    prefix = f"┌ {title} "
    fill = "─" * max(0, BOX_WIDTH - visible_len(prefix) - 1)
    return f"{styled(prefix, STYLE.border)}{styled(fill + '┐', STYLE.border)}"


def box_bottom() -> str:
    return styled("└" + ("─" * (BOX_WIDTH - 2)) + "┘", STYLE.border)


def box_text_lines(text: str, *styles: str) -> list[str]:
    inner_width = BOX_WIDTH - 4
    wrapped = wrap_plain(text, inner_width)
    return [box_line(styled(part, *styles) if styles else part) for part in wrapped]


def box_kv_lines(
    label: str,
    value: str,
    *,
    indent: int = 2,
    label_width: int = 16,
    label_styles: tuple[str, ...] = (),
    value_styles: tuple[str, ...] = (),
) -> list[str]:
    inner_width = BOX_WIDTH - 4
    prefix_plain = f"{' ' * indent}{label:<{label_width}} "
    continuation_plain = " " * len(prefix_plain)
    value_width = max(1, inner_width - len(prefix_plain))
    wrapped = wrap_plain(value, value_width)

    prefix = (" " * indent) + styled(f"{label:<{label_width}}", *label_styles) + " "
    lines = [box_line(prefix + styled(wrapped[0], *value_styles))]
    for part in wrapped[1:]:
        lines.append(box_line(continuation_plain + styled(part, *value_styles)))
    return lines


def render_banner(provider_key: str, provider: dict, success_message: str | None = None) -> str:
    run_command, config_command = build_commands(provider_key, provider)
    lines: list[str] = [
        box_rule(styled("Subagent Orchestration", STYLE.title, STYLE.bold)),
        *box_kv_lines(
            "Provider",
            f"{provider['display_name']} ({provider_key})",
            label_width=8,
            label_styles=(STYLE.label, STYLE.bold),
            value_styles=(STYLE.provider, STYLE.bold),
        ),
        box_line(),
        *box_text_lines("Role mappings", STYLE.accent, STYLE.bold),
    ]

    for role in ROLE_ORDER:
        model = provider["roles"][role]
        usage = ROLE_USAGE[role]
        quoted_model = f'"{model}"'
        lines.extend(
            box_kv_lines(
                role,
                quoted_model,
                label_styles=(STYLE.label,),
                value_styles=(STYLE.value, STYLE.bold),
            )
        )
        lines.extend(
            box_kv_lines(
                "used for",
                usage,
                label_styles=(STYLE.label,),
                value_styles=(STYLE.dim,),
            )
        )

    lines.extend(
        [
            box_line(),
            *box_text_lines("Commands", STYLE.accent, STYLE.bold),
            *box_kv_lines(
                "Run",
                run_command,
                label_styles=(STYLE.label,),
                value_styles=(STYLE.command,),
            ),
            *box_kv_lines(
                "Configure",
                config_command,
                label_styles=(STYLE.label,),
                value_styles=(STYLE.command,),
            ),
        ]
    )

    if success_message:
        lines.extend([box_line(), *box_text_lines(success_message, STYLE.success, STYLE.bold)])

    lines.append(box_bottom())
    return "\n".join(lines)


def print_provider_list(data: dict) -> None:
    provider_items = list(providers(data).items())
    lines = [
        box_rule(styled("Provider Selection", STYLE.title, STYLE.bold)),
        *box_text_lines("Registered LLM providers", STYLE.accent, STYLE.bold),
        box_line(),
    ]

    for idx, (provider_key, provider) in enumerate(provider_items, start=1):
        lines.extend(
            box_kv_lines(
                f"{idx}.",
                f"{provider['display_name']} ({provider_key})",
                label_width=4,
                label_styles=(STYLE.command, STYLE.bold),
                value_styles=(STYLE.provider, STYLE.bold),
            )
        )

    lines.extend(
        [
            box_line(),
            *box_kv_lines(
                "Prompt",
                "Choose provider number:",
                label_width=8,
                label_styles=(STYLE.label, STYLE.bold),
                value_styles=(STYLE.command,),
            ),
            box_bottom(),
        ]
    )
    print("\n".join(lines))


def print_mapping(provider_key: str, provider: dict) -> None:
    print(render_banner(provider_key, provider))


def interactive_config() -> int:
    data = load_config()
    all_providers = list(providers(data).items())
    print_provider_list(data)

    while True:
        raw_choice = input("Choose provider number: ").strip()
        if not raw_choice:
            print("No provider selected. Aborting.")
            return 1
        if raw_choice.isdigit():
            index = int(raw_choice)
            if 1 <= index <= len(all_providers):
                provider_key, provider = all_providers[index - 1]
                break
        print("Invalid choice. Enter one of the listed numbers.")

    print()
    print(render_banner(provider_key, provider))
    print()
    print(styled("Edit role mappings. Press Enter to keep the current value.", STYLE.accent, STYLE.bold))

    for role in ROLE_ORDER:
        current = provider["roles"][role]
        updated = input(f"{role} [{current}]: ").strip()
        if updated:
            provider["roles"][role] = updated

    all_values = [provider["roles"][role].strip() for role in ROLE_ORDER]
    if not all(all_values):
        raise SystemExit("ERROR: role mappings cannot be empty")

    save_config(data)
    print()
    print(render_banner(provider_key, provider, "Saved model mappings."))
    return 0


def usage() -> str:
    return (
        "Usage:\n"
        "  model-mapping.py list\n"
        "  model-mapping.py show <provider>\n"
        "  model-mapping.py print-banner <provider>\n"
        "  model-mapping.py interactive-config\n"
    )


def main(argv: list[str]) -> int:
    if len(argv) < 2:
        print(usage(), end="")
        return 1

    command = argv[1]
    data = load_config()

    if command == "list":
        print_provider_list(data)
        return 0

    if command in {"show", "print-banner"}:
        if len(argv) != 3:
            print(usage(), end="")
            return 1
        provider_key = argv[2]
        provider = get_provider(data, provider_key)
        print_mapping(provider_key, provider)
        return 0

    if command == "interactive-config":
        return interactive_config()

    print(usage(), end="")
    return 1


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
