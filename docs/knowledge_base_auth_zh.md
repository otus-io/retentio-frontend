# 账号与导航

🌐 [English](knowledge_base_auth.md) · [知识库](knowledge_base_zh.md)

用户要在启动后回到上次的登录态，未登录时只能做账号流程和有限的公开浏览，登录后进入卡组、发现、资料三个页签。会话失效时退回登录，避免继续打需要鉴权的接口。

## 会话里有什么

| 对象 | 字段 | 放在哪 |
| ---- | ---- | ------ |
| 用户 `User` | `email`、`username`、`emailVerified` | `GET /api/profile` |
| 会话 | `token`，以及是否已登录 | `SharedPreferences` 键 `token`、`isLogin`；内存里另有一份 token 给请求头 |

主题在 Hive 的 HydratedStorage 里。语言键是 `localeCode`。没有 refresh token。

一次有效恢复要求 `isLogin == true` 且 `token` 非空。缺一则视为未登录。

## 启动

1. 初始化崩溃上报、Hive、API 客户端，并读出已保存的 token。
2. 恢复会话。恢复完成前路由不跳转。
3. 应用的初始地址是 `/login`。
4. 已登录且停在 `/login` → 进入 `/`。未登录且当前路径需要登录 → `/login`。

## 账号流程

| 步骤 | 成功 | 失败或不做的事 |
| ---- | ---- | -------------- |
| 登录 | 用户名和密码都非空；拿到非空 token；页签回到「卡组」；进入 `/` | 缺字段或接口失败：提示错误。不检查邮箱是否已验证 |
| 注册 | 字段齐全且两次密码一致；提示去查收邮件；回到登录页 | 不自动登录。登录页用页面压栈打开注册，不走 `go('/register')`，但 `/register` 本身免登录 |
| 忘记密码 | `POST /auth/forgot-password`。若响应里带 `reset_token`（开发环境），打开 `/reset-password?token=` | 正式环境靠邮件链接。客户端未证实邮件是否一定发出 |
| 重置密码 | 链接里要有 token；新密码确认后回到登录 | 没有 token：提示错误并回登录 |
| 验证邮箱 | `/verify-email?token=` 打开后自动提交 | 无 token 立即失败；失败可重试 |
| 登出 | 资料页确认后 `POST /auth/logout`，清 token，`isLogin=false` | — |
| 401 | 清内存和本地 token，再恢复会话。token 已空，结果是未登录，受保护路由回登录 | 不保证同时弹全局提示。不主动调用 logout 接口 |

## 路由

| 路径 | 要登录 | 从哪来 | 规则 |
| ---- | ------ | ------ | ---- |
| `/login` | 否 | 启动、守卫、未登录占位 | 已登录则去 `/` |
| `/register` | 否 | 深链 | — |
| `/reset-password` | 否 | 邮件或开发用 token | — |
| `/verify-email` | 否 | 邮件 | — |
| `/` | 是 | 登录成功或恢复成功 | 主壳 |
| `/discovery/:id` | 否 | 发现列表，或深链 | 未登录可以看详情；点导入会去登录 |
| `/study` | 是 | 我的卡组，或导入后去学习 | `extra` 里必须有 `Deck`。缺失则提示回主页 |

守卫依赖认证状态已经注册。未注册时不做跳转。

## 主壳

底部三个页签，默认第 0 个。登录成功会把页签重置为卡组。

| 页签 | 已登录 | 说明 |
| ---- | ------ | ---- |
| 卡组 | 我的卡组列表 | 未登录时主壳到不了这里 |
| 发现 | 公开目录 | 目录接口可以不带 token，但这个页签在 `/` 上，正常流程仍要先登录 |
| 资料 | 个人资料和设置 | — |

主壳里还有一套「未登录就显示锁和登录按钮」的占位。守卫正常时用户不会停在未登录的 `/` 上，所以这套占位很少出现。

## 资料与偏好

资料页读取 `GET /api/profile`，展示用户名、邮箱和头像首字母。邮箱未验证时显示说明，并可重发验证邮件。

设置项：语言（en / zh / ja）、主题（light / dark / sepia / system）、统计、标签管理、退出。默认语言先是 en，再被本机保存的 `localeCode` 盖掉。主题默认在读取失败时用 dark。登录页的主题按钮只在亮和暗之间切换。

客户端没有调用更新个人资料的接口。

## 代码入口

`lib/main.dart`、`lib/features/auth/`、`lib/routers/app_pages.dart`、`lib/screen/login/`、`lib/screen/register/`、`lib/screen/profile/`、`lib/providers/theme_provider.dart`、`lib/providers/locale_provider.dart`。
