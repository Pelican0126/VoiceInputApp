# 架构

## Target 拓扑

```
VoiceInputApp (.app)
├── 嵌入 KeyboardExtension (.appex)
└── 依赖 SharedKit (Swift Package)

KeyboardExtension (.appex)
└── 依赖 SharedKit
```

`SharedKit` 同时被主 App 和键盘扩展引用，所有跨进程类型与协议在此定义。

## 跨进程通信

| 渠道 | 用途 | 容量 | 方向 |
|---|---|---|---|
| URL Scheme `voiceinput://` | 键盘 → 主 App 触发录音 | URL 长度 | 单向 |
| Darwin Notification | 主 App → 键盘（信号） | 仅信号，无 payload | 双向 |
| App Group `UserDefaults` | 共享小数据（session ID、context、最终文本） | 1MB 内 | 双向 |
| Keychain (`kSecAttrAccessGroup`) | API Key | 字符串 | 双向 |

录音 PCM **不**走共享容器——主 App 自己录、自己上传，结果文本回传时只是几百字节。

## 一次会话的时序

```
KeyboardExt                  Main App
     │                            │
     │ 1. 用户点 mic               │
     │ 2. 写 SharedStore           │
     │    (sessionID, context)     │
     │ 3. open URL ───────────────▶│
     │                             │ 4. 接 URL，切前台
     │                             │ 5. AVAudioSession 激活
     │                             │ 6. AudioRecorder.start
     │                             │ 7. SileroVAD 检测停顿
     │                             │ 8. recorder.stop
     │                             │ 9. ASRProvider.transcribe
     │                             │ 10. LLMProvider.process (流式)
     │                             │ 11. SharedStore.writeResult
     │                             │ 12. DarwinNotifier.post(.resultReady)
     │ 13. 收到 Darwin 通知 ◀───────│
     │ 14. SharedStore.consumeResult
     │ 15. textDocumentProxy.insertText
     │                             │ 16. dismiss / route .home
```

## SharedKit 模块

```
SharedKit/
├── Models/        — 跨进程的值类型（Codable）
├── Providers/     — ASRProvider / LLMProvider 协议 + 内置实现
├── Audio/         — AVAudioEngine 封装、VAD、WAV 编码
├── Pipeline/      — 录音 → ASR → LLM 的编排器
└── IPC/           — App Group 容器、Darwin Notification、Keychain
```

`Providers/` 中所有 Provider 都通过 `ProviderRegistry.shared` 注册和查找。新增 Provider：

1. 实现 `ASRProvider` 或 `LLMProvider` 协议；
2. 在 `ProviderRegistry.registerDefaults()` 中注册；
3. 主 App 设置页面会自动列出。

## 内存与性能约束

- 键盘扩展 < 70MB：所有重计算（VAD、网络、JSON 解析）都在主 App。键盘扩展只渲染 UI、读 SharedStore、调 textDocumentProxy。
- 主 App 录音格式统一为 16kHz mono Float32，发请求前 `WAVEncoder.encode` 转 PCM16 WAV。
- LLM 流式响应使用 `URLSession.bytes(for:)` 解析 SSE，逐 delta append 到 UI 与最终文本。
- VAD 默认采用能量门限实现（`EnergyVAD`）。`SileroVAD` 是 `EnergyVAD` 的占位封装，待接入 ONNX Runtime 后替换为真正的 Silero 推理。
