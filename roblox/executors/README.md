# Roblox Script Template (WIP)

Multiplatform (including nixos) template for roblox executor projects

## Stack

- mise en place - cross-platform package binaries manager
- pesde - luau package manager
- rojo - studio sync & rbxl builds
- just - command manager
- lune - code testing
- darklua - code transforming before syncing to rojo
- luau-lsp - linting & pre-build validating

## Setup

### Nix (recommended)

```sh
nix develop -c $SHELL
```

### Other environments

install mise, then

```sh
mise install
```

```sh
# not sure about this command. read the docs
eval "$(mise activate bash)"
```

## Testing

```sh
just test <options>
```