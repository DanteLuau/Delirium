# Delirium API Reference

> API lengkap dari source `src/` pada build saat ini (output: `dist/library.lua`).
> Dokumen ini disusun langsung dari kode source — jangan invent API yang tidak ada di sini.
> Berlaku untuk cabang `main` commit terakhir.

## 1. Loading

```lua
-- Studio / Rojo
local Delirium = require(game.ReplicatedStorage.Delirium)

-- Executor (raw GitHub build via loadstring)
local src = game:HttpGet("https://raw.githubusercontent.com/DanteLuau/Delirium/refs/heads/main/dist/library.lua")
local Delirium = loadstring(src)()

-- sementara load https://raw.githubusercontent.com/DanteLuau/Delirium/refs/heads/main/test.lua karna dist masih maintenance

assert(Delirium and Delirium.CreateWindow, "Delirium failed to load")
```

## 2. Struktur / Model Pemakaian

```text
Delirium
└── Window          (Delirium:CreateWindow)
    └── Tab         (Window:CreateTab) — punya kolom .Left dan .Right
        └── Elements  (Tab:CreateXxx atau kolom .Left/.Right:CreateXxx)
            └── visual divider  (CreateSection — hanya garis pembatas)
```

Catatan penting: komponen **dibuat langsung di Tab** (atau kolom `Tab.Left` / `Tab.Right`), **bukan** di dalam Section. Section hanyalah divider visual (garis + label).

## 3. Modul `Delirium` — Surface Publik

| Member | Tipe | Deskripsi |
|---|---|---|
| `Delirium:CreateWindow(props)` | `(WindowProps) -> Window` | Membuat window utama (satu-satunya entry point). |
| `Delirium.Flags` | `FlagsRegistry` | Registry flag persisten. |
| `Delirium.Icons` | `IconsModule` | Icon resolver (alias `NebulaIcons`). |
| `Delirium.NebulaIcons` | `IconsModule` | Alias dari `Icons`. |
| `Delirium.MediaService` | `MediaService` | Image/font/avatar service. |
| `Delirium.SaveManager` | `SaveManager` | Persistensi flag ke disk. |
| `Delirium._imageCache` | internal | Debug accessor internal — jangan dipakai. |
| `Delirium._image` | internal | Debug accessor internal — jangan dipakai. |

Tidak ada `Delirium:Notify`, `Delirium:Unload`, `Delirium:OnUnload`, `Delirium:SetTheme`, `Delirium:Docs` — API tersebut TIDAK ada di build ini.

## 4. `Delirium:CreateWindow(props)` → Window

```lua
local Window = Delirium:CreateWindow({
    name     = "My Script",          -- judul window
    subtitle = "v1.0",               -- sub-judul (opsional)
    theme    = "Default",            -- "Default" | "Light" | "Dracula" | tabel tema
    keybind  = Enum.KeyCode.RightShift, -- tombol toggle minimize (default RightShift)
    keepOnScreen = true,             -- kunci drag di layar (default true)
})
```

### `WindowProps`

| Field | Tipe | Default | Keterangan |
|---|---|---|---|
| `name` | `string?` | `"Delirium"` | Judul window. |
| `subtitle` | `string?` | `""` | Sub-judul di title bar. |
| `theme` | `string \| ThemeTable?` | `"Default"` | Nama tema terdaftar atau tabel tema parsial. |
| `keybind` | `EnumItem \| string?` | `Enum.KeyCode.RightShift` | Tombol global toggle minimize (juga bisa nama string `"RightShift"`). |
| `keepOnScreen` | `boolean?` | `true` | Cegah window terseret keluar layar. |

### Metode `Window` (public)

| Metode | Signatur | Keterangan |
|---|---|---|
| `CreateTab` | `(props: TabProps) -> Tab` | Tambah tab baru. |
| `Notify` | `(props: NotifyProps) -> ()` | Tampilkan notifikasi. |
| `Show` | `() -> ()` | Tampilkan window. |
| `Hide` | `() -> ()` | Sembunyikan window. |
| `ToggleHide` | `() -> ()` | Toggle antara Show/Hide. |
| `ToggleMinimise` | `() -> ()` | Toggle minimize ke pill (spelling Inggris). |
| `ChangeTheme` | `(input: string \| ThemeTable) -> ()` | Ganti tema; broadcast ke semua komponen. |
| `Unload` | `() -> ()` | Hapus window + bersihkan UI. |

