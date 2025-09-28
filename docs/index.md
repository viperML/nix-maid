---
# https://vitepress.dev/reference/default-theme-home-page
layout: home

hero:
  name: "nix-maid"
  tagline: "simpler dotfile management"
  # text: My great project tagline
  actions:
    - theme: brand
      text: Installation
      link: /installation
    - theme: alt
      text: API Documentation
      link: /api
    - theme: alt
      text: GitHub
      link: https://github.com/viperML/nix-maid

features:
  - title: "🪶 Lightweight"
    details: The nix-maid core is as lean as possible, pushing the execution to other tools.
  - title: "🌐 Portable"
    details: Both standalone and as a NixOS module are methods of installation.
  - title: "🚫 No Legacy"
    details: New ergonomic API's will make you feel at home.
  - title: "⚡ Fast"
    details: Activation is done as concurrently as possible thanks to systemd.
---

<!--@include: ./readme.md-->

<style>
.VPContent.is-home {
  background: radial-gradient(circle at 90% 50%, #ccccccff 30%, var(--vp-c-bg) 40%);
  min-height: 100vh;
}
.dark .VPContent.is-home {
  background: radial-gradient(circle at 90% 50%, #232a3a 30%, var(--vp-c-bg) 40%);
}

.VPHide {
  display: none;
}
</style>
