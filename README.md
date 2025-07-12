# autopy.fish

A Fish Shell plugin that automatically activates a Python virtual environment (venv or Poetry) when you `cd` into a project directory. If another environment is already active, it will be deactivated.

## Features

- 🔁 Auto-activation of `venv` or Poetry environments
- 🔻 Automatic deactivation of previously active environments
- 🐟 Lightweight and runs on every directory change
- 🧠 Detects `.venv` or `pyproject.toml` in project root
- 🐙 Supports Git repositories (uses repo root as project dir)

## Installation

### With [Fisher](https://github.com/jorgebucaran/fisher)

```fish
fisher install SpaceShaman/autopy.fish