### `Window.Notify(props)` — NotifyProps

```lua
Window:Notify({
    title    = "Saved",              -- judul kartu
    content  = "Profile written.",   -- isi pesan
    duration = 3,                    -- detik (0 = persisten)
    type     = "info",               -- "info" | "success" | "warning" | "error"
    icon     = nil,                  -- string/number id icon opsional
})

## 5. `Window:CreateTab(props)` → Tab

```lua
local Tab = Window:CreateTab({
    name    = "Main",
    icon    = "lucide:swords",       -- string icon opsional
    badge   = "v2",                  -- badge label opsional
    columns = 1,                     -- 1 (default) atau 2 kolom
})
```

### `TabProps`

| Field | Tipe | Keterangan |
|---|---|---|
| `name` | `string?` | Nama tab. |
| `icon` | `string?` | Icon resolvable (contoh `"lucide:swords"`). |
| `badge` | `string?` | Badge pendek di header tab. |
| `columns` | `number?` | Jumlah kolom; gunakan `.Left`/`.Right` untuk akses kolom kedua. |

### Metode & properti `Tab`

```lua
Tab.Left                        -- kolom kiri (TabColumn)
Tab.Right                       -- kolom kanan (TabColumn, jika columns >= 2)
Tab:CreateSection(props)        -- divider visual
Tab:CreateLabel(props)
Tab:CreateButton(props)
Tab:CreateToggle(props)
Tab:CreateSlider(props)
Tab:CreateInput(props)          -- textbox
Tab:CreateKeybind(props)
Tab:CreateDropdown(props)
Tab:CreateColorPicker(props)
-- varian kolom: CreateLeftXxx / CreateRightXxx sama daftar di atas
Tab:Show()
Tab:Hide()
Tab:Destroy()
```

Setiap factory juga tersedia di `Tab.Left` dan `Tab.Right` (mis. `Tab.Left:CreateToggle({...})` untuk tata letak 2 kolom).

## 6. Komponen

Semua props menerima nama lowercase (kanonik). Komponen tertentu juga menerima alias PascalCase (Slider/Dropdown) — lihat tabel masing-masing.

### 6.1 Section (divider)

```lua
Tab:CreateSection({ name = "General" })
```
Metode: `Destroy()`.
Catatan: Section **bukan container** — tidak ada `Section:CreateToggle` dll.

### 6.2 Label

```lua
local L = Tab:CreateLabel({
    text      = "<b>Hello</b>",     -- mendukung rich text (default true)
    richText  = true,
    textSize  = 13,
    textColor = Color3.fromRGB(255, 255, 255),
})
L:Set("New text")       -- ganti isi
L:Destroy()
```

### 6.3 Button

```lua
Tab:CreateButton({
    name        = "Start",
    description = "Mulai sistem.",
    callback    = function()
        print("clicked")
    end,
})
```
Metode: `Destroy()`.

### 6.4 Toggle

```lua
local T = Tab:CreateToggle({
    name        = "Enabled",
    description = "Aktifkan fitur.",
    flag        = "Enabled",         -- disimpan ke Delirium.Flags
    value       = false,             -- nilai awal
    callback    = function(v)        -- v: boolean
        print("Enabled:", v)
    end,
})
T:Set(true)              -- set nilai (memanggil callback)
T:Set(false, true)       -- set nilai tanpa memanggil callback
T.Destroy()              -- label salah:
T:Destroy()              -- benar
```

| Field | Tipe | Keterangan |
|---|---|---|
| `name` | `string?` | Judul. |
| `description` | `string?` | Deskripsi kecil. |
| `flag` | `string?` | Key flag. |
| `value` | `boolean?` | Nilai awal. |
| `callback` | `((v: boolean) -> ())?` | Dipanggil saat berubah. |

Handle: `T.value` (baca), `T:Set(value, skipCallback?)`, `T:Destroy()`.

### 6.5 Slider

```lua
local S = Tab:CreateSlider({
    name        = "Delay",
    description = "Detik antar aksi.",
    flag        = "Delay",
    min         = 0,                 -- alias: Min
    max         = 10,                -- alias: Max
    step        = 1,                 -- alias: increment / Step
    value       = 1,                 -- alias: default / Default
    suffix      = "s",               -- teks satuan opsional
    callback    = function(v)        -- v: number
        print("Delay:", v)
    end,
})
S:Set(5)                 -- set nilai
S:SetValue(5, true)      -- set nilai tanpa callback
S:SetEnabled(false)
local frame = S:GetFrame()
```

Field tambahan: `range = {min, max}` (pengganti min/max), `compact`, `hideMax`, `Tooltip`, `formatDisplayValue(slider, value)`, `enabled`, `layoutOrder`. Beberapa juga punya alias PascalCase (`Min`, `Max`, `Step`, `Default`, `Suffix`, `Compact`, `HideMax`, `Enabled`, `LayoutOrder`, `Callback`, `FormatDisplayValue`).

Handle: `S.value` / `S.Value`, `S.Changed` (internal signal), `S:Set`, `S:SetValue`, `S:SetEnabled`, `S:GetFrame()`, `S:Destroy()`.

### 6.6 Input (Textbox)

```lua
local I = Tab:CreateInput({
    name        = "Message",
    description = "Masukkan teks.",
    flag        = "Message",
    value       = "",                -- nilai awal
    placeholder = "Ketik di sini...",
    numeric     = false,             -- mode angka + ekpresi (mis. "5^3")
    clearOnFocus = false,
    callback    = function(text)     -- text: string
        print("Input:", text)
    end,
})
I:Set("New text")
I:Set("x", true)         -- set tanpa callback
I:Destroy()
```

### 6.7 Keybind

```lua
local K = Tab:CreateKeybind({
    name        = "Toggle UI",
    description = "Tekan tombol minimalkan window.",
    flag        = "UIToggleKey",
    value       = Enum.KeyCode.RightShift,   -- atau string "RightShift"
    hold        = false,             -- mode tahan (untuk hold-threshold)
    holdThreshold = 0.5,
    callback    = function(key)      -- key: EnumItem
        Window:ToggleMinimise()
    end,
    onChanged   = function(key)      -- opsional, event key berubah
        print("new key:", key.Name)
    end,
})
K:Set(Enum.KeyCode.K)
K:Set(Enum.KeyCode.K, true)   -- tanpa memicu onChanged
K:Destroy()
```

Tidak ada handle `OnChanged`/`OnActivated` public di build ini — gunakan props `callback` / `onChanged`.

### 6.8 Dropdown

```lua
local D = Tab:CreateDropdown({
    name        = "Mode",
    description = "Pilih mode.",
    flag        = "Mode",
    options     = { "Safe", "Fast", "Aggressive" },   -- atau tabel {Label=, Value=}
    value       = "Safe",           -- alias: default / Default
    multiSelect = false,            -- alias: MultiSelect (nilai jadi {string})
    searchable  = false,
    placeholder = "Pilih...",
    specialType = nil,              -- "Player" | "Team" (isi otomatis)
    callback    = function(v)
        print("Mode:", v)           -- string, atau table jika multiSelect
    end,
})
D:Set("Fast")
D:SetOptions({ "A", "B", "C" })
D:SetEnabled(false)
local frame = D:GetFrame()
D:Destroy()
```

Field alias PascalCase tersedia: `Options`, `Default`, `MultiSelect`, `Placeholder`, `Searchable`, `DisabledValues`, `FormatDisplayValue`, `MaxVisibleDropdownItems`, `SpecialType`, `Enabled`, `LayoutOrder`, `Callback`.

Handle: `D.value` / `D.Value`, `D.Changed` (internal), `D:Set`, `D:SetValue`, `D:SetOptions`, `D:SetEnabled`, `D:GetFrame()`, `D:Destroy()`.

### 6.9 ColorPicker

```lua
local C = Tab:CreateColorPicker({
    name      = "Accent",
    flag      = "Accent",
    color     = Color3.fromRGB(0, 170, 255),
    alpha     = 1,                  -- opsional (0-1)
    showAlpha = false,              -- tampilkan slider alpha
    callback  = function(color, alpha)
        print("Color:", color, alpha)
    end,
})
C:Set(Color3.fromRGB(255, 0, 0))     -- set warna
C:Set(Color3.fromRGB(255, 0, 0), 0.5, true)  -- set warna + alpha, tanpa callback
C:Destroy()
```

Handle: `C.value` (Color3), `C.alpha` (number), `C:Set(value, alpha?, skipCallback?)`, `C:Destroy()`.

## 7. `Delirium.Flags` — Flag Registry

Komponen stateful menulis nilainya ke registry saat berubah. Flag dapat dibaca dari luar kapan saja.

```lua
Delirium.Flags["Enabled"]          -- baca langsung (via metatable)
Delirium.Flags:Get("Enabled")      -- baca (nilai atau nil)
Delirium.Flags:Set("Enabled", true) -- tulis dari luar (tidak memicu callback)
Delirium.Flags:GetAll()            -- salinan seluruh tabel
Delirium.Flags:Clear()             -- kosongkan semua flag
```

| Tipe nilai | `boolean | number | string | { string } | Color3 | EnumItem` |

## 8. `Delirium.Icons` (alias `NebulaIcons`)

Icon pack: `Lucide`, `Material`, `Phosphor`, `Phosphor-Filled`, `SF`, `Symbols`, `Symbols-Filled`, `Lab`, `Fluency`.

```lua
Delirium.Icons.Resolve("lucide:swords")      -- "rbxassetid://..."
Delirium.Icons.Resolve(100604009889706)      -- angka -> "rbxassetid://..."
Delirium.Icons.Resolve("settings")           -- builtin fallback / Lucide / Symbols
Delirium.Icons.Resolve("rbxassetid://...")   -- dilewatkan apa adanya
Delirium.Icons.GetIcon("swords", "Lucide")   -- id number dari pack
Delirium.Icons.GetAssetUri("swords", "Lucide")
Delirium.Icons.PreloadPack("Lucide")         -- preload async
Delirium.Icons.nebulaIcons                   -- tabel icon bawaan Nebula
```

Format yang didukung `Resolve`: angka → `rbxassetid://`; `"123"` → id; `"rbxassetid://..."`/`"roblox://..."`/`"http..."` → langsung; `"prefix:nama"` (`lucide:`, `symbol:`, `material:`, `phosphor:`, `sf:`, `fluency:`, `lab:`); nama polos → fallback lalu Lucide lalu Symbols lalu builtin.

