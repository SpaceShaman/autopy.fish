# autopy.fish

A [Fish Shell](https://fishshell.com/) plugin that automatically activates a Python virtual environment ([venv](https://docs.python.org/3/library/venv.html) or [Poetry](https://python-poetry.org/)) when you `cd` into a project directory. If another environment is already active, it will be deactivated.

## Features

- 🔁 Auto-activation of [venv](https://docs.python.org/3/library/venv.html) or [Poetry](https://python-poetry.org/) environments
- 🔻 Automatic deactivation of previously active environments
- 🐟 Lightweight and runs on every directory change
- 🧠 Detects `.venv` or `pyproject.toml` in project root
- 🐙 Supports Git repositories (uses repo root as project dir)

## Installation

### With [Fisher](https://github.com/jorgebucaran/fisher)

```fish
fisher install SpaceShaman/autopy.fish
```

### With [reff](https://github.com/danielb2/reef)

```fish
reff install SpaceShaman/autoenv.fish
```

### Manually

Copy `autopy.fish` to your `~/.config/fish/conf.d/` directory.

## Usage tip

If you want the virtual environment to be activated automatically every time you start a new shell (even in terminals spawned from within other tools like Vim), add the following line to your `config.fish`:

```fish
autopy
```

This ensures the environment is activated right after shell startup, not just when changing directories.

