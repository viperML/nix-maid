---
title: API Documentation
---

<script setup>
import { data } from "./options.data.js";
import { RenderDocs } from "easy-nix-documentation";
</script>

<RenderDocs :options="data" :exclude="[/^_module*/, /^systemd*/]" />

## Systemd


<RenderDocs :options="data" :include="[/^systemd*/]" />
