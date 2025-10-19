// @ts-check
"use strict";

import { defineConfig } from "vitepress";

// https://vitepress.dev/reference/site-config
export default defineConfig({
  title: "nix-maid",
  description: "Systemd-native Home-Manager alternative",
  srcExclude: ["readme.md"],
  themeConfig: {
    // https://vitepress.dev/reference/default-theme-config
    nav: [
      // { text: 'Home', link: '/' },
      // { text: 'API', link: '/markdown-examples' }
    ],

    sidebar: [
      {
        // text: 'Examples',
        items: [
          // { text: "Overview", link: "/readme" },
          { text: "API Documentation", link: "/api" },
          { text: "Installation", link: "/installation" },
          { text: "Testing", link: "/test" },
          { text: "Cookbook", link: "/cookbook" },
          // { text: 'Runtime API Examples', link: '/api-examples' }
        ],
      },
    ],

    socialLinks: [
      { icon: "github", link: "https://github.com/viperML/nix-maid" },
    ],

    outline: {
      level: [1,3],
    },
  },
  vite: {
    ssr: {
      noExternal: "easy-nix-documentation",
    },
  },
});
