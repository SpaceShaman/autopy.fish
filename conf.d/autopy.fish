function _autopy --on-event fish_prompt --on-event chpwd --on-variable PWD
  # Don't run during command substitutions (prevents transient toggles).
  status --is-command-substitution; and return

  # If user manually deactivated inside this project, skip re-activation
  # until they leave and re-enter the project.
  if test -n "$AUTOPY_IGNORE_PROJECT_DIR"
    set -l ignore_dir (_autopy_resolve_path $AUTOPY_IGNORE_PROJECT_DIR)
    set -l proj_dir (_autopy_resolve_path (_autopy_get_project_dir))
    if test "$ignore_dir" = "$proj_dir"
      # Still in the same project the user manually deactivated in;
      # keep the ignore marker until they leave the project.
      return
    else
      # They've left the project; clear the ignore marker and continue.
      set -e AUTOPY_IGNORE_PROJECT_DIR
    end
  end
  # If we have an active autopy-managed venv but the current directory
  # is no longer inside that project tree, deactivate the venv.
  if _autopy_is_venv_active
    if test -n "$AUTOPY_OLD_PROJECT_DIR" && not _autopy_is_child_dir
      _autopy_deactivate_venv
      return
    end
  end

    if _autopy_is_old_venv_deleted
    _autopy_deactivate_venv
  end
  
  if _autopy_is_venv_active
    if _autopy_is_child_dir || not _autopy_is_inside_autopy_venv
      return
    end
  end

  set project_dir (_autopy_get_project_dir)

  if _autopy_is_venv_active && _autopy_is_old_venv_active $project_dir
    _autopy_deactivate_venv
  end

  set venv_dir (_autopy_get_venv_dir $project_dir)

  if test -z "$venv_dir"
    return
  end

  if _autopy_is_venv_active
    if _autopy_is_outside_venv $venv_dir
      _autopy_deactivate_venv
    end
    return
  end

  if test -n "$venv_dir"
    _autopy_activate_venv $venv_dir $project_dir
  end
end

function _autopy_is_venv_active
  test "$(type --path python3)" = "$VIRTUAL_ENV/bin/python3"
end

function _autopy_resolve_path -a p
  # Return a canonical absolute path for reliable comparisons.
  if test -z "$p"
    return 1
  end
  if type -q realpath
    realpath -- "$p"
    return
  end
  if type -q readlink
    readlink -f -- "$p"
    return
  end
  if type -q python3
    python3 -c 'import os,sys; print(os.path.realpath(sys.argv[1]))' -- "$p"
    return
  end
  # Fallback: return the original path (non-canonical).
  printf '%s' "$p"
end

function _autopy_is_child_dir
  if test -n "$AUTOPY_OLD_PROJECT_DIR"
    set -l cur (_autopy_resolve_path $PWD)
    set -l old (_autopy_resolve_path $AUTOPY_OLD_PROJECT_DIR)
    switch $cur
    case $old\*
      return 0
    case \*
      return 1
    end
  end
end

function _autopy_get_project_dir
  set dir (pwd -P)
  if _autopy_is_poetry_project $dir
    echo $dir
  else if _autopy_is_git_repo
    command git rev-parse --show-toplevel
  else
    echo $dir
  end
end

function _autopy_get_venv_dir -a project_dir
  if _autopy_is_poetry_project $project_dir
    if type -q poetry
      set venv_dir (poetry env info --path 2>/dev/null)
    end
  else
    set venv_dir ""
    set venv_dir_names env .env venv .venv
    for name in $venv_dir_names
      if test -e "$project_dir/$name/bin/activate.fish"
        set venv_dir "$project_dir/$name"
        break
      end
    end
  end
  echo $venv_dir
end

function _autopy_is_git_repo
  command git rev-parse --show-toplevel &>/dev/null
end

function _autopy_is_poetry_project -a dir
  if test -e "$dir/pyproject.toml"
    grep -q '^\[tool.poetry\]' "$dir/pyproject.toml"
  else
    return 1
  end
end

function _autopy_is_inside_autopy_venv
  if test -z "$AUTOPY_OLD_VENV_DIR"
    return 1
  end
  set -l old_venv (_autopy_resolve_path $AUTOPY_OLD_VENV_DIR)
  set -l cur_venv (_autopy_resolve_path $VIRTUAL_ENV)
  test -n "$AUTOPY_OLD_PROJECT_DIR" -a "$old_venv" = "$cur_venv"
end

function _autopy_is_outside_venv -a dir
  set -l cur_venv (_autopy_resolve_path $VIRTUAL_ENV)
  set -l other (_autopy_resolve_path $dir)
  test "$cur_venv" != "$other"
end

function _autopy_is_old_venv_active -a dir
  set -l old (_autopy_resolve_path $AUTOPY_OLD_PROJECT_DIR)
  set -l new (_autopy_resolve_path $dir)
  test "$old" != "$new"
end

function _autopy_is_old_venv_deleted
  test -n "$AUTOPY_OLD_PROJECT_DIR" -a ! -e "$AUTOPY_OLD_VENV_DIR/bin/activate.fish"
