---
title: API Documentation
---

<script setup>
import { data } from "./options.data.js";
import { RenderDocs } from "easy-nix-documentation";
</script>

> [!WARNING]
> The API is not stable yet and might be subject to change.

## General

<RenderDocs :options="data" :exclude="[/^_module*/, /^systemd*/]" />

## Systemd Units


<RenderDocs :options="data" :include="[/^systemd*/]" headingLevel="h4" />
