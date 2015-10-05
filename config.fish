set fish_greeting ""

function __fasd_run -e fish_preexec -d "fasd takes record of the directories changed into"
	command nohup fasd --proc (command fasd --sanitize "$argv" | tr -s ' ' \n) > "/dev/null" 2>&1
end

function __fzf_escape
	while read item
		echo -n (echo -n "$item" | sed -E 's/([ "$~'\''([{<>})])/\\\\\\1/g')' '
	end
end

function __fzfcmd
	set -q FZF_TMUX; or set FZF_TMUX 1
	set -q FZF_TMUX_HEIGHT; or set FZF_TMUX_HEIGHT 40%

	if [ $FZF_TMUX -eq 1 ]
		echo "/usr/local/etc/vim/plugged/fzf/bin/fzf-tmux -d$FZF_TMUX_HEIGHT"
	else
		echo "/usr/local/etc/vim/plugged/fzf/bin/fzf"
	end
end

function find_all
	locate / | eval (__fzfcmd) +s -m > /tmp/fzf.all
	and commandline -i (cat /tmp/fzf.all | __fzf_escape)
	commandline -f repaint
end

function find_under
	set -q FZF_CTRL_T_COMMAND; or set -l FZF_CTRL_T_COMMAND "
	command find -L . \\( -path '*/\\.*' -o -fstype 'dev' -o -fstype 'proc' \\) -prune \
		-o -type f -print \
		-o -type d -print \
		-o -type l -print 2> /dev/null | sed 1d | cut -b3-"
	eval "$FZF_CTRL_T_COMMAND | "(__fzfcmd)" +s -m > /tmp/fzf.under"
	and for i in (seq 20); commandline -i (cat /tmp/fzf.under | __fzf_escape) 2> /dev/null; and break; sleep 0.1; end
	commandline -f repaint
	rm -f /tmp/fzf.under
end

function history_search
	set -q FZF_TMUX_HEIGHT; or set FZF_TMUX_HEIGHT 40%
	begin
		set -lx FZF_DEFAULT_OPTS "--height $FZF_TMUX_HEIGHT $FZF_DEFAULT_OPTS --tiebreak=index --bind=ctrl-r:toggle-sort $FZF_CTRL_R_OPTS +m"
		history | eval (__fzfcmd) -q '(commandline)' | read -l result
		and commandline -- $result
	end
	commandline -f repaint
end

function j
	fasd -Rdl "$argv[1]" | eval (__fzfcmd) -1 -0 +s +m | read -l dir
	if [ $dir ]
		cd $dir
	else
		return 1
	end
end

function v
	fasd -Rfl "$argv[1]" | eval (__fzfcmd) -1 -0 +s +m | read -l file
	if [ $file ]
		vim $file
	else
		return 1
	end
end

function jgrep
	find . -name .repo -prune -o -name .git -prune -o -name out -prune -o -type f -name "*\.java" -print0 | xargs -0 ag "$argv"
end

function cgrep
	find . -name .repo -prune -o -name .git -prune -o -name out -prune -o -type f \( -name '*.c' -o -name '*.cc' -o -name '*.cpp' -o -name '*.h' -o -name '*.hpp' \) -print0 | xargs -0 ag "$argv"
end

set -x LESS "-FRXS"

set -x MANPAGER "/bin/sh -c \"col -b | vi -MR -c 'set ft=man ts=9 nolist nonu cc=0' -\""

set -x XZ_DEFAULTS "--threads=0"

function export
	if [ $argv ]
		set var (echo $argv | cut -f1 -d=)
		set val (echo $argv | cut -f2 -d=)
		set -g -x $var $val
	else
		echo 'export var=value'
	end
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

function edit_cmd --description 'Input command in external editor'
	set -l f (mktemp /tmp/fish.cmd.XXXXXXXX)
	if test -n "$f"
		set -l p (commandline -C)
		commandline -b > $f
		vim -c 'set ft=fish' $f
		commandline -r (more $f)
		commandline -C $p
		command rm $f
	end
end

function handle_input_bash_conditional --description 'Function used for binding to replace && and ||'
	# This function is expected to be called with a single argument of either & or |
	# The argument indicates which key was pressed to invoke this function
	if begin; commandline --search-mode; or commandline --paging-mode; end
		# search or paging mode; use normal behavior
		commandline -i $argv[1]
		return
	end
	# is our cursor positioned after a '&'/'|'?
	switch (commandline -c)[-1]
	case \*$argv[1]
		# experimentally, `commandline -t` only prints string-type tokens,
		# so it prints nothing for the background operator. We need -c as well
		# so if the cursor is after & in `&wat` it doesn't print "wat".
		if test -z (commandline -c -t)[-1]
			# Ideally we'd just emit a backspace and then insert the text
			# but injected readline functions run after any commandline modifications.
			# So instead we have to build the new commandline
			#
			# NB: We could really use some string manipulation operators and some basic math support.
			# The `math` function is actually a wrawpper around `bc` which is kind of terrible.
			# Instead we're going to use `expr`, which is a bit lighter-weight.

			# get the cursor position
			set -l count (commandline -C)
			# calculate count-1 and count+1 to give to `cut`
			set -l prefix (expr $count - 1)
			set -l suffix (expr $count + 1)
			# cut doesn't like 1-0 so we need to special-case that
			set -l cutlist 1-$prefix,$suffix-
			if test "$prefix" = 0
				set cutlist $suffix-
			end
			commandline (commandline | cut -c $cutlist)
			commandline -C $prefix
			if test $argv[1] = '&'
				commandline -i '; and '
			else
				commandline -i '; or '
			end
			return
		end
	end
	# no special behavior, insert the character
	commandline -i $argv[1]
end

function fish_user_key_bindings
	bind \ev 'edit_cmd'
	bind \cr 'history_search'
	bind \cp 'find_under'
	bind \ct 'find_all'
	bind \& 'handle_input_bash_conditional \&'
	bind \| 'handle_input_bash_conditional \|'
end

if status --is-interactive; bash /usr/local/etc/vim/plugged/gruvbox/gruvbox_256palette.sh; end
