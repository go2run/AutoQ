# AutoQ -> MiniAutoQ (Lean 4) 拆分分析與計畫

## Context

AutoQ 是一個用 C++ 實作的量子程式驗證工具，使用**非確定性有限樹自動機 (NFTA)** 來驗證量子程式的部分正確性（Hoare triple `{P} C {Q}`）。目標是將 AutoQ 的核心驗證邏輯**逐步**移植到 MiniAutoQ（Lean 4），以獲得形式化驗證保證。

範圍：先從**基本的樹自動機資料結構**開始，一小部分就好。Inclusion checking 的 Z3 依賴先不處理。

---

## 待辦清單（第一階段）

- [ ] 1. 在 MiniAutoQ repo 初始化 Lean 4 lake 專案
- [ ] 2. 實作 FiveTuple 複數結構（對應 `fivetuple.hh`）
- [ ] 3. 實作 Symbol 類型（對應 `concrete.hh`）
- [ ] 4. 實作 Automata 樹自動機核心結構（對應 `aut_description.hh`）
- [ ] 5. 撰寫測試：構造 zero(1) 自動機實例並驗證
- [ ] 6. Commit 並 push 到指定分支

---

## 第一階段架構圖

```
                    AutoQ (C++)                           MiniAutoQ (Lean 4)
                    ──────────                            ─────────────────

                ┌──────────────────┐                  ┌──────────────────┐
                │  fivetuple.hh    │     ────>        │  FiveTuple.lean  │
                │  [a,b,c,d,k]    │   移植            │  structure       │
                │  332 lines       │                  │  FiveTuple       │
                └───────┬──────────┘                  └───────┬──────────┘
                        │ 被引用                               │ import
                        v                                      v
                ┌──────────────────┐                  ┌──────────────────┐
                │  concrete.hh     │     ────>        │  Symbol.lean     │
                │  internal|leaf   │   移植            │  inductive       │
                │  111 lines       │                  │  Symbol          │
                └───────┬──────────┘                  └───────┬──────────┘
                        │ 被引用                               │ import
                        v                                      v
                ┌──────────────────┐                  ┌──────────────────┐
                │aut_description.hh│     ────>        │  Automata.lean   │
                │  Automata<TT>    │   移植            │  structure       │
                │  ~100 lines 核心  │  (去掉debug)     │  Automata        │
                └──────────────────┘                  └──────────────────┘

          不移植:                                移植範圍:
          - autoq.hh (debug macros)             - FiveTuple 算術 (+,-,*,/)
          - query.cc (print/stats)              - Symbol (internal/leaf)
          - profiling static members            - Automata (states, transitions)
          - timbuk_parser (1942行)              - zero(1) 測試實例
          - execute.cc, simulation/
```

---

## AutoQ 架構總覽（C++ 原始碼分析）

### 核心元件（需要移植）

| 元件 | 來源檔案 | 行數 | 說明 |
|------|----------|------|------|
| **FiveTuple 複數** | `include/autoq/complex/fivetuple.hh` | 332 | `[a,b,c,d,k]` 精確複數表示 |
| **Concrete Symbol** | `include/autoq/symbol/concrete.hh` | 111 | 葉節點=複數振幅, 內部節點=qubit 編號 |
| **Automata 結構** | `include/autoq/aut_description.hh` | 328 | 狀態、轉移、final states |
| **General Ops** | `src/general.cc` | 370 | union(∥), intersection(∧), tensor product(⊗) |
| **Gate Ops** | `src/gate.cc` | 1627 | X, H, Z, CX, CZ... 量子閘 |
| **Reduction** | `src/reduce.cc` | 866 | remove_useless, state_renumbering 等 |
| **Inclusion** | `src/inclusion.cc` | 2798 | 語言包含=核心驗證（依賴 Z3） |

### 不需移植的部分

| 類別 | 檔案 | 原因 |
|------|------|------|
| Debug/Log | `autoq.hh` (macros), `query.cc` (print_*, count_*) | 純 debug |
| CLI | `cli/autoq.cc` | 介面層 |
| 解析器 | `timbuk_parser-nobison.cc` (1942行), `ExtendedDirac/`, `parsing/` | IO 層 |
| 序列化 | `timbuk_serializer.cc`, `serialization/` | IO 層 |
| 電路執行 | `execute.cc` (QASM 解析+編排) | 編排層 |
| 迴圈/參數化 | `loop_summarization.cc`, `parameterized.cc` | 進階功能 |
| 模擬工具 | `simulation/` (LTS, binary_relation) | 優化用 |
| 記憶體/工具 | `util/memory.cpp`, `util/string.cc` | C++ 特定 |
| Profiling 成員 | `aut_description.hh` 中 `gateCount`, `*_time` 等 | 純效能計量 |
| Benchmark 實例 | `instance.cc` (大部分) | 測試用 |

---

## 第一步實作：樹自動機基本資料結構

### 要做的事

1. **初始化 Lean 4 lake 專案**（MiniAutoQ repo）
2. **FiveTuple** — 精確複數表示（`MiniAutoQ/Complex/FiveTuple.lean`）
3. **Symbol** — 自動機符號類型（`MiniAutoQ/Symbol.lean`）
4. **Automata** — 樹自動機核心結構（`MiniAutoQ/Automata.lean`）
5. **簡單測試** — 構造一個小型自動機實例，驗證結構正確

### 詳細對應

#### Step 1: FiveTuple（對應 `fivetuple.hh`）

C++ 定義（`include/autoq/complex/fivetuple.hh:21-22`）:
```cpp
struct FiveTuple : vector<cpp_int> {  // [a, b, c, d, k]
    // (a + b·(1+i)/√2 + c·i + d·(-1+i)/√2) / √2^k
```

