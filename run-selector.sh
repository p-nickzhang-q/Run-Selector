#!/bin/bash
# 交互式程序选择器 - 上下键选择版本

# 配置
CACHE_DIR="$HOME/.cache/run-selector"
CACHE_FILE="$CACHE_DIR/apps.cache"
CONFIG_FILE="$HOME/.config/run-selector/config.conf"
CACHE_EXPIRE_SECONDS=$((24 * 60 * 60))

# 颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# 显示帮助
show_help() {
    echo -e "${CYAN}交互式程序选择器${NC}"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -g, --gui      仅显示图形界面程序"
    echo "  -c, --cli      仅显示命令行程序"
    echo "  -s, --search   搜索特定程序名称"
    echo "  -r, --refresh  强制刷新缓存"
    echo "  -h, --help     显示此帮助信息"
    echo ""
    echo "操作: ${GREEN}↑/↓${NC} 选择  ${GREEN}Enter${NC} 执行  ${GREEN}q${NC} 退出"
    echo ""
    echo "配置文件: ~/.config/run-selector/config.conf"
    echo "  格式: 程序名=额外参数"
    echo "  示例: godot=--editor --display-driver wayland"
    echo ""
}

# 获取 GUI 程序
get_gui_apps() {
    local dirs=(
        "/usr/share/applications"
        "/usr/local/share/applications"
        "$HOME/.local/share/applications"
        "/var/lib/flatpak/exports/share/applications"
        "$HOME/.local/share/flatpak/exports/share/applications"
    )

    for dir in "${dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            while IFS= read -r desktop_file; do
                [[ -z "$desktop_file" ]] && continue
                local name="" exec_cmd=""
                name=$(grep -m1 '^Name=' "$desktop_file" 2>/dev/null | cut -d'=' -f2-)
                exec_cmd=$(grep -m1 '^Exec=' "$desktop_file" 2>/dev/null | cut -d'=' -f2- | sed 's/%.//g' | sed 's/  */ /g' | sed 's/^"//;s/"$//' | sed 's/^"//;s/"[[:space:]]/ /;s/"$//')
                [[ -z "$name" || -z "$exec_cmd" ]] && continue
                echo "GUI|${name}|${exec_cmd}"
            done < <(find "$dir" -name "*.desktop" -type f 2>/dev/null)
        fi
    done | sort -u -t'|' -k2
}

# 获取 CLI 程序 - 仅扫描用户目录
get_cli_apps() {
    local user_dirs=(
        "$HOME/.local/bin"
        "$HOME/bin"
        "$HOME/go/bin"
        "$HOME/.cargo/bin"
        "$HOME/.npm-global/bin"
        "$HOME/.opencode/bin"
    )

    for dir in "${user_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            for file in "$dir"/*; do
                [[ -x "$file" && -f "$file" ]] && echo "CLI|$(basename "$file")|$file"
            done 2>/dev/null
        fi
    done | sort -u -t'|' -k2
}

# 收集程序
collect_apps() {
    local mode="$1"
    case "$mode" in
        gui) get_gui_apps ;;
        cli) get_cli_apps ;;
        all) get_gui_apps; get_cli_apps ;;
    esac
}

