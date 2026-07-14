# 华为云 CCE 应用部署方案

通过 Helm Chart + OSC 服务包，在华为云 CCE 上部署云原生应用，实现跨平台交付。

## 产品目录

| 产品 | 版本 | 目录 | Release |
|------|------|------|---------|
| **AWX** | 24.6.1 | `products/awx/` | v1.0.0 |
| **GitLab CE** | 17.3.0 | `products/gitlab/` | v1.1.0 |

## 目录结构

```
├── products/
│   ├── awx/                          # Ansible AWX
│   │   ├── chart/                    # Helm Chart
│   │   │   ├── Chart.yaml
│   │   │   ├── values.yaml
│   │   │   ├── crds/
│   │   │   └── templates/
│   │   ├── osc-package/              # OSC 服务包
│   │   │   └── awx/
│   │   │       ├── metadata.yaml
│   │   │       ├── lifecycle.yaml
│   │   │       ├── manifests/        # CRD + CSD
│   │   │       └── raw/              # Helm Chart 源文件
│   │   └── deploy/                   # 手动部署 YAML (参考)
│   └── gitlab/                       # GitLab CE
│       ├── chart/                    # Helm Chart
│       │   ├── Chart.yaml
│       │   ├── values.yaml
│       │   └── templates/
│       ├── osc-package/              # OSC 服务包
│       │   └── gitlab/
│       │       ├── metadata.yaml
│       │       ├── lifecycle.yaml
│       │       ├── manifests/
│       │       └── raw/
├── .omo/                             # 设计文档/规划
├── README.md
└── .gitignore
```

## AWX

AWX 是基于 Ansible 的 Web UI、REST API 和任务引擎，Red Hat Ansible Automation Platform 的上游项目。

### 容器架构

```
Operator → Web (nginx+uwsgi+daphne) + Task (task+ee+redis+rsyslog) + PostgreSQL
```

### 存储

| 卷 | 大小 | 类型 | 用途 |
|----|------|------|------|
| PostgreSQL PVC | 10Gi | csi-disk SSD | 数据库 |
| Projects PV | 100Gi | SFS Turbo RWX | Playbook 项目 |

### 快速部署

```bash
cd products/awx/chart
helm template awx . --namespace cloud \
  --set swr.username=<user> --set swr.password=<token> \
  --set admin.password=<password> \
  --set storage.projects.existingClaim=awx-projects-claim \
  | kubectl apply --server-side --force-conflicts -f -
```

## GitLab CE

GitLab Community Edition — Git 仓库管理、CI/CD、DevOps 平台。

### 容器架构

```
LoadBalancer :80 / :443 / :22
       │
  ┌────▼──────────────┐
  │  gitlab-ce:17.3.0 │  Omnibus 单容器
  │  data  ── 50Gi    │  Git 仓库 / 数据库 / 制品
  │  config ── 10Gi   │  配置文件
  │  logs   ── 10Gi   │  日志文件
  └───────────────────┘
```

### 存储

| 卷 | 大小 | 类型 | 用途 |
|----|------|------|------|
| data | 50Gi | csi-disk | Git 仓库 / PostgreSQL / 制品 |
| config | 10Gi | csi-disk | GitLab 配置 |
| logs | 10Gi | csi-disk | 日志 |

### 快速部署

```bash
cd products/gitlab/chart
helm template gitlab . --namespace gitlab \
  --set domain=gitlab.example.com \
  --set admin.password=<password> \
  --set swr.username=<user> --set swr.password=<token> \
  | kubectl apply --server-side --force-conflicts -f -
```

## OSC 服务包

OSC（云原生服务中心）可将应用发布为标准化服务包，通过可视化界面部署到 CCE、UCS 等平台。

### 使用方式

```bash
# 1. 构建 Helm Chart
cd products/<product>/chart
helm package . -d /tmp/

# 2. 构建 OSC 包
cd products/<product>/osc-package
zip -r /tmp/<product>-<version>.zip <product>/

# 3. 上传到 OSC 控制台
#    https://console.huaweicloud.com/osc
#    我的服务 → 私有服务 → 上传服务
```

### 可配置参数

每个产品在 OSC 表单中提供 30+ 可配置参数，通过 CRD `openAPIV3Schema` 驱动表单自动生成。

## 跨平台发布

| 平台 | 说明 | OSC scenes 配置 |
|------|------|-----------------|
| **CCE** | 华为云 K8s 集群 | `CCE` |
| **UCS** | 多云/混合云/边缘 | `CCE,UCS` |
| **AttachedCluster** | 任意 K8s 集群 | 通过 UCS 接入 |

## Release 版本

| Tag | 产品 | 下载 |
|-----|------|------|
| v1.0.0 | AWX 24.6.1 | [Releases](https://github.com/linglun-scheduler/awx/releases/tag/v1.0.0) |
| v1.1.0 | GitLab CE 17.3.0 | [Releases](https://github.com/linglun-scheduler/awx/releases/tag/v1.1.0) |

## 镜像仓库

所有镜像已推送到华为云 SWR `swr.cn-east-2.myhuaweicloud.com/dx_x2era/`。部署时通过 `--set` 传入 SWR 临时凭证。

## 安全说明

- `infra-cce.yaml` (kubeconfig) → `.gitignore`
- `ssl/` 证书目录 → `.gitignore`
- SWR 凭证 → 运行时 `--set`，不写死
- 管理员密码 → 运行时 `--set`，不写死
