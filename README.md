# ⚡ FlashForge

![iOS](https://img.shields.io/badge/iOS-17.0%2B-black?logo=apple) ![Swift](https://img.shields.io/badge/Swift-5.9-F05138?logo=swift&logoColor=white) ![Privacy](https://img.shields.io/badge/Privacy-First-success) ![License](https://img.shields.io/badge/License-Apache%202.0-blue)

> **Smart Flashcards with Spaced Repetition. Study Smarter, Not Harder.**
> **과학적 간격 반복 알고리즘으로 기억력을 극대화하는 플래시카드 앱.**

---

<br>

## 📱 About the App

**FlashForge** is a beautifully crafted, fully offline flashcard study app powered by a hybrid spaced repetition engine. Combining the proven **SM-2 (Anki)** algorithm with the cutting-edge **FSRS (Free Spaced Repetition Scheduler)**, FlashForge optimizes your review intervals to maximize long-term retention with minimal effort.

**FlashForge**는 검증된 **SM-2(Anki)** 알고리즘과 최신 **FSRS** 알고리즘을 결합한 하이브리드 간격 반복 엔진을 탑재한 플래시카드 학습 앱입니다. 서버도, 회원가입도, 개인정보 수집도 없습니다. 모든 학습 데이터는 오직 당신의 기기에만 저장됩니다.

<br>

## ✨ Key Features / 주요 기능

### 🧠 Hybrid Spaced Repetition (하이브리드 간격 반복)
- **Dual Algorithm Engine:** Combines classic Anki SM-2 with modern FSRS for scientifically optimized review scheduling.
- **Adaptive Scheduling:** 17-parameter FSRS model dynamically adjusts to your learning patterns.
- **4-Grade Feedback:** Rate each card as Again, Hard, Good, or Easy for precise scheduling.
- **이중 알고리즘 엔진:** 클래식 SM-2와 최신 FSRS를 결합한 과학적 복습 스케줄링.
- **적응형 스케줄링:** 17개 매개변수 FSRS 모델이 학습 패턴에 맞춰 자동 조정됩니다.
- **4단계 피드백:** Again, Hard, Good, Easy로 세밀한 스케줄링이 가능합니다.

### 🃏 Deck & Card Management (덱 & 카드 관리)
- **Unlimited Decks:** Organize flashcards into topic-based decks.
- **Rich Card Content:** Each card supports front (question), back (answer), and optional notes.
- **Smart Queues:** Separate Learning and Review queues for focused study sessions.
- **무제한 덱:** 주제별로 플래시카드를 자유롭게 분류하세요.
- **풍부한 카드 콘텐츠:** 질문, 답변, 메모를 각 카드에 기록할 수 있습니다.
- **스마트 큐:** 학습(Learning)과 복습(Review) 큐를 분리하여 집중 학습이 가능합니다.

### 🎨 Glassmorphism UI (글래스모피즘 UI)
- **Glass Card Design:** Stunning frosted-glass card interface with blur effects and translucency.
- **Smooth Animations:** Card reveal with cross-dissolve transitions and 3D perspective drag.
- **Dark Gradient Theme:** Modern dark UI with ambient glow effects.
- **글래스 카드 디자인:** 블러 효과와 투명감이 돋보이는 아름다운 유리 질감 카드.
- **부드러운 애니메이션:** 크로스 디졸브 전환과 3D 원근 드래그 효과.
- **다크 그라데이션 테마:** 앰비언트 글로우가 적용된 모던 다크 UI.

### 📊 Study Analytics (학습 분석)
- **140-Day Heatmap:** Visual review activity calendar to track study consistency.
- **Due Card Summary:** Real-time display of learning and review card counts.
- **Progress Tracking:** Monitor card states — New, Learning, Review, Relearning.
- **140일 히트맵:** 학습 활동 캘린더로 꾸준한 공부 습관을 확인하세요.
- **복습 카드 요약:** 학습/복습 카드 수를 실시간으로 보여줍니다.
- **진도 추적:** New → Learning → Review → Relearning 카드 상태를 모니터링합니다.

### 🔔 Daily Reminders (학습 알림)
- **Push Notifications:** Configurable daily study reminders to build consistent habits.
- **Custom Timing:** Set your preferred reminder time.
- **푸시 알림:** 매일 학습 습관을 유지할 수 있도록 알림을 설정하세요.
- **맞춤 시간 설정:** 원하는 시간에 알림을 받을 수 있습니다.

### 💾 Data Portability (데이터 이식성)
- **Full Backup:** Export all decks, cards, and review history as `.ffbackup` files.
- **Easy Restore:** Import backups with preview before applying.
- **100% Offline:** All data stays on your device. No servers, no sign-ups.
- **전체 백업:** 덱, 카드, 복습 기록을 `.ffbackup` 파일로 내보낼 수 있습니다.
- **간편 복원:** 적용 전 미리보기와 함께 백업을 가져올 수 있습니다.
- **100% 오프라인:** 모든 데이터는 기기에만 저장됩니다. 서버도, 회원가입도 없습니다.

### 🌍 Localization (다국어 지원)
- **2 Languages:** English and Korean.
- **2개 국어 지원:** 영어, 한국어를 지원합니다.

<br>

## 📸 Screenshots

> Screenshots coming soon.

<!--
| Study | Decks | Card Detail | Settings |
|:---:|:---:|:---:|:---:|
| <img src="Screenshots/1.png" alt="Study" width="200" /> | <img src="Screenshots/2.png" alt="Decks" width="200" /> | <img src="Screenshots/3.png" alt="Card Detail" width="200" /> | <img src="Screenshots/4.png" alt="Settings" width="200" /> |
-->

<br>

---

## 🛠 Tech Stack

| Category | Technology |
|---|---|
| **Language** | Swift 5.9 |
| **UI Framework** | UIKit (Programmatic) |
| **Architecture** | MVVM |
| **Local Storage** | SwiftData |
| **Layout** | SnapKit |
| **Concurrency** | Swift Concurrency (async/await, Actor) |
| **Scheduling** | SM-2 (Anki) + FSRS Hybrid |
| **Project Management** | Tuist |

<br>

---

## 🚀 Getting Started

This project uses [Tuist](https://tuist.io) for project generation and dependency management.

### Prerequisites
- Xcode 16.0 or later
- [Tuist](https://docs.tuist.io/guides/quick-start/install-tuist/) installed

### Installation

```bash
# Install Tuist (if not already installed)
curl -Ls https://install.tuist.io | bash

# Generate project and install dependencies
make install
```

This will run `tuist install` and `tuist generate` to set up the Xcode workspace.

### Available Commands

| Command | Description |
|---|---|
| `make install` | Install dependencies and generate Xcode project |
| `make clean` | Remove generated project files |

### Opening in Xcode

1. Open the workspace:
   ```bash
   open FlashForge.xcworkspace
   ```

2. **Important:** Select the correct scheme and destination
   - **Scheme:** Choose `FlashForge`
   - **Destination:** Select an iOS Simulator (e.g., iPhone 16)

3. Press `Cmd+R` to build and run

<br>

---

## 📂 Project Structure

```
FlashForge/
├── App/                    # AppDelegate, SceneDelegate
├── Models/                 # Domain models, FSRS parameters
├── Services/               # CardRepository, FSRSScheduler, AnkiScheduler
├── ViewModels/             # HomeViewModel, DecksViewModel, DeckDetailViewModel
├── ViewControllers/        # Study, Decks, DeckDetail, CardEditor, More, Onboarding
├── Views/                  # GlassCardView, ReviewHeatmapView
├── Resources/
│   ├── en.lproj/           # English
│   └── ko.lproj/           # 한국어
├── Tests/                  # Unit tests
├── Tuist/                  # Tuist project configuration
└── Makefile
```

<br>

---

## 💜 Support Me

<div align="left">
  <a href="https://buymeacoffee.com/bbdyno" target="_blank">
    <img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" height="45" width="174" />
  </a>
</div>

<br>

<details>
<summary>
  <b>🪙 Crypto Donation (BTC / ETH)</b><br>
  <span style="font-size: 0.8em; color: gray;">Click to see QR Codes & Addresses</span>
</summary>

<br>

<table>
  <tr>
    <td align="center" width="200">
      <img src="https://img.shields.io/badge/Bitcoin-FF9900?style=for-the-badge&logo=bitcoin&logoColor=white" height="30"/>
      <br><br>
      <img src="https://api.qrserver.com/v1/create-qr-code/?size=150x150&data=bc1qz5neag5j4cg6j8sj53889udws70v7223zlvgd3" width="120" alt="BTC QR">
      <br><br>
      <a href="bitcoin:bc1qz5neag5j4cg6j8sj53889udws70v7223zlvgd3"><b>Send BTC ↗</b></a>
    </td>
    <td align="center" width="200">
      <img src="https://img.shields.io/badge/Ethereum-3C3C3D?style=for-the-badge&logo=ethereum&logoColor=white" height="30"/>
      <br><br>
      <img src="https://api.qrserver.com/v1/create-qr-code/?size=150x150&data=0x5f35523757d0e672fa3ffbc0f1d50d35fd6b2571" width="120" alt="ETH QR">
      <br><br>
      <a href="ethereum:0x5f35523757d0e672fa3ffbc0f1d50d35fd6b2571"><b>Send ETH ↗</b></a>
    </td>
  </tr>
</table>

<blockquote>
<p><b>BTC:</b> <code>bc1qz5neag5j4cg6j8sj53889udws70v7223zlvgd3</code></p>
<p><b>ETH:</b> <code>0x5f35523757d0e672fa3ffbc0f1d50d35fd6b2571</code></p>
</blockquote>

</details>

<br>

> **Thanks for your support!** 🎁
>
> 🇰🇷 커피 한 잔의 후원은 저에게 큰 힘이 됩니다. 감사합니다! <br>
> 🇺🇸 Thanks for the coffee! Your support keeps me going. <br>
> 🇸🇦 شكراً على القهوة! دعمك يعني لي الكثير. <br>
> 🇩🇪 Danke für den Kaffee! Deine Unterstützung motiviert mich. <br>
> 🇫🇷 Merci pour le café ! Votre soutien me motive. <br>
> 🇪🇸 ¡Gracias por el café! Tu apoyo me motiva a seguir. <br>
> 🇯🇵 コーヒーの差し入れ、ありがとうございます！励みになります。 <br>
> 🇨🇳 感谢请我喝杯咖啡！您的支持是我最大的动力。 <br>
> 🇮🇩 Terima kasih traktiran kopinya! Dukunganmu sangat berarti.
