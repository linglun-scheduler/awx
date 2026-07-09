#!/bin/bash
# ──────────────────────────────────────────────
# AWX OSC 服务包上传脚本
# 前提: 已安装 huawei-cloud CLI 或通过浏览器操作
# ──────────────────────────────────────────────

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE="/tmp/awx-24.6.1.zip"

echo "========================================"
echo "  AWX OSC 服务包 - 上传指引"
echo "========================================"
echo ""
echo "⚠️  请上传 awx-24.6.1.zip (OSC 服务包)"
echo "   不是 awx-1.0.0.tgz (Helm 包)！"
echo ""

# 检查服务包是否存在
if [ ! -f "$PACKAGE" ]; then
  echo "❌ 服务包不存在: $PACKAGE"
  echo ""
  echo "   重新打包:"
  echo "   cd $SCRIPT_DIR/../awx-chart"
  echo "   helm package . -d $SCRIPT_DIR/awx/package/"
  echo "   cd $SCRIPT_DIR"
  echo "   zip -r $PACKAGE awx/"
  exit 1
fi

echo "📦 服务包: $PACKAGE ($(du -h "$PACKAGE" | cut -f1))"
echo "📦 内部结构:"
unzip -l "$PACKAGE" 2>&1 | tail -6
echo ""

echo "═══════════════════════════════════════════"
echo " 方式一: 华为云 OSC 控制台 (推荐)"
echo "═══════════════════════════════════════════"
echo ""
echo "1. 登录 OSC 控制台:"
echo "   https://console.huaweicloud.com/osc"
echo ""
echo "2. 左侧导航 → 我的服务 → 私有服务"
echo ""
echo "3. 点击「上传服务」"
echo "   - 仓库类型: 容器镜像仓库"
echo "   - 选择文件: $PACKAGE"
echo ""
echo "4. 上传后镜像需设为「公开」:"
echo "   SWR 控制台 → 镜像管理 → 编辑 → 公开"
echo ""
echo "5. 部署:"
echo "   我的服务 → 私有服务 → awx → 创建实例"
echo "   - 集群: 选择 CCE 集群"
echo "   - 命名空间: cloud"
echo "   - 参数: 根据需要修改 values.yaml"
echo ""

echo "═══════════════════════════════════════════"
echo " 方式二: OSC CLI (需要 huaweicloud CLI)"
echo "═══════════════════════════════════════════"
echo ""
echo "# 安装 CLI 并登录"
echo "  hcloud configure"
echo ""
echo "# 上传服务包 (参考 OSC CLI 文档)"
echo "  hcloud osc service upload --package $PACKAGE"
echo ""
echo "# 部署服务实例"
echo "  hcloud osc instance create --service awx --version 1.0.0"
echo ""

echo "========================================"
echo " 镜像已就绪 (SWR cn-east-2)"
echo "========================================"
echo "  awx:24.6.1"
echo "  awx-operator:2.19.1"
echo "  awx-ee:24.6.1"
echo "  redis:7"
echo "  postgresql-15:latest"
echo ""
echo "⚠️  请确保 SWR 镜像设为「公开」或在集群侧配置 imagePullSecret"
echo "========================================"