# 获取程序额外参数
get_extra_args() {
    local name="$1"
    local cmd_basename=$(basename "$cmd" 2>/dev/null | cut -d' ' -f1)

    # 检查配置文件是否存在
    if [[ -f "$CONFIG_FILE" ]]; then
        while IFS='=' read -r prog args; do
            [[ -z "$prog" || "$prog" =~ ^# ]] && continue
            # 匹配程序名或命令名
            if [[ "${name,,}" == "${prog,,}" ]] || [[ "${cmd_basename,,}" == "${prog,,}" ]]; then
                echo "$args"
                return
            fi
        done < "$CONFIG_FILE"
    fi
}

# 交互式菜单 - 使用 fzf
interactive_menu() {
    local apps=("$@")
    local total=${#apps[@]}

    # 检查 fzf 是否安装
    if ! command -v fzf &>/dev/null; then
        echo -e "${RED}错误: fzf 未安装${NC}"
        echo -e "${YELLOW}请运行: sudo apt install fzf${NC}"
        exit 1
    fi

    local selection
    selection=$(printf '%s\n' "${apps[@]}" | fzf \
        --height=80% \
        --layout=reverse \
        --border \
        --header="程序选择器 (共 $total 个) | ↑/↓选择 Enter执行 Esc退出" \
        --preview-window=hidden \
        --ansi \
        --with-nth=2.. \
        --delimiter='|')

    [[ -z "$selection" ]] && echo -e "${YELLOW}已退出${NC}" && exit 0

    local type="${selection%%|*}"
    local rest="${selection#*|}"
    local name="${rest%%|*}"
    local cmd="${rest#*|}"

    # 获取额外参数
    local extra_args=$(get_extra_args "$name" "$cmd")

    echo ""
    echo -e "${GREEN}正在启动: ${name}${NC}"
    if [[ -n "$extra_args" ]]; then
        echo -e "${BLUE}命令: ${cmd} ${extra_args}${NC}"
    else
        echo -e "${BLUE}命令: ${cmd}${NC}"
    fi
    echo ""

    if [[ "$type" == "CLI" ]]; then
        # CLI 程序在前台执行（$cmd 必须加引号：路径里常含空格）
        exec "$cmd" $extra_args
    else
        # GUI 程序后台启动（$cmd 必须加引号，否则 "/opt/T3 Code (Beta)/t3code" 会被拆成三个参数）
        local launch_log="${TMPDIR:-/tmp}/run-selector-launch.log"
        : > "$launch_log"
        nohup "$cmd" $extra_args >"$launch_log" 2>&1 &
        local pid=$!
        disown 2>/dev/null

        # 给进程 1.5 秒确认它没立刻挂掉，避免静默失败
        sleep 1.5
        if kill -0 "$pid" 2>/dev/null; then
            echo -e "${GREEN}程序已启动！${NC} (pid $pid)"
        else
            echo -e "${RED}启动失败！${NC} 命令没有活下来。输出如下："
            sed 's/^/    /' "$launch_log"
            echo -e "${YELLOW}提示：如果是 Electron 应用且已有一份在运行，第二个实例会静默退出（正常现象）。${NC}"
        fi
    fi
}

# 主函数
main() {
    local mode="all"
    local search_query=""
    local force_refresh=false

    # 解析参数
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -g|--gui) mode="gui"; shift ;;
            -c|--cli) mode="cli"; shift ;;
            -r|--refresh) force_refresh=true; shift ;;
            -s|--search)
                shift
                search_query="$1"
                shift
                ;;
            -h|--help) show_help; exit 0 ;;
            *) echo -e "${RED}未知选项: $1${NC}"; show_help; exit 1 ;;
        esac
    done

    mkdir -p "$CACHE_DIR"

    local cache_file="$CACHE_FILE.$mode"
    local apps=""

    # 加载缓存或收集
    if [[ "$force_refresh" != "true" ]] && [[ -f "$cache_file" ]]; then
        local cache_time=$(stat -c %Y "$cache_file" 2>/dev/null || echo 0)
        local now=$(date +%s)
        if [[ $((now - cache_time)) -lt $CACHE_EXPIRE_SECONDS ]]; then
            apps=$(cat "$cache_file")
        fi
    fi

    if [[ -z "$apps" ]]; then
        echo -e "${CYAN}正在收集程序列表...${NC}"
        apps=$(collect_apps "$mode")
        echo "$apps" > "$cache_file"
    fi

    # 搜索过滤
    if [[ -n "$search_query" ]]; then
        apps=$(echo "$apps" | grep -i "$search_query")
        [[ -z "$apps" ]] && echo -e "${RED}未找到匹配程序${NC}" && exit 1
    fi

    # 转为数组
    mapfile -t apps_array <<< "$apps"

    [[ ${#apps_array[@]} -eq 0 ]] && echo -e "${RED}没有找到程序${NC}" && exit 1

    # 启动交互菜单
    interactive_menu "${apps_array[@]}"
}

main "$@"