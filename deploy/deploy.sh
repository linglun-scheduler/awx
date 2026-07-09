#!/bin/bash
set -euo pipefail

# AWX CCE 一键部署脚本
# 用法: ./deploy.sh
# 前提: 本机已配置 kubectl 可访问 CCE 集群

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NAMESPACE="cloud"

echo "========================================"
echo "  AWX 部署到华为云 CCE"
echo "  命名空间: $NAMESPACE"
echo "========================================"

# 第 1 步：创建命名空间
echo ""
echo "[1/6] 创建命名空间..."
kubectl apply -f "$SCRIPT_DIR/01-cloud-namespace.yaml"

# 第 2 步：创建 admin 密码
echo ""
echo "[2/6] 创建 admin 密码 Secret..."
kubectl apply -f "$SCRIPT_DIR/02-awx-admin-password.yaml"

# 第 3 步：安装 CRD
echo ""
echo "[3/6] 安装 AWX Operator CRD..."
kubectl apply -f https://raw.githubusercontent.com/ansible/awx-operator/2.19.1/config/crd/bases/awx.ansible.com_awxs.yaml

# 第 4 步：部署 Operator
echo ""
echo "[4/6] 部署 AWX Operator..."
kubectl apply -f "$SCRIPT_DIR/04-awx-operator.yaml"

echo ""
echo "等待 AWX Operator 就绪..."
kubectl -n $NAMESPACE wait --for=condition=ready pod -l app.kubernetes.io/name=awx-operator --timeout=120s || {
    echo "⚠️ 等待超时，检查 Pod 状态:"
    kubectl -n $NAMESPACE get pod -l app.kubernetes.io/name=awx-operator
}

# 第 5 步：部署 AWX 实例
echo ""
echo "[5/6] 部署 AWX 实例..."
kubectl apply -f "$SCRIPT_DIR/05-awx-instance.yaml"

# 第 6 步：等待并验证
echo ""
echo "[6/6] 等待 AWX 部署完成 (约 3-5 分钟)..."
echo ""
echo "实时状态查看: kubectl -n $NAMESPACE get pods -w"
echo ""

# 等待 30 秒后显示初始状态
sleep 30
kubectl -n $NAMESPACE get pods

echo ""
echo "========================================"
echo "  部署进行中..."
echo "  查看状态: kubectl -n $NAMESPACE get pods"
echo "  获取地址: kubectl -n $NAMESPACE get svc -l app.kubernetes.io/instance=awx"
echo "========================================"
