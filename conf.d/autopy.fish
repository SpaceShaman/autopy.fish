
function autopy --on-variable PWD
  if is_venv_active && is_child_dir
    return
  end

  set project_dir (get_project_dir)

  if is_venv_active && is_old_venv_active $project_dir
    deactivate_venv
  end

  set venv_dir (get_venv_dir $project_dir)

  if test -z "$venv_dir"
    return
  end

  if is_venv_active
    if is_outside_venv $venv_dir
      deactivate_venv
    end
    return
  end

  if test -n "$venv_dir"
    activate_venv $venv_dir $project_dir
  end
end

function is_venv_active
  set python_bin (command which python)
  test "$python_bin" = "$VIRTUAL_ENV/bin/python"
end

function is_child_dir
  if test -n "$OLD_PROJECT_DIR"
    switch $PWD
      case $OLD_PROJECT_DIR\*
        return 0
      case \*
        return 1
    end
  else
  end
end

function get_project_dir
  if is_git_repo
    command git rev-parse --show-toplevel
  else
    pwd
  end
end

function get_venv_dir -a project_dir
  if is_poetry_project $project_dir
    set venv_dir (command poetry show -v 2> /dev/null | grep 'Using virtualenv:' | cut -d ' ' -f 3)
  else
    set -l venv_dir_names env .env venv .venv
    set venv_dir ""
    for name in $venv_dir_names
      if test -e "$project_dir/$name/bin/activate.fish"
        set venv_dir "$project_dir/$name"
        break
      end
    end
  end
  echo $venv_dir
end

function is_git_repo
  command git rev-parse --show-toplevel &>/dev/null
end

function is_poetry_project -a dir
  command -q poetry && test -e "$dir/pyproject.toml"
end


function is_outside_venv -a dir
  test "$VIRTUAL_ENV" != "$dir"
end

function is_old_venv_active -a dir
  test "$OLD_PROJECT_DIR" != "$dir"
end

function activate_venv -a venv_dir project_dir
  source "$venv_dir/bin/activate.fish"
  set -gx OLD_PROJECT_DIR $project_dir
end

function deactivate_venv
  deactivate
  set -gx OLD_PROJECT_DIR ""
end

