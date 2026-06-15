#!/bin/bash

XDG_DATA_HOME=${XDG_DATA_HOME:-$HOME/.local/share}

if [ -d "/opt/system/Tools/PortMaster/" ]; then
  controlfolder="/opt/system/Tools/PortMaster"
elif [ -d "/opt/tools/PortMaster/" ]; then
  controlfolder="/opt/tools/PortMaster"
elif [ -d "$XDG_DATA_HOME/PortMaster/" ]; then
  controlfolder="$XDG_DATA_HOME/PortMaster"
else
  controlfolder="/roms/ports/PortMaster"
fi

source $controlfolder/control.txt

[ -f "${controlfolder}/mod_${CFW_NAME}.txt" ] && source "${controlfolder}/mod_${CFW_NAME}.txt"

get_controls

GAMEDIR=/$directory/ports/wiliwili/
CONFDIR="$GAMEDIR/conf/"
PKGDIR="$GAMEDIR/wiliwili"

mkdir -p "$GAMEDIR/conf"

cd $GAMEDIR

> "$GAMEDIR/log.txt" && exec > >(tee "$GAMEDIR/log.txt") 2>&1

export XDG_DATA_HOME="$CONFDIR"
export LD_LIBRARY_PATH="$PKGDIR/libs.${DEVICE_ARCH}:$LD_LIBRARY_PATH"
export SDL_GAMECONTROLLERCONFIG="$sdl_controllerconfig"

# If a custom gamecontrollerdb exists, use it
if [ -f "$PKGDIR/gamecontrollerdb.txt" ]; then
    export SDL_GAMECONTROLLERCONFIG_FILE="$PKGDIR/gamecontrollerdb.txt"
fi

bind_directories ~/.config/wiliwili "$CONFDIR"

$GPTOKEYB "wiliwili" -c "$PKGDIR/wiliwili.gptk" &
pm_platform_helper "$PKGDIR/wiliwili.${DEVICE_ARCH}"
cd "$PKGDIR"
./wiliwili.${DEVICE_ARCH}

pm_finish
