# AWX 部署到华为云 CCE — 部署说明

## 前置条件

1. 一台能访问 CCE 集群的机器（`kubectl` 已配置）
2. `KUBECONFIG` 指向集群配置文件
3. SWR 镜像已就绪（首次同步已完成）

## 部署步骤

### 第 1 步：检查集群环境

```bash
# 检查节点
kubectl get nodes

# 检查存储类 (重要!)
kubectl get storageclass

# 检查 csi-nfs 是否支持 RWX
kubectl get storageclass csi-nfs 2>/dev/null || echo "csi-nfs 不可用"
```

> ⚠️ 如果 `csi-nfs` 不可用，修改 `05-awx-instance.yaml`:
> - 将 `projects_storage_access_mode: ReadWriteMany` 改为 `ReadWriteOnce`
> - 或指定其他支持 RWX 的存储类

### 第 2 步：按顺序部署

```bash
# 2.1 创建命名空间
kubectl apply -f 01-cloud-namespace.yaml

# 2.2 创建 admin 密码 (可选: 修改密码后 apply)
kubectl apply -f 02-awx-admin-password.yaml

# 2.3 安装 CRD (从 GitHub)
kubectl apply -f https://raw.githubusercontent.com/ansible/awx-operator/2.19.1/config/crd/bases/awx.ansible.com_awxs.yaml

# 2.4 部署 AWX Operator
kubectl apply -f 04-awx-operator.yaml

# 2.5 等待 Operator 就绪
kubectl -n cloud wait --for=condition=ready pod -l app.kubernetes.io/name=awx-operator --timeout=120s

# 2.6 部署 AWX 实例
kubectl apply -f 05-awx-instance.yaml
```

### 第 3 步：等待部署完成（约 3-5 分钟）

```bash
# 实时查看 Pod 状态
kubectl -n cloud get pods -w

# 所有 Pod 应最终变为 Running
kubectl -n cloud get pods
```

### 第 4 步：获取访问地址

```bash
# 获取 LoadBalancer 外部 IP
kubectl -n cloud get svc -l app.kubernetes.io/instance=awx

# 示例输出:
# NAME         TYPE           CLUSTER-IP     EXTERNAL-IP     PORT(S)
# awx-service  LoadBalancer   10.0.0.123     119.3.x.x       80:31234/TCP
```

访问 `http://<EXTERNAL-IP>` 进入 AWX 登录页面。

### 第 5 步：登录

- **用户名**: `admin`
- **密码**: `AWXAdmin123!`（在 `02-awx-admin-password.yaml` 中定义）

登录后请**立即修改密码**。

## 验证

```bash
# API 验证
curl http://<EXTERNAL-IP>/api/v2/

# Me 端点验证
curl -u admin:AWXAdmin123! http://<EXTERNAL-IP>/api/v2/me/

# PV/PVC 验证
kubectl -n cloud get pvc
kubectl -n cloud get pv
```

## 卸载

```bash
# 删除 AWX 实例 (保留 PVC)
kubectl delete -f 05-awx-instance.yaml

# 完全清理 (包括 PVC)
kubectl delete namespace cloud
```
