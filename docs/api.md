---
title: API Documentation
---

<script setup>
import { data } from "./options.data.js";
import { RenderDocs } from "easy-nix-documentation";
</script>

> [!WARNING]
> The API is not stable yet and might be subject to change.

<RenderDocs :options="data" :exclude="[/^_module*/, /^systemd*/]" />

## Systemd


<RenderDocs :options="data" :include="[/^systemd*/]" />
