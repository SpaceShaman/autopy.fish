function autopy
  if _autopy_is_old_venv_deleted
    echo "deactivate"
    return
  end

  if _autopy_is_venv_active
    if _autopy_is_child_dir || not _autopy_is_inside_autopy_venv
      return
    end
  end

  set project_dir (_autopy_get_project_dir)

  if _autopy_is_venv_active && _autopy_is_old_venv_active $project_dir
    echo "deactivate"
    return
  end

  set venv_dir (_autopy_get_venv_dir $project_dir)

  if test -z "$venv_dir"
    return
  end

  if _autopy_is_venv_active
    if _autopy_is_outside_venv $venv_dir
      echo "deactivate"
    end
    return
  end

  if test -n "$venv_dir"
    echo "activate '$venv_dir' '$project_dir'"
  end
end

function _autopy_sync_clean_file --on-event fish_prompt
  set tmpfile (_autopy_async_file)
  if test -e $tmpfile
    rm $tmpfile
  end
end

function _autopy_async --on-signal SIGUSR1
  set tmpfile (_autopy_async_file)
  if test -e $tmpfile
    _autopy_exec (cat $tmpfile)
  end
end

function _autopy_exec -a command
  switch $command
  case "activate*"
    set parts (string split ' ' $command)
    set venv_dir (string trim --chars="'" $parts[2])
    set project_dir (string trim --chars="'" $parts[3])
    _autopy_activate_venv $venv_dir $project_dir
  case "deactivate"
    _autopy_deactivate_venv
  end
end

function _autopy_async_file
  echo $__async_prompt_tmpdir'/'$fish_pid'_'autopy
end

function _autopy_is_venv_active
  test "$(type --path python3)" = "$VIRTUAL_ENV/bin/python3"
end

function _autopy_is_child_dir
  if test -n "$AUTOPY_OLD_PROJECT_DIR"
    switch $PWD
    case $AUTOPY_OLD_PROJECT_DIR\*
      return 0
    case \*
      return 1
    end
  end
end

function _autopy_get_project_dir
  set dir (pwd)
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
  test -n "$AUTOPY_OLD_PROJECT_DIR" -a "$AUTOPY_OLD_VENV_DIR" = "$VIRTUAL_ENV"
end

function _autopy_is_outside_venv -a dir
  test "$VIRTUAL_ENV" != "$dir"
end

function _autopy_is_old_venv_active -a dir
  test "$AUTOPY_OLD_PROJECT_DIR" != "$dir"
end

function _autopy_is_old_venv_deleted
  test -n "$AUTOPY_OLD_PROJECT_DIR" -a ! -e "$AUTOPY_OLD_VENV_DIR/bin/activate.fish"
end

function _autopy_activate_venv -a venv_dir project_dir
  source "$venv_dir/bin/activate.fish"
  set -gx AUTOPY_OLD_VENV_DIR $venv_dir
  set -gx AUTOPY_OLD_PROJECT_DIR $project_dir
end

function _autopy_deactivate_venv
  functions -q deactivate; and deactivate
  set -e AUTOPY_OLD_VENV_DIR
  set -e AUTOPY_OLD_PROJECT_DIR
end
