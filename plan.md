# 上游自动同步计划

- ✅ 为 `hbb_common` 增加定时和手动上游同步，并在合并前后核对服务器地址与公钥配置。
- ✅ 验证、提交并推送 `hbb_common` 自动化。
- ✅ 为 RustDesk 增加定时和手动上游同步，确认定制 `hbb_common` 已包含官方子模块提交。
- ✅ 保留自有 API 地址及子模块 URL；新官方版本自动构建，同版本重建使用递增修订标签。
- ✅ 使用 `shellcheck`、`actionlint` 和本地临时仓库演练验证自动化。
- ✅ 定位并修复因默认 `GITHUB_TOKEN` 缺少 Workflows 权限导致的同步推送失败。
- ✅ 手动同步 RustDesk 到官方最新 `master`，保留个人 API 与自有 `hbb_common` 配置并推送。
- ✅ 修复自有 `hbb_common/main` 新增 `WaylandDisplayInfo.transform` 后的 RustDesk 测试兼容性。
- ✅ 推送兼容补丁并完成 `v1.4.9-2` 全平台修订标签构建。
- ✅ 确认两个仓库已配置 `UPSTREAM_SYNC_TOKEN`，且旧失败来自 Secret 缺失。
- ✅ 运行 `hbb_common` 上游同步并核对远端 `main`；官方提交已在自有分支历史中，无需额外推送。
- ✅ 运行 RustDesk 上游同步，推送 `master`，创建 `v1.4.9-3` 并触发发布构建。
- ✅ 修复 PAT 标签 push 与显式派发造成的重复构建，通过 `actionlint` 后推送 `0d9470d43`。
- ✅ 确认发布 Actions 已启动且当前无失败；按用户要求停止持续跟踪，不将运行中状态记为最终构建成功。

安全边界：同步使用限定仓库范围的 `UPSTREAM_SYNC_TOKEN`，临时写入 Git extraheader 后清理，不强推、不覆盖已有标签；个人配置校验失败或出现非预期冲突时立即停止，不写入远端。