end

function _autopy_activate_venv -a venv_dir project_dir
  # Save the current PATH so we can restore it on deactivate
  set -gx AUTOPY_OLD_PATH $PATH

  source "$venv_dir/bin/activate.fish"
  # Preserve any deactivate function the venv provided by copying it
  # to an internal name, then install a wrapper that calls it and
  # performs autopy cleanup and project-ignore behavior.
  if functions -q deactivate
    # Copy the original deactivate only if we haven't already stored it
    # and the current `deactivate` doesn't look like autopy's wrapper.
    if not functions -q __autopy_inner_deactivate
      functions deactivate | string match -q '*AUTOPY_IGNORE_PROJECT_DIR*'
      if test $status -ne 0
        functions -c deactivate __autopy_inner_deactivate
      end
    end
  end

  # Record the venv/project so autopy can track and deactivate later
  set -gx AUTOPY_OLD_VENV_DIR (_autopy_resolve_path $venv_dir)
  set -gx AUTOPY_OLD_PROJECT_DIR (_autopy_resolve_path $project_dir)

  function deactivate
    # Call the original venv's deactivate if it existed.
    if functions -q __autopy_inner_deactivate
      # Backup this wrapper so we can restore it if the inner
      # deactivate removes `deactivate` (some venv scripts remove
      # the function when called).
      functions -q deactivate; and functions -c deactivate __autopy_wrapper_backup
      # Install a temporary no-op `deactivate` to absorb any removal.
      function deactivate; end
      # Call the original inner deactivate (may remove the temp stub).
      __autopy_inner_deactivate
      # If `deactivate` was removed, restore our wrapper from backup.
      if not functions -q deactivate
        functions -q __autopy_wrapper_backup; and functions -c __autopy_wrapper_backup deactivate
      end
      # Clean up the backup if it exists.
      functions -q __autopy_wrapper_backup; and functions -e __autopy_wrapper_backup
    end

    # Restore PATH if we saved one.
    if test -n "$AUTOPY_OLD_PATH"
      set -gx PATH $AUTOPY_OLD_PATH
      set -e AUTOPY_OLD_PATH
    end

    # Capture the old project dir before clearing env so we can set
    # a project-scoped ignore marker to prevent immediate re-activation.
    set -l _saved_autopy_old_project_dir $AUTOPY_OLD_PROJECT_DIR

    # Ensure env vars are cleaned up.
    set -e VIRTUAL_ENV
    set -e AUTOPY_OLD_VENV_DIR
    set -e AUTOPY_OLD_PROJECT_DIR

    # Prevent autopy from immediately re-activating on the next prompt
    # but do not set this flag when autopy itself initiated the deactivate.
      if test -z "$AUTOPY_INTERNAL_DEACTIVATE"
        # Remember the project the user manually deactivated in so we
        # don't auto-reactivate until they leave and come back.
        if test -n "$_saved_autopy_old_project_dir"
          set -gx AUTOPY_IGNORE_PROJECT_DIR (_autopy_resolve_path $_saved_autopy_old_project_dir)
        else
          set -gx AUTOPY_IGNORE_PROJECT_DIR (_autopy_resolve_path (_autopy_get_project_dir))
        end
      end
  end
end

function _autopy_deactivate_venv
  # Indicate this is an autopy-initiated deactivate so the wrapper
  # doesn't set the manual-ignore flag.
  set -gx AUTOPY_INTERNAL_DEACTIVATE 1
  functions -q deactivate; and deactivate
  set -e AUTOPY_INTERNAL_DEACTIVATE
  set -e AUTOPY_OLD_VENV_DIR
  set -e AUTOPY_OLD_PROJECT_DIR
end

# Safe manual deactivation helper in case `deactivate` is unavailable.
function autopy-deactivate
  # Call the original venv deactivate if present
  if functions -q __autopy_inner_deactivate
    __autopy_inner_deactivate
  end
  if test -n "$AUTOPY_OLD_PATH"
    set -gx PATH $AUTOPY_OLD_PATH
    set -e AUTOPY_OLD_PATH
  end

  # Capture project dir before clearing so we can set the ignore marker.
  set -l _saved_autopy_old_project_dir $AUTOPY_OLD_PROJECT_DIR

  set -e VIRTUAL_ENV
  set -e AUTOPY_OLD_VENV_DIR
  set -e AUTOPY_OLD_PROJECT_DIR

  # Prevent immediate re-activation until user leaves project
  if test -n "$_saved_autopy_old_project_dir"
    set -gx AUTOPY_IGNORE_PROJECT_DIR (_autopy_resolve_path $_saved_autopy_old_project_dir)
  else
    set -gx AUTOPY_IGNORE_PROJECT_DIR 1
  end
end

# Ensure a `deactivate` command exists: if none is present, provide a
# lightweight one that calls the venv's original `__autopy_inner_deactivate`
# when available, otherwise falls back to `autopy-deactivate`.
if not functions -q deactivate
  function deactivate
    if functions -q __autopy_inner_deactivate
      __autopy_inner_deactivate
      return
    end
    autopy-deactivate
  end
end

