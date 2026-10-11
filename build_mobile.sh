#!/bin/bash
# ========================================
# 人口通 - 移动端构建脚本
# ========================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MOBILE_DIR="${SCRIPT_DIR}/mobile"

# 颜色输出
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

echo_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

echo_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查 Flutter 环境
check_flutter() {
    # PATH 中没有 flutter 时，自动探测常见安装路径（本机安装于 $HOME/Flutter）
    if ! command -v flutter &> /dev/null; then
        for FLUTTER_DIR in "$HOME/Flutter" "$HOME/flutter" "/opt/flutter" "/usr/local/flutter"; do
            if [ -x "$FLUTTER_DIR/bin/flutter" ]; then
                export PATH="$FLUTTER_DIR/bin:$PATH"
                break
            fi
        done
    fi
    if ! command -v flutter &> /dev/null; then
        echo_error "未找到 Flutter，请先安装 Flutter SDK"
        echo_info "安装指南: https://flutter.dev/docs/get-started/install"
        exit 1
    fi
    echo_info "Flutter 已安装: $(flutter --version | head -1)"
}

# 配置 API 地址
configure_api_url() {
    local API_URL=${1:-"https://your-domain.com:5000"}
    
    CONFIG_FILE="${MOBILE_DIR}/lib/config/app_config.dart"
    
    if [ -f "$CONFIG_FILE" ]; then
        # 备份原配置
        cp "$CONFIG_FILE" "${CONFIG_FILE}.bak"
        
        # 更新 API 地址
        sed -i "s|static String apiBaseUrl = .*|static String apiBaseUrl = '${API_URL}';|g" "$CONFIG_FILE"
        
        echo_info "API 地址已配置为: ${API_URL}"
    fi
}

# 获取依赖
get_dependencies() {
    echo_info "获取 Flutter 依赖..."
    cd "${MOBILE_DIR}"
    flutter pub get
    echo_info "依赖获取完成"
}

# 运行测试
run_tests() {
    echo_info "运行测试..."
    cd "${MOBILE_DIR}"
    flutter test
    echo_info "测试完成"
}

# 静态分析
analyze() {
    echo_info "静态代码分析..."
    cd "${MOBILE_DIR}"
    flutter analyze
    echo_info "分析完成"
}

# 构建 APK
build_apk() {
    local BUILD_TYPE=${1:-"release"}
    
    cd "${MOBILE_DIR}"
    
    echo_info "构建 APK (${BUILD_TYPE})..."
    
    case "$BUILD_TYPE" in
        release)
            flutter build apk --release
            echo_info "APK 输出: ${MOBILE_DIR}/build/app/outputs/flutter-apk/app-release.apk"
            ;;
        debug)
            flutter build apk --debug
            echo_info "APK 输出: ${MOBILE_DIR}/build/app/outputs/flutter-apk/app-debug.apk"
            ;;
        split)
            flutter build apk --split-per-abi
            echo_info "分架构 APK 输出: ${MOBILE_DIR}/build/app/outputs/flutter-apk/"
            ;;
        *)
            echo_error "未知构建类型: $BUILD_TYPE"
            echo_info "支持的类型: release, debug, split"
            exit 1
            ;;
    esac
    
    echo_info "构建完成"
}

# 清理构建
clean() {
    echo_info "清理构建..."
    cd "${MOBILE_DIR}"
    flutter clean
    echo_info "清理完成"
}

# 使用帮助
show_help() {
    echo "人口通 - 移动端管理脚本"
    echo ""
    echo "用法: $0 <命令> [参数]"
    echo ""
    echo "命令:"
    echo "  check               检查 Flutter 环境"
    echo "  config <url>        配置 API 地址"
    echo "  deps                获取依赖"
    echo "  test                运行测试"
    echo "  analyze             静态代码分析"
    echo "  build <type>        构建 APK"
    echo "                      type: release(默认), debug, split"
    echo "  clean               清理构建"
    echo "  all <api_url>       完整构建流程（配置+依赖+测试+构建）"
    echo "  help                显示帮助"
    echo ""
    echo "示例:"
    echo "  $0 config https://192.168.1.100:5000"
    echo "  $0 build release"
    echo "  $0 all https://your-domain.com:5000"
}

# 完整构建流程
build_all() {
    local API_URL=${1:-"https://your-domain.com:5000"}
    
    check_flutter
    configure_api_url "$API_URL"
    get_dependencies
    run_tests
    analyze
    build_apk release
}

# 主入口
case "${1:-help}" in
    check)
        check_flutter
        ;;
    config)
        configure_api_url "${2:-https://your-domain.com:5000}"
        ;;
    deps)
        check_flutter
        get_dependencies
        ;;
    test)
        check_flutter
        get_dependencies
        run_tests
        ;;
    analyze)
        check_flutter
        get_dependencies
        analyze
        ;;
    build)
        check_flutter
        get_dependencies
        build_apk "${2:-release}"
        ;;
    clean)
        clean
        ;;
    all)
        build_all "${2:-https://your-domain.com:5000}"
        ;;
    help|*)
        show_help
        ;;
esac
