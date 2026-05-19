# IM 常见 Bug 模式与排查路径

## 未读数异常（翻倍 / 不清零）

排查路径：
1. 搜索 `unreadCount` 更新逻辑（BTIMService）
2. 检查重连后是否重复注册监听器
3. 检查 markRead 是否正确触发

常见根因：重连后重复拉取历史消息；本地 DB 与内存状态不同步

## 消息发送状态卡住

排查路径：
1. 搜索 `MessageStatus` / `sendMessage`（BTIMService）
2. 检查 SDK 回调是否正确处理超时
3. 检查重试机制

常见根因：SDK 回调在非主线程更新 UI；超时后状态未置为 failed

## 消息列表 UI 错位 / 重复

排查路径：
1. 找 ViewModel 消息列表更新逻辑（BTIMModule）
2. 检查 diff 算法 / reload 时机
3. 检查 cell reuse 逻辑

常见根因：异步更新未在主线程执行；insertRows 与 reloadData 混用

## 崩溃（EXC_BAD_ACCESS / index out of range）

排查路径：
1. 查看 crash 堆栈，定位具体文件和方法
2. 检查多线程并发访问同一数据结构
3. 检查消息列表在 tableView 更新期间被修改

常见根因：主线程 UI 操作与后台数据更新竞争；weak 引用在回调时已释放
