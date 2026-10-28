# 当前系统数据交付

数据库快照：`jsh_erp-2026-10-28.sql`，导出时间为 2026-10-28（北京时间），含当前 67 张表的结构与数据，包括系统账号、权限和业务记录。

本次上传附件目录为空，无需另行复制附件。数据库连接密码和本机运行环境不包含在交付中。

## 恢复

1. 安装 MySQL 8、Redis、Java 8、Maven 和项目要求的 Node 环境。
2. 在全新实例或已经备份的目标环境导入，避免覆盖目标环境同名数据库。SQL 含建库、建表及数据语句。
3. 在终端执行：

```powershell
mysql --host=127.0.0.1 --port=3306 --user=root --password --default-character-set=utf8mb4 < jsh_erp-2026-10-28.sql
```

上面的重定向命令请在 cmd 或 Bash 中执行；PowerShell 可先运行 `mysql --host=127.0.0.1 --port=3306 --user=root --password --default-character-set=utf8mb4`，再在 MySQL 提示符执行 `source E:/你的项目目录/transfer-data/jsh_erp-2026-10-28.sql`。

4. 按实际环境配置后端的 MySQL、Redis 及上传路径，构建并启动前后端。代码入口和依赖见根目录 README.md；当前功能说明在 jshERP-boot/docs/factory。
5. 该快照已包含工厂模块表结构，不要重复执行历史迁移 SQL 或用初始 jsh_erp.sql 覆盖。

请只在私有仓库向授权协作者分享此快照。数据库中的应用登录账号与业务数据会随备份恢复；MySQL 服务账号与连接凭据需要接收者自行配置。
