---
# https://vitepress.dev/reference/default-theme-home-page
layout: home

hero:
  name: "nix-maid"
  tagline: "Systemd-native dotfile management"
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
    details: Pushing the execution to other tools, making the project almost a pure-nix library.
  - title: "🌐 Portable"
    details: Defers the value of your home directory, meaning the same configuration can be used with different users.
  - title: "🚫 No Legacy"
    details: API redesigned from scratch, freeing us from past mistakes like `mkOutOfStoreSymlink`
  - title: "⚡ Fast"
    details: Utilizes a static directory, enabling rollbacks without traversing your entire home or diffing profiles.
---

<!--@include: ./readme.md-->

<style>
.VPContent.is-home {
  background: radial-gradient(circle at 90% 110%, #232a3a 30%, var(--vp-c-bg) 40%);
  min-height: 100vh;
}

.VPHide {
  display: none;
}
</style>
