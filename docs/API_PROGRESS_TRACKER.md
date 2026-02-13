## API 接口进度追踪

追踪所有 API 接口的前后端实现和测试状态。

**状态说明：** ✅ 完成 | 🔧 进行中 | ❌ 未开始

---

### 身份验证（公开）

| 接口 | 说明 | 前端 | 后端 |
|---|---|---|---|
| `POST /auth/register` | 注册用户 | ❌ | ✅ |
| `POST /auth/login` | 用户登录 | ❌ | ✅ |
| `POST /auth/logout` | 用户登出 | ❌ | ❌ |
| `POST /auth/forgot-password` | 忘记密码 / 重置密码 | ❌ | ❌ |

### 管理员

| 接口 | 说明 | 前端 | 后端 |
|---|---|---|---|
| `POST /admin/login` | 管理员登录 | ❌ | ✅ |
| `GET /admin/api/users` | 获取所有用户 | ❌ | ✅ |
| `GET /admin/api/users/{username}` | 获取用户详情 | ❌ | ✅ |
| `GET /admin/api/decks` | 获取所有卡组（管理员） | ❌ | ✅ |

### 用户

| 接口 | 说明 | 前端 | 后端 |
|---|---|---|---|
| `GET /api/profile` | 获取当前用户信息 | ❌ | ✅ |
| `PATCH /api/profile` | 更新用户信息（用户名、邮箱、密码等） | ❌ | ❌ |

### 卡组

| 接口 | 说明 | 前端 | 后端 |
|---|---|---|---|
| `POST /api/decks` | 创建卡组（创建后自动预排24小时） | ❌ | ✅ |
| `GET /api/decks` | 获取所有卡组 | ❌ | ✅ |
| `GET /api/decks/{id}` | 获取卡组详情 | ❌ | ✅ |
| `PATCH /api/decks/{id}` | 更新卡组 | ❌ | ✅ |
| `DELETE /api/decks/{id}` | 删除卡组 | ❌ | ✅ |
| `GET /api/decks/{id}/holiday-check` | 检测用户是否长时间未学习并自动调整 | ❌ | ❌ |
| `POST /api/decks/{id}/split` | 拆分卡组为子卡组（按章节） | ❌ | ❌ |
| `GET /api/decks/public/{id}` | 下载公开卡组 | ❌ | ❌ |

### 词条

| 接口 | 说明 | 前端 | 后端 |
|---|---|---|---|
| `POST /api/decks/{id}/facts/{operation}` | 添加词条 (append/prepend/shuffle/spread) 🔧 | ❌ | ❌ |
| `GET /api/decks/{id}/facts` | 获取所有词条 | ❌ | ✅ |
| `GET /api/decks/{id}/facts/{factIndex}` | 获取单个词条 | ❌ | ✅ |
| `PATCH /api/decks/{id}/facts/{factIndex}` | 更新词条 | ❌ | ✅ |
| `DELETE /api/decks/{id}/facts/{factIndex}` | 删除词条 | ❌ | ✅ |
| `GET /api/decks/{id}/facts/search` | 模糊搜索词条（提前复习特定单词） | ❌ | ❌ |

### 卡片

| 接口 | 说明 | 前端 | 后端 |
|---|---|---|---|
| `GET /api/decks/{id}/next-due-card` | 获取下一张待复习卡片 | ❌ | ✅ |
| `GET /api/decks/{id}/cards/all-cards` | 获取所有卡片 | ❌ | ✅ |
| `GET /api/decks/{id}/cards/hidden-cards` | 获取已隐藏卡片 | ❌ | ✅ |
| `PATCH /api/decks/{id}/cards/{cardIndex}/update-interval` | 更新卡片间隔 | ❌ | ✅ |
| `PATCH /api/decks/{id}/cards/{cardIndex}/update-visibility` | 隐藏/显示卡片（已掌握的单词） | ❌ | ✅ |
| `POST /api/decks/{id}/reschedule` | 自动重排卡片复习计划 | ❌ | ❌ |
| `PATCH /api/decks/{id}/reschedule-due` | 批量调整到期日期（考试前集中复习） | ❌ | ❌ |

### 媒体文件

| 接口 | 说明 | 前端 | 后端 |
|---|---|---|---|
| `POST /api/media/upload` | 上传文件（支持 apkg 导入卡组） | ❌ | ❌ |
| `GET /api/media/files` | 获取用户所有文件 | ❌ | ❌ |
| `GET /api/media/files/{file_id}/metadata` | 获取文件元数据 | ❌ | ❌ |
| `DELETE /api/media/files/{file_id}` | 删除文件 | ❌ | ❌ |
| `GET /api/media/audio/{file_id}` | 播放音频 | ❌ | ❌ |
| `GET /api/media/image/{file_id}` | 显示图片 | ❌ | ❌ |

### 排行榜 / 游戏化

| 接口 | 说明 | 前端 | 后端 |
|---|---|---|---|
| `POST /api/ranking/calculate` | 计算/更新排行榜排名 | ❌ | ❌ |
| `GET /api/ranking` | 获取用户排行榜（按已学单词数） | ❌ | ❌ |
| `GET /api/ranking/me` | 获取当前用户排名 | ❌ | ❌ |

### 分页支持

| 接口 | 说明 | 前端 | 后端 |
|---|---|---|---|
| 所有列表接口 | 支持 `page` / `pageSize` 分页参数 | ❌ | ❌ |

---

### 其他待办