Lean 版本:
```lean
structure FiveTuple where
  a : Int; b : Int; c : Int; d : Int; k : Int
```

移植的操作（只需核心算術）:
- `+`, `-`（`binary_operation`, 行 303-318）: 先對齊 k，再逐元素加減
- `*`（行 90-97）: 四元乘法公式 + k 相加
- `isZero`（行 248-249）: a=b=c=d=0
- `fraction_simplification`（行 123-132）: 當 a,b,c,d 都是偶數時除以 2
- `increase_k`（行 268-279）: 升級 k 值
- `counterclockwise` / `clockwise`（行 138-191）: 以 π/4 為單位旋轉
- `divide_by_the_square_root_of_two`（行 133-137）: k += 1

**不移植**: `realToSMT`/`imagToSMT`（Z3）, `abs2`（浮點）, `toInt`/`to_rational`, `Rand`

#### Step 2: Symbol（對應 `concrete.hh`）

C++ 定義（`include/autoq/symbol/concrete.hh:24-28`）:
```cpp
struct Concrete {
    bool internal;
    Complex::Complex complex;  // FiveTuple
```

Lean 版本:
```lean
inductive Symbol where
  | internal (qubit : Nat)
  | leaf (val : FiveTuple)
```

移植的操作:
- `is_internal`, `is_leaf`（pattern match）
- `qubit`（取 internal 的值）
- `+`, `-`, `*`（葉節點的 FiveTuple 運算, 行 58-68）
- `<` 排序（internal < leaf, 行 71-75）

#### Step 3: Automata（對應 `aut_description.hh`）

C++ 定義（`include/autoq/aut_description.hh:52-118`）:
```cpp
template <typename TT> struct Automata {
    typedef int64_t State;
    typedef pair<Symbol, Tag> SymbolTag;
    typedef map<SymbolTag, map<State, set<StateVector>>> TopDownTransitions;
    StateVector finalStates;
    State stateNum;
    int qubitNum;
    TopDownTransitions transitions;
```

Lean 版本:
```lean
abbrev State := Int
abbrev Tag := Nat  -- color bitset
structure SymbolTag where
  symbol : Symbol
  tag : Tag

structure Automata where
  finalStates : List State
  stateNum : Nat
  qubitNum : Nat
  transitions : Std.RBMap SymbolTag (Std.RBMap State (List (List State))) compare
```

移植的概念:
- `SymbolTag` 的 `Ord` instance（`aut_description.hh:83-96`）
- `tag_intersection`（bitwise AND, 行 78）
- 空的 Automata 構造（行 129-151，去掉 LOG 部分）

**不移植**: 所有 `inline static` 成員（gateCount, *_time 等）、name 字串

#### Step 4: 簡單測試

用 `instance.cc` 中的 `zero(n)` 函數（行 92-125）構造一個 1-qubit |0⟩ 狀態的自動機作為測試：
```
Final States: [0]
Transitions:
  [1, tag=1]: 0 -> {[2, 1]}    -- internal, qubit 1
  [Zero, tag=1]: 1 -> {[]}     -- leaf, amplitude 0
  [One, tag=1]: 2 -> {[]}      -- leaf, amplitude 1
stateNum: 3, qubitNum: 1
```

### 關鍵檔案參考

- `include/autoq/complex/fivetuple.hh` — FiveTuple 完整實作
- `include/autoq/complex/complex.hh:9-36` — `is_complex` concept（Lean 中用 typeclass）
- `include/autoq/symbol/concrete.hh` — Concrete symbol
- `include/autoq/aut_description.hh:52-118` — Automata 結構定義
- `src/instance.cc:92-125` — `zero(n)` 測試用實例

### 建議的專案結構

```
MiniAutoQ/
├── lakefile.lean
├── MiniAutoQ.lean              -- import all
├── MiniAutoQ/
│   ├── Complex/
│   │   └── FiveTuple.lean      -- Step 1
│   ├── Symbol.lean             -- Step 2
│   └── Automata.lean           -- Step 3
```

### 驗證方式
- `lake build` 通過
- `#eval` 測試 FiveTuple 算術（例如：One * One = One, H 閘相關值）
- 構造 `zero(1)` 自動機實例，列印驗證

---

## 驗證方式

1. `lake build` 編譯通過
2. `#eval` 測試 FiveTuple 基本運算：
   - `FiveTuple.mk 1 0 0 0 0` 表示 1
   - `FiveTuple.mk 0 0 0 0 0` 表示 0
   - 乘法: One * One = One
   - 加法: Zero + One = One
3. 構造 `zero(1)` 自動機：有 3 個狀態、3 個轉移，驗證結構
4. 與 C++ 版本結果比對

---

## 未來路線圖（Phase 4-6，之後再做）

| 階段 | 內容 | 行數 | 來源 |
|------|------|------|------|
| Phase 4 | Union / Intersection / TensorProduct | ~370 | `general.cc` |
| Phase 4.5 | remove_useless / state_renumbering | ~200 | `reduce.cc` 部分 |
| Phase 5 | 量子閘 (X, Z, H → CX, CCX) | ~1627 | `gate.cc` |
| Phase 6a | Emptiness check | ~90 | `inclusion.cc` 部分 |
| Phase 6b | Inclusion (不含 Z3) | ~500+ | `inclusion.cc` 部分 |
| Phase 6c | Scaled Inclusion (需 Z3 替代) | ~2000+ | `inclusion.cc` 部分 |

每個階段都是前一階段的自然延伸，可以逐步推進。
