#!/usr/bin/env bash
# Contributed by @quinkennedy (https://gist.github.com/quinkennedy/fc78c2bb1d6b1e27c174)
{ # this ensures the entire script is downloaded #

openframe_has() {
  type "$1" > /dev/null 2>&1
}

if [ -z "$OPENFRAME_DIR" ]; then
  OPENFRAME_DIR="$HOME/.openframe"
fi

openframe_edit_or_add() {
  if grep -q "^$2" $1; then
    sudo bash -c "sed -i 's/^$2.*/$2$3/g' $1"
  else
    sudo bash -c "echo $2$3 >> $1"
  fi
}

openframe_download() {
  if openframe_has "curl"; then
    curl -q $*
  elif openframe_has "wget"; then
    # Emulate curl with wget
    ARGS=$(echo "$*" | command sed -e 's/--progress-bar /--progress=bar /' \
                           -e 's/-L //' \
                           -e 's/-I /--server-response /' \
                           -e 's/-s /-q /' \
                           -e 's/-o /-O /' \
                           -e 's/-C - /-c /')
    wget $ARGS
  fi
}

openframe_do_rotate() {
  echo "how much have you rotated it?"
  echo "enter '0' for no rotation"
  echo "'1' if you rotated your physical screen 90 degrees clockwise"
  echo "'2' for 180 degrees (upside down)"
  echo "'3' for 270 degrees (90 degrees counter-clockwise)"
  read ANSWER
  if [ "$ANSWER" -ge 0 -a "$ANSWER" -le 3 ]; then
    openframe_edit_or_add /boot/config.txt display_rotate= $ANSWER
  else
    echo "input not recognised, must be a number between 0 and 3"
    openframe_ask_rotate
  fi
}

openframe_ask_rotate() {
  echo "have you rotated your screen from default (normally landscape)? (y/n)"
  read ANSWER
  ANSWER="$(echo $ANSWER | tr '[:upper:]' '[:lower:]')"
  if [ "$ANSWER" == "y" ] || [ "$ANSWER" == "yes" ]; then
    openframe_do_rotate
  elif [ "$ANSWER" == "n" ] || [ "$ANSWER" == "no" ]; then
    :
  else
    echo "input not recognised, must be yes or no"
    openframe_ask_rotate
  fi
}

openframe_do_install() {
  # install NVM for easy node version management
  openframe_download https://raw.githubusercontent.com/creationix/nvm/v0.33.0/install.sh | bash
  # source nvm to access it in the shell
  # usually it is sourced in .bashrc,
  # but we can't reload .bashrc within a script
  echo "source nvm"
  . ~/.nvm/nvm.sh
  # install Node.js 4.3
  echo "install node"
  nvm install 6.9
  nvm alias default 6.9

  # disable terminal screen blanking
  openframe_edit_or_add ~/.bashrc "setterm -powersave off -blank 0"

  # disable screensaver
  echo "install server utils"
  sudo apt-get install x11-xserver-utils

  # let anybody use xinit
  openframe_edit_or_add /etc/X11/Xwrapper.config "allowed_users" "=anybody"

  # echo "disable screensaver"
  # TODO - this doesn't actually have the desired effect, and breaks startx
  #touch ~/.xinitrc
  #openframe_edit_or_add ~/.xinitrc "xset s off"
  #openframe_edit_or_add ~/.xinitrc "xset -dpms"
  #openframe_edit_or_add ~/.xinitrc "xset s noblank"

  # install Openframe
  echo "install openframe"
  npm install -g openframe@latest

  echo "install default format extensions"
  npm install -g openframe-image@latest
  npm install -g openframe-glslviewer@latest
  npm install -g openframe-website@latest
  npm install -g openframe-video@latest

  # interactive prompt for configuration
  openframe_ask_rotate

  echo ""
  echo "If you have changed your display rotation, you must restart the Pi by typing: sudo reboot"
  echo ""
  echo "If not, you must run the following command: source ~/.bashrc"
  echo ""
  echo "After restarting or reloading .bashrc, you can launch the frame by just typing:"
  echo ""
  echo "openframe"
}

openframe_do_install

} # this ensures the entire script is downloaded #
