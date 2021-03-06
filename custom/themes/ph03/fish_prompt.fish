# name: ph03
#
# ph03 is a Powerline-style, Git-aware fish theme optimized for awesome.
#
# You will probably need a Powerline-patched font for this to work:
#
#     https://powerline.readthedocs.org/en/latest/fontpatching.html
#
# I recommend picking one of these:
#
#     https://github.com/Lokaltog/powerline-fonts
#
# You can override some default options in your config.fish:
#
#     set -g theme_display_user yes
#     set -g default_user your_normal_user

set -g current_bg NONE

# Powerline glyphs
set branch_glyph            \uE0A0
set ln_glyph                \uE0A1
set padlock_glyph           \uE0A2
set right_black_arrow_glyph \uE0B0
set right_arrow_glyph       \uE0B1
set left_black_arrow_glyph  \uE0B2
set left_arrow_glyph        \uE0B3

# Additional glyphs
set detached_glyph          \u27A6
set nonzero_exit_glyph      '! '
set superuser_glyph         '$ '
set bg_job_glyph            '% '

# Colors
set lt_green   9ec90f
set med_green  189303
set dk_green   0c4801

set lt_red     C99
set med_red    ac000c
set dk_red     600

set slate_blue 255e87

set lt_orange  cc7013
set dk_orange  3a2a03

set dk_grey    333
set med_grey   999
set lt_grey    ccc

# ===========================
# Helper methods
# ===========================

function __ph03_in_git
  command git rev-parse --is-inside-work-tree >/dev/null 2>&1
end

function __ph03_git_branch
  set -l ref (command git symbolic-ref HEAD 2> /dev/null)
  if [ $status -gt 0 ]
    set -l branch (command git show-ref --head -s --abbrev |head -n1 2> /dev/null)
    set ref "$detached_glyph $branch"
  end
  echo $ref | sed  "s-refs/heads/-$branch_glyph -"
end

function __ph03_pretty_parent -d 'Print a parent directory, shortened to fit the prompt'
  echo -n (dirname $argv[1]) | sed -e 's|/private||' -e "s|^$HOME|~|" -e 's-/\(\.\{0,1\}[^/]\)\([^/]*\)-/\1-g' -e 's|/$||'
end

function __ph03_project_dir -d 'Print the current git project base directory'
  command git rev-parse --show-toplevel 2>/dev/null
end

function __ph03_project_pwd -d 'Print the working directory relative to project root'
  set -l base_dir (__ph03_project_dir)
  echo "$PWD" | sed -e "s*$base_dir**g" -e 's*^/**'
end


# ===========================
# Segment functions
# ===========================

function __ph03_start_segment -d 'Start a segment'
  set_color -b $argv[1]
  set_color $argv[2]
  if [ "$current_bg" = 'NONE' ]
    # If there's no background, just start one
    echo -n ' '
  else
    # If there's already a background...
    if [ "$argv[1]" = "$current_bg" ]
      # and it's the same color, draw a separator
      echo -n "$right_arrow_glyph "
    else
      # otherwise, draw the end of the previous segment and the start of the next
      set_color $current_bg
      echo -n "$right_black_arrow_glyph "
      set_color $argv[2]
    end
  end
  set current_bg $argv[1]
end

function __ph03_path_segment -d 'Display a shortened form of a directory'
  if test -w "$argv[1]"
    __ph03_start_segment $dk_grey $med_grey
  else
    __ph03_start_segment $dk_red $lt_red
  end

  set -l directory
  set -l parent

  switch "$argv[1]"
    case /
      set directory '/'
    case "$HOME"
      set directory '~'
    case '*'
      set parent    (__ph03_pretty_parent "$argv[1]")
      set parent    "$parent/"
      set directory (basename "$argv[1]")
  end

  test "$parent"; and echo -n -s "$parent"
  set_color fff --bold
  echo -n "$directory "
  set_color normal
end

function __ph03_finish_segments -d 'Close open segments'
  if [ -n $current_bg -a $current_bg != 'NONE' ]
    set_color -b normal
    set_color $current_bg
    echo -n "$right_black_arrow_glyph "
    set_color normal
  end
  set -g current_bg NONE
end


# ===========================
# Theme components
# ===========================

