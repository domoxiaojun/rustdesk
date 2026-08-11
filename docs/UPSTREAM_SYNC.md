# 自动同步官方上游

自动化由两个仓库各自的 `Sync upstream` 工作流组成，不需要跨仓库令牌或额外密钥。

## 定时执行

1. `hbb_common` 每天 02:17 UTC（新加坡时间 10:17）合并官方 `main`。
2. RustDesk 每天 03:17 UTC（新加坡时间 11:17）合并官方 `master`，并把子模块指向自有 `hbb_common/main`。

定时同步后会读取 `Cargo.toml` 的版本。如果对应的 `vX.Y.Z` 标签尚不存在，自动创建标签并派发完整构建；同一官方版本内的普通主分支提交只同步源码，不重复构建。

## 手动同步与发布

1. 在 `domoxiaojun/hbb_common` 中手动运行 `Sync upstream`，等待成功。
2. 在 `domoxiaojun/rustdesk` 中手动运行 `Sync upstream`。
3. 跟随新官方版本构建时可保持 `Force a build even if this official version already exists` 为关闭状态；检测到新版本号后会自动构建。
4. 需要在同一官方版本内强制重建时开启该选项。标签留空时自动使用递增修订标签，例如 `v1.4.9-1`、`v1.4.9-2`。
5. 也可以明确填写合法标签。自动化不会移动或覆盖已有标签。

发布步骤会显式派发 `Flutter Tag Build` 和 F-Droid 工作流。这样即使同步提交由仓库自带的 `GITHUB_TOKEN` 推送，也能正常启动后续构建。

## 安全门禁

- 仅进行普通合并和普通推送，不使用强推。
- `hbb_common` 合并前后必须保持当前服务器地址和公钥配置完全一致。
- RustDesk 合并前后必须保持当前 API 地址和自有子模块 URL 完全一致。
- RustDesk 只接受已经包含官方所需提交的自有 `hbb_common/main`。
- 只自动解析 `libs/hbb_common` 子模块指针冲突；任何其他冲突都会停止且不推送。
- 配置校验、祖先关系或标签校验失败时立即停止，不修改远端分支。