## 9. `Delirium.MediaService`

```lua
-- Gambar
MediaService:preloadImages({ [id] = "url" }, function(failed) end)
MediaService:assignImage(myLabel, "Image", 80384652)   -- auto-rebind saat selesai cache
MediaService:resolveImage(80384652)                    -- "rbxassetid://..." atau ""
MediaService:setOnBlock(function(value) end)           -- hook gambar gagal
-- Avatar
local uri = MediaService:avatar(userId, function(uri) end)
-- Font eksternal (manifest Roblox asset)
local fnt = MediaService:loadFont(12187277209, {
    weight = Enum.FontWeight.SemiBold,
    style  = Enum.FontStyle.Normal,
    saveToDisk = true,
    fallback = Font.fromEnum(Enum.Font.SourceSans),
})
MediaService:resolveFont(12187277209)
MediaService:bindFont(myLabel, "FontFace", 12187277209, { weight = Enum.FontWeight.SemiBold })
```

## 10. `Delirium.SaveManager`

Persistensi flag ke disk (executor filesystem).

```lua
-- Pola pemakaian standar:
SaveManager:SetFolder("MyScript")          -- opsional, default "Delirium"

local t = Tab:CreateToggle({ name = "God Mode", flag = "GodMode", value = false, callback = ... })
SaveManager:Register("GodMode", function(v) t:Set(v, true) end)
-- atau batch:
SaveManager:RegisterMany({
    GodMode  = function(v) t:Set(v, true) end,
    AutoFarm = function(v) af:Set(v, true) end,
})

SaveManager:Load()                         -- restore flags (returns count restored; no-op jika belum ada)
SaveManager:Save("profilku")               -- simpan ke profil (returns boolean sukses/gagal)
SaveManager:Refresh()                      -- re-push semua flag ke setter (sync setelah external Set)
SaveManager:List()                         -- { string } daftar profil tersimpan
SaveManager:Delete("profilku")             -- hapus profil (returns boolean)
SaveManager:BuildConfigTab(Window)         -- auto-buat tab "Config" lengkap
SaveManager:SetAutoSaveInterval(30)        -- detik, panggil sebelum BuildConfigTab
SaveManager:ScheduleAutoSave()             -- debounce 0.5s; panggil di dalam flag callback
SaveManager:StopAutoSave()                 -- hentikan loop (panggil di unload)
SaveManager.deriveFlagFromName("My Toggle") -- "my_toggle"
```

