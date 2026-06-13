#!/bin/bash
#
# wiliwili PortMaster 构建脚本
# 在 x86_64 Linux 主机上交叉编译 aarch64 版本
#
# 前置条件：
#   - Docker 已安装并运行
#   - qemu-user-static 已配置（首次运行会自动设置）
#
# 使用方式：
#   cd wiliwili  # 项目根目录
#   bash scripts/portmaster/run.sh
#
# 产物：
#   build-portmaster/wiliwili-Linux-aarch64-portmaster.zip
#

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
BUILD_DIR="${PROJECT_DIR}/build-portmaster"

echo "============================================"
echo " wiliwili PortMaster Cross Build"
echo "============================================"
echo "Project: ${PROJECT_DIR}"
echo "Build:   ${BUILD_DIR}"
echo ""

# 确保子模块已初始化
echo ">>> Initializing submodules..."
git -C "${PROJECT_DIR}" submodule update --init --recursive 2>/dev/null || true

# 配置 QEMU 用户态模拟
echo ">>> Setting up QEMU binfmt..."
docker run --rm --privileged multiarch/qemu-user-static --reset -p yes 2>/dev/null || true

# 构建 Docker 编译镜像
echo ">>> Building Docker build image..."
docker build -t wiliwili-portmaster "${SCRIPT_DIR}"

# 创建输出目录
mkdir -p "${BUILD_DIR}"

# 在 Docker 中执行编译
echo ">>> Starting cross-compilation (this may take a while)..."
docker run --rm \
    -v "${PROJECT_DIR}:/data:ro" \
    -v "${BUILD_DIR}:/output" \
    wiliwili-portmaster \
    bash /data/scripts/portmaster/build.sh /data /output

echo ""
echo "============================================"
echo " Build Complete!"
echo "============================================"
echo ""
echo "Output file: ${BUILD_DIR}/wiliwili-Linux-aarch64-portmaster.zip"
ls -lh "${BUILD_DIR}/wiliwili-Linux-aarch64-portmaster.zip" 2>/dev/null || echo "(waiting for build to finish)"
echo ""
echo "Install instructions:"
echo "  1. Copy wiliwili.port/ to your device's /roms/ports/ directory"
echo "  2. Restart EmulationStation or refresh ports list"
echo "  3. Launch 'wiliwili' from the Ports menu"
echo ""
