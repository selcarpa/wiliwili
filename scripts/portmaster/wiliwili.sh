#!/bin/bash
#
# wiliwili PortMaster 启动脚本
# 放置在 /roms/ports/wiliwili/ 目录下

# ---- PortMaster 运行时初始化 ----
if [ -d "/opt/system/Tools/PortMaster/" ]; then
    controlfolder="/opt/system/Tools/PortMaster"
elif [ -d "/opt/tools/PortMaster/" ]; then
    controlfolder="/opt/tools/PortMaster"
else
    controlfolder="/roms/ports/PortMaster"
fi

source "$controlfolder/control.txt"
get_controls

cd "/$directory/ports/wiliwili"

# ---- 环境变量设置 ----
export SDL_GAMECONTROLLERCONFIG="$sdl_controllerconfig"
export LD_LIBRARY_PATH="$PWD/libs:$LD_LIBRARY_PATH"

# 如果存在自定义映射，使用它
if [ -f "$PWD/gamecontrollerdb.txt" ]; then
    export SDL_GAMECONTROLLERCONFIG_FILE="$PWD/gamecontrollerdb.txt"
fi

# ---- 输入后台进程 ----
# gptokeyb 将手柄按键映射为键盘/鼠标事件，并负责退出手势
$GPTOKEYB "wiliwili" -c "./wiliwili.gptk" &
GPTOKEYB_PID=$!

# 确保 uinput 可访问
$ESUDO chmod 666 /dev/uinput 2>/dev/null || true

# ---- 启动 wiliwili ----
# 设置 480p UI 缩放以适配 640x480 或更小的屏幕
./wiliwili.aarch64 \
    --window-width=640 \
    --window-height=480

# ---- 清理 ----
kill "$GPTOKEYB_PID" 2>/dev/null || true
$ESUDO systemctl restart oga_events 2>/dev/null || true

# 清理终端
printf "\033c" > /dev/tty1 2>/dev/null || true
