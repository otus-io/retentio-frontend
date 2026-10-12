# 学习

🌐 [English](knowledge_base_study.md) · [知识库](knowledge_base_zh.md)

学习要解决的是：从一套卡组里拿出当前最该看的一张卡，先回忆，再核对，用「下次什么时候再出现」打分，然后立刻再拿一张。队列可以按词条标签缩小。用户可以隐藏一张卡，或删掉这一张卡而留下词条。

进度是这一轮里清掉了多少到期卡，不是单独的「学完了」页面。客户端没有「全部复习完」的结束页。服务端会一直返回最紧急的卡，所以即使用户已经追平到期，只要服务端还给卡，就可以继续下一张。选卡的服务端细则客户端未证实。

导入副本上的质量验收不在这个界面，而在 QA。见 [词条、标签与协作](knowledge_base_content_zh.md)。

## 一张卡

`Card`（`lib/models/card.dart`）是学习单位。

| 字段 | 含义 |
| ---- | ---- |
| `id` | 提交复习、隐藏、删除用的主键 |
| `fact_id` | 关联词条，编辑和举报用它 |
| `front` / `back` | 正反面槽位。每个槽位有列名和若干条目：text / audio / json / image / video |
| `template` | 这张卡的正反面引用了词条的哪些 entry 下标 |
| `due_date` | 下次到期，Unix 秒。服务端调度结果。客户端不另存 interval |
| `last_review` | 上次复习，Unix 秒 |
| `hidden` | 隐藏后不应再被展示 |
| `created_at` | Unix 秒 |

接口有时带 `urgency`。滑块不用这个值，自己用时间戳重算。

## 一轮复习

```text
进入学习
  → 读取卡组的词条标签，并 GET 下一张（可带 tag_id）
有卡
  → 正面
  → 「显示答案」只翻面
  → 背面拖动间隔
  → 「下一张」PATCH：card_id + interval（秒，四舍五入）+ last_review（客户端当前 UTC 秒）
  → 成功：本轮计数 +1，展示预取的下一张或再 GET，卡面回到正面
  → 失败：停在当前卡，提示提交失败，不增加计数
无卡
  → 整组：这套卡组没有卡片
  → 带了标签：这个标签下没有卡片，可以清除筛选
```

其他动作：

| 动作 | 结果 |
| ---- | ---- |
| 隐藏 | 与「下一张」同类，但 body 是 `hidden: true`。成功后同样进入下一张并计入本轮次数 |
| 删除这张卡 | `DELETE` 该 card。再取下一张。不增加本轮次数。词条和其他 sibling 卡还在 |
| 编辑词条并保存 | 重新取卡。若保存前已经无卡，本轮计数会重置 |
| 切换标签 | 本轮计数、当前卡、预取、进度分母全部清掉，再按新标签取卡 |

同一次 PATCH 只能是「间隔 + last_review」或「隐藏」，不能混用。

预取：取卡响应里的 `next_card` 会先准备好。它和当前卡是同一张，或是隐藏卡，就丢掉。提交成功且预取有效时，不进入整页 loading，直接换成下一张。服务端如果在背后重排队列，当前正在看的卡不被换掉，新的下一张只进预取。

没有卡时点下一张，不会发 PATCH。

`DeckStudyReviewAgainRequested` 能重置本轮并重新取卡，界面没有绑这个事件。

## 间隔滑块

只在背面出现。没有预设按钮，是连续滑块，大约 100 档。左端文案是短间隔，右端是长间隔。

当前间隔 = `due_date - last_review`。若 ≤ 0，计算区间为 0，界面把滑块最大值做成最小值 + 1。

否则先取 `基准 = max(300, 当前间隔)`（不足 5 分钟按 5 分钟），紧急程度 = `(now - last_review) / 基准`：

- 已经到期（紧急程度 ≥ 1）：短 = 0.5 倍基准，中 = 2 倍，长 = 4 倍。
- 还没到期：从「1 倍基准」线性过渡到上述倍数。紧急程度为 0 时三档都是基准本身。
- 滑块初始停在中间档。若四舍五入后长短端重合，长端改为短端的 4 倍。

展示会把秒收成秒、分、小时、天、月（30 天）、年（12 个月）。

提交的是用户选定的秒数。新的 `due_date` 由服务端根据 interval 写回。服务端公式客户端未证实。

卡组上的 `minInterval` / `defInterval` / `maxInterval` 不参与这个滑块。

## 空队列、隐藏、标签、假期

- 响应里没有卡对象，或 `card` 是空数组，都当成没有卡。
- 服务端若仍返回 `hidden: true` 的卡，客户端丢弃，当作没有这张卡。预取同样过滤。
- 标签筛选把 `tag_id` 传给出卡和统计。标签下没有卡时用专用空态，不用整组的空文案。
- 假期重排：`POST /api/decks/{id}/reschedule` 只有路径和错误文案，学习流程没有调用。取卡响应里的 `meta.reschedule_suggested` 客户端未解析。

## 进度数字

学习页进度条是「本轮清掉的到期数 / 本轮开始时冻结的到期数」。

- 分母在进入这一轮或换过标签后，第一次拿到的到期数上冻结。
- 分子取「冻结值减去当前到期数」和「本轮已提交次数」里较大的那个，再不超过分母。这样服务端到期数反弹时，进度条不会掉回 0。
- 本轮已提交次数包含成功的评分和成功的隐藏，不包含删除卡，也不包含失败的提交。

这些数字和统计页不是同一套。统计页按卡组拉 7 / 30 / 90 / 365 天的每日复习次数（UTC），再算今日、合计、活跃天数、日均、星期分布。

卡组列表上的进度是「已见过的卡 / 总卡数」，也就是 `(cardsCount - unseenCards) / cardsCount`，不是到期进度。列表另外展示总复习次数、到期数、词条数。隐藏卡数量在统计字段里，学习页不显示。

## 离线

评分和隐藏是同步 PATCH。失败就停住，没有本地队列，之后也不会补传。见 [数据与媒体](knowledge_base_data_zh.md)。

## 代码入口

`lib/features/deck_study/`、`lib/screen/deck/deck_view_screen.dart`、`lib/screen/deck/deck_widgets/deck_view_body.dart`、`lib/screen/deck/deck_widgets/deck_view_interval_slider_controls.dart`、`lib/features/deck_study/domain/value_objects/review_interval_range.dart`、`lib/screen/deck/formatters/review_interval_label.dart`、`lib/services/apis/card_service.dart`、`lib/services/apis/review_stats_service.dart`。
