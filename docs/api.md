---
title: API Documentation
---

<script setup>
import { data } from "./options.data.js";
import { RenderDocs } from "easy-nix-documentation";
</script>


## General

<RenderDocs :options="data" :exclude="[/^_module*/, /^systemd*/]" />

## Systemd Units


<RenderDocs :options="data" :include="[/^systemd*/]" headingLevel="h4" />
