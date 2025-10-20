# autopy.fish

A [Fish Shell](https://fishshell.com/) plugin that automatically activates a Python virtual environment ([venv](https://docs.python.org/3/library/venv.html), [UV](https://docs.astral.sh/uv/) or [Poetry](https://python-poetry.org/)) when you `cd` into a project directory. If another environment was previously activated by `autopy.fish`, it will be deactivated.

If a virtual environment is activated by other means (e.g. by explicitly running `source {venv_path}/bin/activate.fish`), `autopy.fish` will do nothing until this environment is deactivated.

## Features

- 🔁 Auto-activation of [venv](https://docs.python.org/3/library/venv.html), [UV](https://docs.astral.sh/uv/) or [Poetry](https://python-poetry.org/) environments
- 🔻 Automatic deactivation of previously active environments
- 🐟 Lightweight and runs on every directory change
- 🧠 Detects `.venv` or `pyproject.toml` in project root
- 🐙 Supports Git repositories (uses repo root as project dir)

## Installation

### With [Fisher](https://github.com/jorgebucaran/fisher)

```fish
fisher install SpaceShaman/autopy.fish
```

### With [reef](https://github.com/danielb2/reef)

```fish
reef install SpaceShaman/autoenv.fish
```

### Manually

Copy `autopy.fish` to your `~/.config/fish/conf.d/` directory.
