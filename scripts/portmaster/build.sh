#!/bin/bash
#
# PortMaster 交叉编译脚本
# 使用方式：
#   docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
#   docker build -t wiliwili-portmaster scripts/portmaster
#   docker run --rm -v $(pwd):/data wiliwili-portmaster \
#       bash /data/scripts/portmaster/build.sh /data /data/build-portmaster
#

set -e

SOURCE_DIR="${1:-/data}"
BUILD_DIR="${2:-${SOURCE_DIR}/build-portmaster}"
OUTPUT_DIR="${BUILD_DIR}/wiliwili.port"
JOBS=$(nproc)

echo "=== wiliwili PortMaster Build ==="
echo "Source:   ${SOURCE_DIR}"
echo "Build:    ${BUILD_DIR}"
echo "Output:   ${OUTPUT_DIR}"
echo "Jobs:     ${JOBS}"
echo ""

# 创建输出目录
mkdir -p "${OUTPUT_DIR}/libs"
mkdir -p "${OUTPUT_DIR}/resources"

# 配置 CMake
echo ">>> Configuring..."
cmake -B "${BUILD_DIR}/cmake" \
    -DCMAKE_BUILD_TYPE=Release \
    -DPLATFORM_DESKTOP=ON \
    -DUSE_SDL2=ON \
    -DUSE_GLES2=ON \
    -DUSE_SYSTEM_SDL2=ON \
    -DUSE_SYSTEM_CURL=ON \
    -DDISABLE_WEBP=OFF \
    -DBRLS_UNITY_BUILD=ON \
    -DCMAKE_UNITY_BUILD_BATCH_SIZE=16 \
    "${SOURCE_DIR}"

# 编译
echo ">>> Building..."
cmake --build "${BUILD_DIR}/cmake" -j"${JOBS}" --target wiliwili

# 复制可执行文件
echo ">>> Collecting binaries..."
cp "${BUILD_DIR}/cmake/wiliwili" "${OUTPUT_DIR}/wiliwili.aarch64"

# 收集运行时依赖库
echo ">>> Collecting runtime libraries..."

collect_libs() {
    ldd "$1" 2>/dev/null | grep -oP '/\S+' | sort -u
}

# 将库从系统路径复制到包目录
copy_lib() {
    local lib="$1"
    local dest="${OUTPUT_DIR}/libs/$(basename "$lib")"
    if [ ! -f "$dest" ]; then
        cp -L "$lib" "$dest" 2>/dev/null || true
    fi
}

# 从二进制收集直接依赖
while IFS= read -r lib; do
    case "$lib" in
        /lib/|/lib64/|/usr/lib/|/usr/lib64/) continue ;;
        *) copy_lib "$lib" ;;
    esac
done < <(collect_libs "${OUTPUT_DIR}/wiliwili.aarch64")

# 递归收集间接依赖直到收敛
PREV=0
CURR=$(ls "${OUTPUT_DIR}/libs/" 2>/dev/null | wc -l)
while [ "$CURR" -gt "$PREV" ]; do
    PREV=$CURR
    while IFS= read -r -d '' f; do
        while IFS= read -r lib; do
            case "$lib" in
                /lib/|/lib64/|/usr/lib/|/usr/lib64/) continue ;;
                *) copy_lib "$lib" ;;
            esac
        done < <(collect_libs "$f")
    done < <(find "${OUTPUT_DIR}/libs/" -name '*.so*' -print0)
    CURR=$(ls "${OUTPUT_DIR}/libs/" 2>/dev/null | wc -l)
done

# 清理不需要的大型 debug 符号
if command -v aarch64-linux-gnu-strip &>/dev/null; then
    aarch64-linux-gnu-strip "${OUTPUT_DIR}/wiliwili.aarch64" 2>/dev/null || true
    for lib in "${OUTPUT_DIR}/libs/"*.so*; do
        aarch64-linux-gnu-strip --strip-unneeded "$lib" 2>/dev/null || true
    done
fi

# 复制资源文件
echo ">>> Copying resources..."
cp -r "${SOURCE_DIR}/resources/"* "${OUTPUT_DIR}/resources/"

# 复制或生成 gamecontrollerdb.txt
if [ -f "${SOURCE_DIR}/resources/gamepad/gamecontrollerdb.txt" ]; then
    cp "${SOURCE_DIR}/resources/gamepad/gamecontrollerdb.txt" "${OUTPUT_DIR}/"
else
    echo ">>> Downloading gamecontrollerdb.txt..."
    wget -q "https://raw.githubusercontent.com/gabomdq/SDL_GameControllerDB/master/gamecontrollerdb.txt" \
        -O "${OUTPUT_DIR}/gamecontrollerdb.txt" || true
fi

# 复制启动脚本和配置
cp "${SOURCE_DIR}/scripts/portmaster/wiliwili.sh" "${OUTPUT_DIR}/"
cp "${SOURCE_DIR}/scripts/portmaster/port.json" "${OUTPUT_DIR}/"
cp "${SOURCE_DIR}/scripts/portmaster/wiliwili.gptk" "${OUTPUT_DIR}/"

# 复制图标
cp "${SOURCE_DIR}/resources/icon/icon.png" "${OUTPUT_DIR}/wiliwili.png"

# 设置执行权限
chmod +x "${OUTPUT_DIR}/wiliwili.sh"
chmod +x "${OUTPUT_DIR}/wiliwili.aarch64"

# 打包
echo ">>> Creating PortMaster package..."
cd "${BUILD_DIR}"
zip -r "wiliwili-Linux-aarch64-portmaster.zip" "wiliwili.port/"

echo ""
echo "=== Build Complete ==="
echo "Package: ${BUILD_DIR}/wiliwili-Linux-aarch64-portmaster.zip"
ls -lh "${BUILD_DIR}/wiliwili-Linux-aarch64-portmaster.zip"
echo ""
echo "Contents:"
du -sh "${OUTPUT_DIR}/"
du -sh "${OUTPUT_DIR}/libs/"
du -sh "${OUTPUT_DIR}/resources/"
