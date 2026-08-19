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
- ⬜ 在两个仓库配置 `UPSTREAM_SYNC_TOKEN` 后重新运行定时同步验证。

安全边界：同步使用限定仓库范围的 `UPSTREAM_SYNC_TOKEN`，临时写入 Git extraheader 后清理，不强推、不覆盖已有标签；个人配置校验失败或出现非预期冲突时立即停止，不写入远端。