function __ph03_prompt_status -d 'the symbols for a non zero exit status, root and background jobs'
  set -l nonzero
  set -l superuser
  set -l bg_jobs

  # Last exit was nonzero
  if [ $RETVAL -ne 0 ]
    set nonzero $nonzero_exit_glyph
  end

  # if superuser (uid == 0)
  set -l uid (id -u $USER)
  if [ $uid -eq 0 ]
    set superuser $superuser_glyph
  end

  # Jobs display
  if [ (jobs -l | wc -l) -gt 0 ]
    set bg_jobs $bg_job_glyph
  end

  set -l status_flags "$nonzero$superuser$bg_jobs"

  if test "$nonzero" -o "$superuser" -o "$bg_jobs"
    __ph03_start_segment fff 000
    if [ "$nonzero" ]
      set_color $med_red --bold
      echo -n $nonzero_exit_glyph
    end

    if [ "$superuser" ]
      set_color $med_green --bold
      echo -n $superuser_glyph
    end

    if [ "$bg_jobs" ]
      set_color $slate_blue --bold
      echo -n $bg_job_glyph
    end
  end
end

function __ph03_prompt_user -d 'Display actual user if different from $default_user'
  if [ "$theme_display_user" = 'yes' ]
    if [ "$USER" != "$default_user" -o -n "$SSH_CLIENT" ]
      __ph03_start_segment $lt_grey $slate_blue
      echo -n -s (whoami) '@' (hostname | cut -d . -f 1) ' '
    end
  end
end

# TODO: clean up the fugly $ahead business
function __ph03_prompt_git -d 'Display the actual git state'
  set -l dirty   (command git diff --no-ext-diff --quiet --exit-code; or echo -n '*'(command git status --porcelain 2>/dev/null| grep "^[ MARC][MD]" | wc -l)' ')
  set -l staged  (command git diff --cached --no-ext-diff --quiet --exit-code; or echo -n '+'(command git status --porcelain 2>/dev/null| grep "^[MARDC]" | wc -l)' ')
  set -l stashed (command git rev-parse --verify refs/stash > /dev/null 2>&1; and echo -n '$ ')
  set -l aheadnum   (command git rev-list @\{u\}..HEAD 2>&1 | wc -l)
  set -l behinddnum (command git rev-list HEAD..@\{u\} 2>&1 | wc -l)
  set -l ahead   (command git branch -v 2> /dev/null | grep -Eo '^\* [^ ]* *[^ ]* *\[[^]]*\]' | grep -Eo '\[[^]]*\]$' | awk 'ORS="";/ahead/ {print "↑"} /behind/ {print "↓"}' | sed -e "s/↑/↑$aheadnum/" | sed -e "s/↓/↓$behinddnum/")
  test "$ahead"; and set ahead $ahead' '

  set -l new (command git ls-files --other --exclude-standard);
  test "$new"; and set new '…'(command git status --porcelain 2>/dev/null | grep "^??" | wc -l)' '

  set -l flags (command echo "$ahead$staged$dirty$stashed$new" | sed 's/[ \t]*$//')
  test "$flags"; and set flags " $flags"

  set -l flag_bg $med_green
  set -l flag_fg $dk_orange
  if test "$dirty" -o "$staged"
    set flag_bg $med_red
    set flag_fg $dk_orange
  else
    if test "$stashed"
      set flag_bg $lt_orange
      set flag_fg $dk_orange
    end
  end

  __ph03_path_segment (__ph03_project_dir)

  __ph03_start_segment $flag_bg $flag_fg
  set_color $flag_fg --bold
  echo -n -s (__ph03_git_branch) $flags ' '
  set_color normal

  set -l project_pwd  (__ph03_project_pwd)
  if test "$project_pwd"
    if test -w "$PWD"
      __ph03_start_segment 333 999
    else
      __ph03_start_segment $med_red $lt_red
    end

    echo -n -s $project_pwd ' '
  end
end

function __ph03_prompt_dir -d 'Display a shortened form of the current directory'
  __ph03_path_segment "$PWD"
end

function __ph03_svn_prompt
    if svn info>/dev/null 2>&1
        __ph03_start_segment $med_green $dk_orange
        set_color $dk_orange --bold
        printf 'svn %s ' (svn info 2>&1 | sed -n -e '/^Revision: \([0-9]*\).*$/s//\1/p')
    end
end

function __ph03_hg_prompt
    if hg root >/dev/null 2>&1
        __ph03_start_segment $med_green $dk_orange
        set_color $dk_orange --bold
        printf '\u263F %s ' (hg branch ^/dev/null)
    end
end

# ===========================
# Apply theme
# ===========================

function fish_prompt
  set -g RETVAL $status
  __ph03_prompt_status
  __ph03_prompt_user
  if __ph03_in_git
    __ph03_prompt_git
  else
    __ph03_prompt_dir
    __ph03_svn_prompt
    __ph03_hg_prompt
  end
  __ph03_finish_segments
end
