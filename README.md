# Run-Selector - 交互式程序选择器

一个轻量级的终端程序启动器，基于 [fzf](https://github.com/junegunn/fzf) 实现流畅的交互体验，支持模糊搜索、缓存加速、GUI/CLI 程序分类显示。

## 功能特性

- **即时响应** - 基于 fzf 的高性能交互界面，无按键延迟
- **模糊搜索** - 实时过滤，输入即可搜索
- **程序分类** - 自动识别 GUI 和 CLI 程序
- **智能缓存** - 程序列表缓存 24 小时，启动更快
- **搜索过滤** - 支持命令行关键词预过滤
- **自定义参数** - 支持为程序配置默认启动参数

## 依赖

- **fzf** - 模糊查找工具

```bash
# Ubuntu/Debian
sudo apt install fzf

# Fedora
sudo dnf install fzf

# macOS
brew install fzf
```

## 安装

```bash
# 克隆或下载到 ~/run-selector 目录
chmod +x ~/run-selector/run-selector.sh
```

## 使用方法

### 基本用法

```bash
./run-selector.sh          # 显示所有程序
./run-selector.sh -g       # 仅显示 GUI 程序
./run-selector.sh -c       # 仅显示 CLI 程序
./run-selector.sh -s fire  # 预过滤包含 "fire" 的程序
./run-selector.sh -r       # 强制刷新缓存
```

### 操作说明

| 按键 | 功能 |
|------|------|
| `↑` / `↓` | 上下移动选择 |
| `Enter` | 启动选中的程序 |
| `Esc` | 退出 |
| 直接输入 | 实时模糊搜索 |

### 命令选项

| 选项 | 长选项 | 说明 |
|------|--------|------|
| `-g` | `--gui` | 仅显示图形界面程序 |
| `-c` | `--cli` | 仅显示命令行程序 |
| `-s <关键词>` | `--search <关键词>` | 预过滤程序名称 |
| `-r` | `--refresh` | 强制刷新缓存 |
| `-h` | `--help` | 显示帮助信息 |

## 示例

### 启动程序

```bash
$ ./run-selector.sh -g

╭──────────────────────────────────────────────────────────╮
│ 程序选择器 (共 45 个) | ↑/↓选择 Enter执行 Esc退出        │
├──────────────────────────────────────────────────────────┤
│ > [GUI] Firefox                                          │
│   [GUI] VS Code                                          │
│   [GUI] Files                                            │
│   [GUI] Terminal                                         │
│   ...                                                    │
╰──────────────────────────────────────────────────────────╯
```

### 模糊搜索

在界面中直接输入即可实时过滤：

```
> fire

  [GUI] Firefox              firefox
  [GUI] Firewalld            firewall-config
  [CLI] firewall-cmd         /usr/bin/firewall-cmd
```

## 程序来源

### GUI 程序

从以下目录的 `.desktop` 文件解析：

- `/usr/share/applications`
- `/usr/local/share/applications`
- `~/.local/share/applications`
- Flatpak 导出目录

### CLI 程序

从 `PATH` 环境变量中的目录扫描可执行文件。

## 缓存机制

- **缓存位置**: `~/.cache/run-selector/apps.cache.<mode>`
- **有效期**: 24 小时
- **刷新方式**: 使用 `-r` 参数或删除缓存文件

```bash
# 手动清除缓存
rm -rf ~/.cache/run-selector/
```

## 自定义参数配置

可以为特定程序配置默认启动参数，避免每次手动输入。

### 配置文件位置

```
~/.config/run-selector/config.conf
```

### 配置格式

```bash
程序名=额外参数
```

程序名可以是显示名称或命令名（不区分大小写），以 `#` 开头的行为注释。

### 配置示例

```bash
# Godot 使用 Wayland 显示驱动
godot=--editor --display-driver wayland

# Firefox 隐私模式
firefox=--private-window

# VS Code 新窗口
code=--new-window
```

### 使用效果

配置后，在 run-selector 中选择对应程序时会自动附加配置的参数：

```
正在启动: Godot
命令: godot --editor --display-driver wayland
```

## 添加快捷方式（可选）

### 添加 alias

在 `~/.bashrc` 中添加：

```bash
alias rs='~/run-selector/run-selector.sh'
alias rsg='~/run-selector/run-selector.sh -g'
alias rsc='~/run-selector/run-selector.sh -c'
```

然后执行：

```bash
source ~/.bashrc
```

之后可以直接用 `rs`、`rsg`、`rsc` 命令。

### 添加键盘快捷键

在桌面环境的键盘设置中添加自定义快捷键：

```
命令: ~/run-selector/run-selector.sh -g
快捷键: Super + R (或其他组合键)
```

## 与其他工具对比

| 工具 | 类型 | 依赖 | 特点 |
|------|------|------|------|
| **run-selector** | 终端 | fzf | 轻量、即时响应、模糊搜索 |
| rofi | 图形 | 需安装 | 美观、可定制主题 |
| dmenu | 图形 | 需安装 | 极简、轻量 |
| gnome-pie | 图形 | 需安装 | 圆形菜单 |

## 常见问题

### Q: 程序列表不完整？

某些程序可能没有 `.desktop` 文件，使用 `-c` 选项查看所有 CLI 命令。

### Q: 程序启动失败？

部分程序需要特定参数或工作目录，可以手动修改 `.desktop` 文件或直接在终端运行。

### Q: 如何添加自定义程序？

在 `~/.local/share/applications/` 创建 `.desktop` 文件：

```ini
[Desktop Entry]
Name=我的程序
Exec=/path/to/my-program
Type=Application
```

## 许可证

MIT License

## 作者

由 Claude Code 生成