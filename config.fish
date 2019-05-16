set -x MENUCONFIG_COLOR classic
set -x LESS "-FRXS"
set -x XZ_DEFAULTS "--threads=0"
if set -q TMUX
  set -x fzf /usr/local/etc/vim/plugged/fzf/bin/fzf-tmux -d40%
else
  set -x fzf /usr/local/etc/vim/plugged/fzf/bin/fzf
end
alias vi nvim

function __fasd_run -e fish_preexec -d "fasd takes record of the directories changed into"
	command nohup fasd --proc (command fasd --sanitize "$argv" | tr -s ' ' \n) > "/dev/null" 2>&1
end

function __fzf_from_command -d "fzf pickup result from command"
  eval "$argv | $fzf -m" | while read -l r; set result $result $r; end
  if [ -z "$result" ]
    commandline -f repaint
    return
  else
    # Remove last token from commandline.
    commandline -t ""
  end
  for i in $result
    commandline -it -- (string escape $i)
    commandline -it -- ' '
  end
  commandline -f repaint
end

function __fzf-history-widget -d "Show command history"
  begin
    set -l FISH_MAJOR (echo $FISH_VERSION | cut -f1 -d.)
    set -l FISH_MINOR (echo $FISH_VERSION | cut -f2 -d.)
    set -lx FZF_DEFAULT_OPTS "--tiebreak=index --bind=ctrl-r:toggle-sort +m"

    # history's -z flag is needed for multi-line support.
    # history's -z flag was added in fish 2.4.0, so don't use it for versions
    # before 2.4.0.
    if [ "$FISH_MAJOR" -gt 2 -o \( "$FISH_MAJOR" -eq 2 -a "$FISH_MINOR" -ge 4 \) ];
      history -z | eval $fzf --read0 -q '(commandline)' | perl -pe 'chomp if eof' | read -lz result
      and commandline -- $result
    else
      history | eval $fzf -q '(commandline)' | read -l result
      and commandline -- $result
    end
  end
  commandline -f repaint
end

function __fzf-history-path -d "History path from fasd"
	__fzf_from_command "fasd -Rla"
end

function __fzf-file-widget -d "List all files and folders"
  function __fzf_parse_commandline -d 'Parse the current command line token and return split of existing filepath and rest of token'
    # eval is used to do shell expansion on paths
    set -l commandline (eval "printf '%s' "(commandline -t))

    if [ -z $commandline ]
      set dir '.'
    else
      set dir (__fzf_get_dir $commandline)
    end

    echo $dir
  end

  function __fzf_get_dir -d 'Find the longest existing filepath from input string'
    set dir $argv

    # Strip all trailing slashes. Ignore if $dir is root dir (/)
    if [ (string length $dir) -gt 1 ]
      set dir (string replace -r '/*$' '' $dir)
    end

    # Iteratively check if dir exists and strip tail end of path
    while [ ! -d "$dir" ]
      # If path is absolute, this can keep going until ends up at /
      # If path is relative, this can keep going until entire input is consumed, dirname returns "."
      set dir (dirname "$dir")
    end

    echo $dir
  end

  set -l dir (__fzf_parse_commandline)

  # "-path \$dir'*/\\.*'" matches hidden files/folders inside $dir but not
  # $dir itself, even if hidden.
  set FZF_CTRL_T_COMMAND "
  command find -L \$dir -mindepth 1 \\( -path \$dir'*/\\.*' -o -fstype 'sysfs' -o -fstype 'devfs' -o -fstype 'devtmpfs' \\) -prune \
  -o -type f -print \
  -o -type d -print \
  -o -type l -print 2> /dev/null | sed 's@^\./@@'"
  __fzf_from_command $FZF_CTRL_T_COMMAND
end

function __edit_cmd -d 'Edit command in Vim'
	set -l f (mktemp /tmp/fish.cmd.XXXXXXXX)
	if test -n "$f"
		set -l p (commandline -C)
		commandline -b > $f
		vi -c 'set ft=fish' $f
		commandline -r (more $f)
		commandline -C $p
		command rm $f
	end
end

function __chdir -d "Change directory"
	fasd -Rld (commandline -b) | eval $fzf -1 -0 +s +m | read -l result
	if [ -n "$result" ]
		cd $result
		commandline -r ""
		commandline -f repaint
	else
		return 1
	end
end

function __vim_edit -d "Vim"
	fasd -Rlf (commandline -b) | eval $fzf -1 -0 +s +m | read -l result
	if [ -n "$result" ]
		vi $result
		commandline -r ""
		commandline -f repaint
	else
		return 1
	end
end

function fish_user_key_bindings
	bind \ee __edit_cmd
	bind \ec __chdir
	bind \ev __vim_edit
	bind \ct __fzf-file-widget
	bind \cp __fzf-history-path
	bind \cr __fzf-history-widget

	if bind -M insert > /dev/null 2>&1
		bind -M insert \ee __edit_cmd
		bind -M insert \ec __chdir
		bind -M insert \ev __vim_edit
		bind -M insert \ct __fzf-file-widget
		bind -M insert \ct __fzf-history-path
		bind -M insert \cr __fzf-history-widget
	end
end

function pbcopy -d "Copy data from STDIN to the clipboard"
	xclip -in -sel clip
end

function pbpaste -d "Paste data from the Clipboard"
	xclip -out -sel clip
end

function jgrep
	find . -name .repo -prune -o -name .git -prune -o -name out -prune -o -type f -name "*\.java" -print0 | xargs -0 ag "$argv"
end

function cgrep
	find . -name .repo -prune -o -name .git -prune -o -name out -prune -o -type f \( -name '*.c' -o -name '*.cc' -o -name '*.cpp' -o -name '*.h' -o -name '*.hpp' \) -print0 | xargs -0 ag "$argv"
end

function plz -d "sudo the last command in history"
  echo sudo $history[1]
  eval command sudo -k $history[1]
end

function fish_prompt --description 'Write out the prompt'
	set -l last_status $status

	if not set -q __fish_prompt_normal
		set -g __fish_prompt_normal (set_color normal)
	end

	# PWD
	set_color $fish_color_cwd
	echo -n (prompt_pwd)
	set_color normal

	printf '%s ' (__fish_git_prompt)

	if not test $last_status -eq 0
	set_color $fish_color_error
	end

	echo -n '$ '

	set_color normal
end
