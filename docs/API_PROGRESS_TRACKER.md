## API 接口进度追踪

追踪所有 API 接口的前后端实现和测试状态。

**状态说明：** ✅ 完成 | 🔧 进行中 | ❌ 未开始

---

### 身份验证（公开）

| 接口 | 说明 | 前端 | 后端 |
|---|---|---|---|
| `POST /auth/register` | 注册用户 | ✅ | ✅ |
| `POST /auth/login` | 用户登录 | ✅ | ✅ |
| `POST /auth/logout` | 用户登出 | ❌ | ✅ |
| `POST /auth/forgot-password` | 请求密码重置令牌 | ❌ | ✅ |
| `POST /auth/reset-password` | 使用令牌重置密码 | ❌ | ✅ |

### 用户

| 接口 | 说明 | 前端 | 后端 |
|---|---|---|---|
| `GET /api/profile` | 获取当前用户信息 | ❌ | ✅ |
| `PATCH /api/profile` | 更新用户信息（用户名、邮箱、密码等） | ❌ | ❌ |

### 卡组

| 接口 | 说明 | 前端 | 后端 |
|---|---|---|---|
| `POST /api/decks` | 创建卡组（创建后自动预排24小时） | ✅ | ✅ |
| `GET /api/decks` | 获取所有卡组 | ✅ | ✅ |
| `GET /api/decks/{id}` | 获取卡组详情 | ❌ | ✅ |
| `PATCH /api/decks/{id}` | 更新卡组 | ✅ | ✅ |
| `DELETE /api/decks/{id}` | 删除卡组 | ✅ | ✅ |
| `GET /api/decks/{id}/card` (meta) | 假期检测：通过 card 元数据返回 | ❌ | ✅ |
| `POST /api/decks/{id}/split` | 拆分卡组为子卡组（按章节） | ❌ | ❌ |
| `GET /api/decks/public/{id}` | 下载公开卡组 | ❌ | ❌ |

### 词条

| 接口 | 说明 | 前端 | 后端 |
|---|---|---|---|
| `POST /api/decks/{id}/facts/{operation}` | 添加词条 (append/prepend/shuffle/spread) | ❌ | ✅ |
| `GET /api/decks/{id}/facts` | 获取所有词条 | ❌ | ✅ |
| `GET /api/decks/{id}/facts/{factId}` | 获取单个词条 | ❌ | ✅ |
| `PATCH /api/decks/{id}/facts/{factId}` | 更新词条 | ❌ | ✅ |
| `DELETE /api/decks/{id}/facts/{factId}` | 删除词条 | ❌ | ✅ |
| `GET /api/decks/{id}/facts/search` | 模糊搜索词条（提前复习特定单词） | ❌ | ❌ |

### 卡片

| 接口 | 说明 | 前端 | 后端 |
|---|---|---|---|
| `GET /api/decks/{id}/card` | 获取最紧急卡片 | ❌ | ✅ |
| `PATCH /api/decks/{id}/card` | 更新卡片间隔或可见性（按 card_id 查找，支持 last_review 离线同步） | ❌ | ✅ |
| `GET /api/decks/{id}/cards` | 获取卡片统计（总数、隐藏数量、隐藏事实） | ❌ | ✅ |
| `POST /api/decks/{id}/reschedule` | 假期模式：按天数平移卡片复习计划 | ❌ | ✅ |

### 排行榜 / 游戏化

| 接口 | 说明 | 前端 | 后端 |
|---|---|---|---|
| `POST /api/ranking/calculate` | 计算/更新排行榜排名 | ❌ | ❌ |
| `GET /api/ranking` | 获取用户排行榜（按已学单词数） | ❌ | ❌ |
| `GET /api/ranking/me` | 获取当前用户排名 | ❌ | ❌ |

### 媒体

| 接口 | 说明 | 前端 | 后端 |
|---|---|---|---|
| `POST /api/media` | 上传媒体文件 | ❌ | ✅ |
| `GET /api/media` | 列出用户媒体（支持 since/limit/offset） | ❌ | ✅ |
| `GET /api/media/{id}` | 下载媒体文件 | ❌ | ✅ |
| `GET /api/media/{id}/meta` | 获取媒体元数据 | ❌ | ✅ |
| `DELETE /api/media/{id}` | 删除媒体 | ❌ | ✅ |

### 共享媒体（管理员）

| 接口 | 说明 | 前端 | 后端 |
|---|---|---|---|
| `POST /api/admin/media/shared` | 上传共享媒体（管理员） | ❌ | ✅ |
| `GET /api/media/shared/{id}` | 下载共享媒体 | ❌ | ✅ |
| `GET /api/media/shared?word=...&lang=...` | 按单词查询共享媒体 | ❌ | ✅ |
| `DELETE /api/admin/media/shared/{id}` | 删除共享媒体（管理员） | ❌ | ✅ |
| `POST /api/admin/decks/import` | 批量导入共享卡组（ZIP + manifest） | ❌ | ✅ |

### 分页支持

| 接口 | 说明 | 前端 | 后端 |
|---|---|---|---|
| 所有列表接口 | 支持 `page` / `pageSize` 分页参数 | ❌ | ❌ |

---

### 其他待办