**Perubahan dari versi sebelumnya:**
- `Save()` dan `Load()` kini return value (boolean / number)
- `_scheduleAutoSave()` diganti `ScheduleAutoSave()` (public, non-underscore)
- `RegisterMany({ flag = setter })` baru — batch register satu call
- `Refresh()` baru — re-sync UI dari flags tanpa load dari disk
- `_activeProfile` internal — `BuildConfigTab` tidak lagi baca `.value` dari element (bug lama)
- `_pendingLoad` di-clear setiap `Load()` — tidak ada bleed antar load
- `Delete()` return false pada empty name (tidak hapus default secara diam-diam)

## 11. Tema

Tema bawaan: `"Default"` (dark), `"Light"`, `"Dracula"` (case-insensitive).

```lua
Window:ChangeTheme("Light")
Window:ChangeTheme("Default")
local MyTheme = {
    AccentColor      = Color3.fromRGB(0, 255, 128),
    BackgroundColor  = Color3.fromRGB(12, 12, 12),
    ContentColor     = Color3.fromRGB(255, 255, 255),
    CornerRoundness  = UDim.new(0, 10),
    TitleFont        = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.SemiBold),
}
Window:ChangeTheme(MyTheme)       -- tabel parsial di-merge di atas Default
```

Token tema utama (lihat `src/themes/default.luau` untuk daftar lengkap): `WindowColor`, `ShadowColor`, `SurfaceStroke`, `TitleBarColor`, `CornerRoundness`, `TabColor`, `TabBackground`, `ElementGradient`, `ElementStroke`, `ElementStrokeHover`, `ElementTransparency`, `ElementCornerRadius`, `TitleFont`, `Font`, `ContentColor`, `PlaceholderColor`, `AccentColor`, `AccentStroke`, `AccentGlow`, `ToggleTrack`, `ToggleKnobOff`, `SliderBackground`, `SliderProgress`, `FieldBackground`, `PillCornerRadius`, `NeutralButton`, `ErrorColor`, `ActionColor`, `LiveAnimation`.

## 12. Contoh cepat (Quick Example)

```lua
local Delirium = loadstring(game:HttpGet("https://raw.githubusercontent.com/DanteLuau/Delirium/refs/heads/main/dist/library.lua"))()
assert(Delirium and Delirium.CreateWindow)

local Window = Delirium:CreateWindow({ name = "Contoh", theme = "Default" })
local Tab = Window:CreateTab({ name = "Main" })

Tab:CreateSection({ name = "General" })

Tab:CreateToggle({
    name     = "Auto Farm",
    flag     = "AutoFarm",
    value    = false,
    callback = function(v)
        print("AutoFarm:", v)
        Window:Notify({ title = "AutoFarm", content = v and "ON" or "OFF", type = v and "success" or "warning", duration = 2 })
    end,
})

Tab:CreateKeybind({
    name     = "Toggle UI",
    value    = Enum.KeyCode.RightShift,
    callback = function()
        Window:ToggleMinimise()
    end,
})
```