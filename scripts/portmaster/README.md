# wiliwili PortMaster 构建与安装

## 构建（在 x86_64 PC 上交叉编译）

### 前置条件

- Docker 已安装并运行
- Git

### 步骤

```bash
# 1. 克隆仓库并初始化子模块
git clone --recursive https://github.com/xfangfang/wiliwili.git
cd wiliwili

# 2. 运行 PortMaster 构建脚本
bash scripts/portmaster/run.sh
```

构建产物：`build-portmaster/wiliwili-Linux-aarch64-portmaster.zip`

### 在没有 Docker 的环境中手动构建

如果无法使用 Docker，也可以直接在 ARM64 Linux 设备（如树莓派、RK3588 开发板）上原生编译：

```bash
# 安装依赖
sudo apt install build-essential cmake libmpv-dev libwebp-dev \
    libssl-dev libsdl2-dev libcurl4-openssl-dev \
    libgl1-mesa-dev libegl1-mesa-dev libgles2-mesa-dev \
    libass-dev libuchardet-dev git pkg-config

# 编译
cd wiliwili
git submodule update --init --recursive
cmake -B build -DCMAKE_BUILD_TYPE=Release \
    -DPLATFORM_DESKTOP=ON -DUSE_SDL2=ON -DUSE_GLES2=ON \
    -DUSE_SYSTEM_SDL2=ON -DUSE_SYSTEM_CURL=ON
cmake --build build -j$(nproc) --target wiliwili

# 收集产物（可参考 scripts/portmaster/build.sh 的打包逻辑）
```

---

## 安装到 PortMaster 设备

### 需要的设备规格

| 要求 | 说明 |
|------|------|
| **架构** | aarch64 (ARM64) |
| **GPU** | 支持 OpenGL ES 2.0+ |
| **屏幕** | 最低 640×480（推荐 854×480 或更高）|
| **存储** | 约 100MB（含运行时库）|
| **系统** | 支持 PortMaster 的自制固件（ArkOS、JelOS、AmberELEC、Rocknix 等）|

### 安装步骤

#### 方法一：通过 PortMaster 工具安装（如果已收录）

1. 打开设备上的 **PortMaster** 工具
2. 在列表中找到 **wiliwili**
3. 选择安装
4. 安装完成后在 **Ports** 菜单中启动

#### 方法二：手动安装

1. 将 `wiliwili-Linux-aarch64-portmaster.zip` 传输到设备上
2. 解压到 `/roms/ports/` 目录：

```bash
# 在设备上执行（通过 SSH 或终端）
unzip wiliwili-Linux-aarch64-portmaster.zip -d /roms/ports/
```

3. 解压完成后目录结构应为：

```
/roms/ports/wiliwili/
├── wiliwili.sh            # 启动脚本
├── wiliwili.aarch64       # 可执行文件
├── wiliwili.png           # 图标
├── wiliwili.gptk          # 手柄按键配置
├── port.json              # PortMaster 元数据
├── gamecontrollerdb.txt   # SDL 手柄映射
├── libs/                  # 运行时库
│   ├── libmpv.so.*
│   ├── libavcodec.so.*
│   └── ...
└── resources/             # 应用资源
    ├── font/
    ├── i18n/
    ├── xml/
    └── ...
```

4. 重启 EmulationStation 或刷新 Ports 列表
5. 在 **Ports** 菜单中选择 **wiliwili** 启动

### 首次启动配置

首次启动后，进入 **设置 → 界面设置 → UI 缩放**，选择 **480p** 以适配小屏幕。

或直接编辑配置文件：

```bash
# 配置文件位置
~/.config/wiliwili/wiliwili_config.json
# 或
/roms/ports/wiliwili/wiliwili_config.json

# 设置 UI 缩放
"app_ui_scale": "480p"
```

---

## 目录结构说明

```
wiliwili.port/                  # PortMaster 包目录
├── wiliwili.sh                 # PortMaster 标准启动脚本
├── wiliwili.aarch64            # aarch64 编译的二进制
├── wiliwili.png                # 256x256 图标
├── wiliwili.gptk               # gptokeyb 退出手势配置
├── port.json                   # PortMaster 元数据
├── gamecontrollerdb.txt        # SDL 游戏手柄映射数据库
├── libs/                       # 捆绑的共享库
└── resources/                  # 应用资源
```

### 启动脚本说明

`wiliwili.sh` 会：
1. 自动检测 PortMaster 运行时路径
2. 设置 SDL 游戏控制器映射（适配不同设备的手柄）
3. 启动 gptokeyb 提供退出手势（Select + Start）
4. 以 640×480 窗口模式启动 wiliwili
5. 退出时清理后台进程

### 可自定义的选项

- **替换手柄映射**：将自定义 `gamecontrollerdb.txt` 放入包目录
- **调整 UI 缩放**：修改 `wiliwili.sh` 中的 `--window-width`/`--window-height` 参数
- **修改退出手势**：编辑 `wiliwili.gptk` 文件
