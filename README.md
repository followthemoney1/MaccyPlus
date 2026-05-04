
<img width="587" height="338" alt="Screenshot 2026-05-04 at 21 56 37" src="https://github.com/user-attachments/assets/0def518f-6925-483f-84dc-8d4f1de609c4" />

![Auto-playing GIF](docs/Area3.gif)

# [MaccyPlus](https://github.com/followthemoney1/MaccyPlus)

[![Downloads](https://img.shields.io/github/downloads/followthemoney1/MaccyPlus/total.svg)](https://github.com/followthemoney1/MaccyPlus/releases/latest)

MaccyPlus is a lightweight clipboard manager for macOS with a built-in **Commands** library. It keeps the history of what you copy, lets you quickly navigate and search previous clipboard contents, and lets you save reusable commands with smart variables.

Based on [Maccy](https://github.com/p0deje/Maccy) by Alex Rodionov. MaccyPlus works on macOS Sonoma 14 or higher.



<!-- vim-markdown-toc GFM -->

* [Features](#features)
* [Commands Tab](#commands-tab)
  * [Smart Variables](#smart-variables)
* [Install](#install)
* [Usage](#usage)
  * [Clipboard History](#clipboard-history)
  * [Commands](#commands)
* [Advanced](#advanced)
  * [Ignore Copied Items](#ignore-copied-items)
  * [Ignore Custom Copy Types](#ignore-custom-copy-types)
  * [Speed up Clipboard Check Interval](#speed-up-clipboard-check-interval)
* [FAQ](#faq)
  * [Why doesn't it paste when I select an item in history?](#why-doesnt-it-paste-when-i-select-an-item-in-history)
  * [When assigning a hotkey to open MaccyPlus, it says that this hotkey is already used in some system setting.](#when-assigning-a-hotkey-to-open-maccyplus-it-says-that-this-hotkey-is-already-used-in-some-system-setting)
  * [How to restore hidden footer?](#how-to-restore-hidden-footer)
  * [How to ignore copies from Universal Clipboard?](#how-to-ignore-copies-from-universal-clipboard)
  * [My keyboard shortcut stopped working in password fields. How do I fix this?](#my-keyboard-shortcut-stopped-working-in-password-fields-how-do-i-fix-this)
* [Translations](#translations)
* [License](#license)

<!-- vim-markdown-toc -->

## Features

* Lightweight and fast
* Keyboard-first
* Secure and private
* Native UI
* Open source and free
* **Commands tab** — save reusable text snippets with smart variables
* **Folders** — organize commands into folders
* **Per-command hotkeys** — trigger any command from anywhere with a global shortcut
* **Smart variables** — `%CLIPBOARD%`, `%DATE%`, `%TIME%`, `%UUID%`, `%INPUT:label%`

## Commands Tab

MaccyPlus adds a second mode to the popup: **Commands**. Switch between History and Commands using the segmented picker at the top of the panel, or press <kbd>CONTROL (⌃)</kbd> + <kbd>TAB</kbd>.

Commands are persistent text snippets that live until you delete them. Click a command to expand its variables and auto-paste the result.

### Smart Variables

Use these placeholders in a command body. They expand at paste time:

| Variable | Expands to |
|----------|-----------|
| `%CLIPBOARD%` | Current clipboard contents |
| `%DATE%` | Today's date (ISO 8601) |
| `%TIME%` | Current time (HH:mm:ss) |
| `%UUID%` | A new random UUID |
| `%INPUT:label%` | Prompts you for a value before pasting (in-place form inside the panel) |

Multiple `%INPUT:label%` tokens with different labels each get their own field. Expansion is single-pass — pasted values are not re-scanned for tokens.

## Install

Download the latest version from the [releases](https://github.com/followthemoney1/MaccyPlus/releases/latest) page.

## Usage

### Clipboard History

1. <kbd>SHIFT (⇧)</kbd> + <kbd>COMMAND (⌘)</kbd> + <kbd>C</kbd> to popup MaccyPlus or click on its icon in the menu bar.
2. Type what you want to find.
3. To select the history item you wish to copy, press <kbd>ENTER</kbd>, or click the item, or use <kbd>COMMAND (⌘)</kbd> + `n` shortcut.
4. To choose the history item and paste, press <kbd>OPTION (⌥)</kbd> + <kbd>ENTER</kbd>, or <kbd>OPTION (⌥)</kbd> + <kbd>CLICK</kbd> the item, or use <kbd>OPTION (⌥)</kbd> + `n` shortcut.
5. To choose the history item and paste without formatting, press <kbd>OPTION (⌥)</kbd> + <kbd>SHIFT (⇧)</kbd> + <kbd>ENTER</kbd>, or <kbd>OPTION (⌥)</kbd> + <kbd>SHIFT (⇧)</kbd> + <kbd>CLICK</kbd> the item, or use <kbd>OPTION (⌥)</kbd> + <kbd>SHIFT (⇧)</kbd> + `n` shortcut.
6. To delete the history item, press <kbd>OPTION (⌥)</kbd> + <kbd>DELETE (⌫)</kbd>.
7. To see the full text of the history item, wait a couple of seconds for tooltip.
8. To pin the history item so that it remains on top of the list, press <kbd>OPTION (⌥)</kbd> + <kbd>P</kbd>. The item will be moved to the top with a random but permanent keyboard shortcut. To unpin it, press <kbd>OPTION (⌥)</kbd> + <kbd>P</kbd> again.
9. To clear all unpinned items, select _Clear_ in the footer, or press <kbd>OPTION (⌥)</kbd> + <kbd>COMMAND (⌘)</kbd> + <kbd>DELETE (⌫)</kbd>. To clear all items including pinned, select _Clear_ with <kbd>OPTION (⌥)</kbd> pressed, or press <kbd>SHIFT (⇧)</kbd> + <kbd>OPTION (⌥)</kbd> + <kbd>COMMAND (⌘)</kbd> + <kbd>DELETE (⌫)</kbd>.
10. To save a clipboard item as a command, right-click it and choose **Save as Command**.
11. To disable MaccyPlus and ignore new copies, click on the menu icon with <kbd>OPTION (⌥)</kbd> pressed.
12. To ignore only the next copy, click on the menu icon with <kbd>OPTION (⌥)</kbd> + <kbd>SHIFT (⇧)</kbd> pressed.
13. To customize the behavior, check "Preferences..." window, or press <kbd>COMMAND (⌘)</kbd> + <kbd>,</kbd>.

### Commands

1. Switch to Commands mode using the segmented picker (clock/terminal icons) or <kbd>CONTROL (⌃)</kbd> + <kbd>TAB</kbd>.
2. Click **Add Command** in the footer to create a new command.
3. Give it a title, body (with optional smart variables), and pick a folder.
4. Click a command to expand variables and auto-paste.
5. Commands with `%INPUT:label%` variables show an in-place form before pasting.
6. Commands persist until you delete them — they survive app restarts.
7. Organize commands into folders using the sidebar.

## Advanced

### Ignore Copied Items

You can tell MaccyPlus to ignore all copied items:

```sh
defaults write org.p0deje.Maccy ignoreEvents true # default is false
```

This is useful if you have some workflow for copying sensitive data. You can set `ignoreEvents` to true, copy the data and set `ignoreEvents` back to false.

You can also click the menu icon with <kbd>OPTION (⌥)</kbd> pressed. To ignore only the next copy, click with <kbd>OPTION (⌥)</kbd> + <kbd>SHIFT (⇧)</kbd> pressed.

### Ignore Custom Copy Types

By default MaccyPlus will ignore certain copy types that are considered to be confidential
or temporary. The default list always includes the following types:

* `org.nspasteboard.TransientType`
* `org.nspasteboard.ConcealedType`
* `org.nspasteboard.AutoGeneratedType`

Also, default configuration includes the following types but they can be removed
or overwritten:

* `com.agilebits.onepassword`
* `com.typeit4me.clipping`
* `de.petermaurer.TransientPasteboardType`
* `Pasteboard generator type`
* `net.antelle.keeweb`

You can add additional custom types using settings.
To find what custom types are used by an application, you can use
free application [Pasteboard-Viewer](https://github.com/sindresorhus/Pasteboard-Viewer).
Simply download the application, open it, copy something from the application you
want to ignore and look for any custom types in the left sidebar. [Here is an example
of using this approach to ignore Adobe InDesign](https://github.com/p0deje/Maccy/issues/125).

### Speed up Clipboard Check Interval

By default, MaccyPlus checks clipboard every 500 ms, which should be enough for most users. If you want
to speed it up, you can change it with `defaults`:

```sh
defaults write org.p0deje.Maccy clipboardCheckInterval 0.1 # 100 ms
```

## FAQ

### Why doesn't it paste when I select an item in history?

1. Make sure you have "Paste automatically" enabled in Preferences.
2. Make sure "MaccyPlus" is added to System Settings -> Privacy & Security -> Accessibility.

### When assigning a hotkey to open MaccyPlus, it says that this hotkey is already used in some system setting.

1. Open System settings -> Keyboard -> Keyboard Shortcuts.
2. Find where that hotkey is used. For example, "Convert text to simplified Chinese" is under Services -> Text.
3. Disable that hotkey or remove assigned combination.
4. Restart MaccyPlus.
5. Assign hotkey in MaccyPlus settings.

### How to restore hidden footer?

1. Open MaccyPlus window.
2. Press <kbd>COMMAND (⌘)</kbd> + <kbd>,</kbd> to open preferences.
3. Enable footer in Appearance section.

If for some reason it doesn't work, run the following command in Terminal.app:

```sh
defaults write org.p0deje.Maccy showFooter 1
```

### How to ignore copies from [Universal Clipboard](https://support.apple.com/en-us/102430)?

1. Open Preferences -> Ignore -> Pasteboard Types.
2. Add `com.apple.is-remote-clipboard`.

### My keyboard shortcut stopped working in password fields. How do I fix this?

If your shortcut produces a character (like `Option+C` -> "c"), macOS security may block it in password fields. Use [Karabiner-Elements](https://karabiner-elements.pqrs.org/) to remap your shortcut to a different combination like `Cmd+Shift+C`. [See detailed solution](docs/keyboard-shortcut-password-fields.md).

## Translations

MaccyPlus inherits translations from Maccy and supports 30+ languages. The original translations are hosted in [Weblate](https://hosted.weblate.org/engage/maccy/).

## License

[MIT](./LICENSE)
