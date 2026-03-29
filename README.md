# Templates

My own templates with optional NixOS support, primarily only for myself and my friends

## Installation

### Nix

```nix
nix flake init -t github:acos/templates#category/name
```

### Other systems

*follows nix flake syntax*

```sh
bash <(curl -s https://raw.githubusercontent.com/acos-s/templates/refs/heads/main/get-template.sh) github:acos-s/templates#category/name
```
