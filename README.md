# VoiceInputApp — iOS 语音输入法（BYOK）

iOS 语音输入法 + 主 App。用户自带 ASR / LLM API key，键盘扩展通过切回主 App 录音、识别、AI 润色，结果回传插入光标。极客向，纯客户端无后端。

## 技术栈

- Swift 5.10+ / iOS 17.0+
- 主 App：SwiftUI
- 键盘扩展：UIKit + `UIInputViewController`
- 音频：AVAudioEngine + Silero VAD（ONNX Runtime）
- 网络：URLSession + SSE 流式
- 持久化：SwiftData（历史） + App Group 共享容器（IPC） + Keychain（API key）
- 包管理：Swift Package Manager

## 工程结构

```
VoiceInputApp/                  # 主 App target
KeyboardExtension/              # 键盘扩展 target
SharedKit/                      # 共享 Swift Package（主 App + 键盘）
project.yml                     # XcodeGen 配置，运行 `xcodegen` 生成 .xcodeproj
```

详细分层见 [docs/architecture.md](docs/architecture.md)。

## 数据流

```
[键盘] 点话筒 → extensionContext.open("voiceinput://record?session=UUID")
[主 App] 接 URL → 切前台 → AudioRecorder + SileroVAD 录音
       → ASRProvider.transcribe(audio) → 原始转写
       → LLMProvider.process(rawText, prompt, context) → 润色文本（流式）
       → 写 SharedStore (App Group) → DarwinNotifier.post("result.ready")
[键盘] 收到 Darwin 通知 → 读 SharedStore → textDocumentProxy.insertText
```

## 默认 Provider（首发）

| 类型 | 模型 | 协议 |
|---|---|---|
| ASR | Qwen3-ASR-Flash（DashScope） | DashScope / OpenAI 兼容 |
| LLM | MiMo-V2.5（小米） | OpenAI ChatCompletions |

任何 OpenAI 兼容 endpoint 用户都可自行填入（DeepSeek / Kimi / 自部署 vLLM 等）。

## 起项目

```bash
brew install xcodegen
xcodegen generate
open VoiceInputApp.xcodeproj
```

`SharedKit/` 是独立 Swift Package，可单独 `swift build` / `swift test` 验证。

## MVP 范围（v1.0）

- [x] 键盘扩展 ↔ 主 App IPC（URL Scheme + Darwin Notification + App Group）
- [x] ASRProvider / LLMProvider 协议
- [x] Qwen3-ASR-Flash + MiMo-V2.5 实现
- [x] 用户自定义 endpoint + key（OpenAI 兼容）
- [x] 4 个预置 Prompt 模板（通用 / 公文 / 微信 / 邮件）
- [x] 历史记录（最近 50 条）
- [x] 三步新手引导（权限 / API key / 启用键盘）

**不做**：灵动岛 / Action Button / 流式增量插入 / 本地模型（Whisper/Paraformer）/ TTS / 账号系统 / 订阅 / 云同步。

## 关键工程坑

1. **键盘扩展内存上限 ~70MB** — 重计算（VAD、网络、推理）必须在主 App 跑。
2. **Full Access 检查** — `hasFullAccess == false` 时键盘无法访问 App Group。
3. **Darwin Notification 无 payload** — 信号 + SharedStore 拉取数据。
4. **AVAudioSession** — 主 App 启动立即激活，category `.record`，options `.duckOthers`。
5. **API Key 存 Keychain** —`kSecAttrAccessGroup` 配 App Group。
6. **录音格式** — 内部 16kHz mono Float32，发请求前转 WAV/PCM16。
7. **MiMo 默认禁用 thinking** —`extra_body: {"thinking": {"type": "disabled"}}` 降延迟。

## License

MIT
