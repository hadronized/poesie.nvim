# Poesie, the declarative configuration layer for Neovim

**Poesie** is a configuration layer built on top of [Neovim] made to be _declarative_. Declarative configuration can be
pictured as a tree of (possibly nested) key-value pairs.

<!-- vim-markdown-toc GFM -->

* [Features](#features)
* [Install procedure](#install-procedure)
  * [With packer](#with-packer)
  * [Bootstrapping](#bootstrapping)
* [User guide](#user-guide)
  * [Neovim layer](#neovim-layer)
  * [LSP layer](#lsp-layer)
    * [`"diagnostics"`](#diagnostics)
  * [Treesitter layer](#treesitter-layer)
  * [Plugin layer](#plugin-layer)
  * [Keybindings layer](#keybindings-layer)
* [Why this approach vs. scripting](#why-this-approach-vs-scripting)

<!-- vim-markdown-toc -->

## Features

- Set Vim / Neovim declaratively.
- Set LSP features declaratively.
- Set Treesitter features declaratively.
- Extend your editor by adding plugins and configuring them declaratively. **Poesie** will expose the configuration
  scoped by plugin. If a plugin doesn’t support the configuration interface, some local overrides might be implemented
  in **poesie** to still be able to configure those plugins in a declarative way.

## Install procedure

Installing **poesie** is a bit specific as it requires _bootstrapping_. This will largely depend on the packager you
use. Once **poesie** is installed, you can drop your packager configuration and use the plugin layer of poesie, as it
will automatically handle that for you.

If at some point you want to manually install poesie without having to alter your configuration, you can also bootstrap
it by using `git`.

### With packer

```lua
use {
  'phaazon/poesie.nvim',
  as = 'poesie',
}
```

### Bootstrapping

```sh
git clone --recurse-submodules https://github.com/phaazon/poesie.nvim <path to the plugin directory>
```

## User guide

**Poesie** is organized into different _layers_. You can enable each layer by creating and filling the file associated
with the corresponding layer:

| Layer                 | Associated file                          | Notes                                 |
| -----                 | ---------------                          | -----                                 |
| **Neovim layer**      | `$XDG_CONFIG_HOME/nvim/nvim.json`        | Configure Neovim options.             |
| **LSP layer**         | `$XDG_CONFIG_HOME/nvim/lsp.json`         | Configure Neovim’s native LSP.        |
| **Treesitter layer**  | `$XDG_CONFIG_HOME/nvim/treesitter.json`  | Configure Neovim’s native Treesitter. |
| **Plugin layer**      | `$XDG_CONFIG_HOME/nvim/plugins.json`     | Declare and configure plugins.        |
| **Keybindings layer** | `$XDG_CONFIG_HOME/nvim/keybindings.json` | Global keybindings.                   |

If a file is present, its corresponding layer is assumed active and its configuration will be loaded.

### Neovim layer

The Neovim layer is a 2-level configuration object used to configure Vim / Neovim options. Those objects directly map to
the `lua-vim-options` (`:h lua-vim-options`) configuration objects. For instance, switching the `showmode` off option
is done with `vim.o.showmode = false;` in Lua, and is done this way with the Neovim layer:

```json
{
  "o": {
    "showmode": false
  }
}
```

### LSP layer

The LSP layer allows to configure the internal Lua LSP implementation. It is a rich configuration object that provides
some candies if you have the right plugins installed. It is mean of several main top-objects:

```json
{
  "diagnostics": …,
  "capabilities": …,
  "symbol-kind-labels": …,
  "keybindings": …,
  "servers": …
}
```

#### `"diagnostics"`

| Key                               | Type      | Default value | Note                                          |
| ---                               | ----      | ------------- | ----                                          |
| `"diagnostics.underline"`         | `boolean` | `true`        | Should diagnostics use underline.             |
| `"diagnostics.virtual_text"`      | `boolean` | `true`        | Should diagnostics be using virtual text.     |
| `"diagnostics.signs"`             | `boolean` | `true`        | Should diagnostics be using signs.            |
| `"diagnostics.update_in_insert"`  | `boolean` | `false`       | Should diagnostics be updated in insert mode. |
| `"diagnostics.severity_sort"`     | `boolean` | `false`       | Should diagnostics be sorted by severity.     |

### Treesitter layer

### Plugin layer

### Keybindings layer

## Why this approach vs. scripting

The typical way to configure an editor like Vim or Neovim is via _scripting_: you get access to a VimL / Lua API, and
you use it to configure the editor. The problem with that approach is that _scripting ≠ configuring_: using a
programming language to configure your software yields more problems than it solves and having more power doesn’t always
mean having an easier and better life. Scripting languages will offer people the power to use conditional, loops,
imports, object-oriented programming and other paradigms that have nothing to do with configuration. If those concepts
exist, you can be sure that someone will use them, abuse them and/or misuse them. Reading the configuration of a
software that is full of loops, conditionals and imports doesn’t help making the end-users live any easier.

On the other side, this plugin allows users to configure Neovim in a declarative language devoid of control flow,
without conditional, loops, etc. It provides users with _real_ configuration files, and not source code / scripting
files. Plugin authors can support the declarative layer directly in their plugins so that they automatically benefit
from the declarative interface of **poesie**.

[Neovim]: https://neovim.io
