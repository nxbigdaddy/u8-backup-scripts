# U8 数据库备份脚本集

> 由内部工程脱敏整理后开源。原目录：`U8-T` ｜ 领域：运维工具

## 项目简介

U8 数据库备份/分离/还原 PowerShell 脚本集（31 个 ps1 + 执行记录）

## 技术栈

未标注

## 目录结构

```text
├── U8业务流程分析报告.html
├── U8模块使用量分析报告.md
├── U8系统分析报告.md
├── U8系统改善建议报告.html
├── agent_check.ps1
├── agent_check.txt
├── backup_detach.ps1
├── backup_detached.txt
├── backup_echo.ps1
├── backup_echo.txt
├── backup_final.ps1
├── backup_final.txt
├── backup_go.ps1
├── backup_go.txt
├── backup_one_shot.ps1
├── backup_one_shot.txt
├── backup_restart.ps1
├── backup_result.txt
├── backup_sch.ps1
├── backup_status.txt
├── backup_task.ps1
├── backup_task.txt
├── backup_v3.ps1
├── backup_xp.ps1
├── biz_module_analysis.txt
├── bk_cmd.sql
├── block_check.ps1
├── block_check.txt
└── ... 其余 33 项
```

## 快速开始

```bash
git clone <你的仓库地址>
cd u8-backup-scripts
```

- 依赖安装与启动方式请参考仓库内各子目录的 README 与配置文件。
- 所有配置模板均以 `*.example` 形式提供，请复制后填入你自己的密钥与地址。

## 脱敏说明

本仓库由内部工程导出，导出时已执行以下处理：

- **删除**：私钥与证书（`*.pem` / `*.key` / `*.pfx` / `id_rsa*` / `id_ed25519*`）、`.env` 实例文件、
  数据库与备份（`*.sql` 数据导出 / `*.db` / `*.sqlite` / `*.bak` / `*.mdf`）、cookie 与本地配置、
  依赖目录与构建产物、压缩包与安装程序、大体积媒体文件。
- **替换**：口令、API Key、Token、连接串密码、内网 IP、企业域名与企业名称，均替换为占位符。
- **保留**：可公开的源码、配置模板（`.env.example`）、文档、测试与少量必要素材。

如仍发现遗漏的敏感信息，请提交 Issue，我们会立即处理。

## 许可证

MIT
