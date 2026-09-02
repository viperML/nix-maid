// @ts-check
"use strict";

import { dirname, normalize } from 'node:path'
import { fileURLToPath } from 'node:url'
import { loadOptions } from "easy-nix-documentation/loader"

export default {
    async load() {
        const __dirname = dirname(fileURLToPath(import.meta.url));
        return await loadOptions(`-f ${__dirname}/../test/simple.nix config.build.optionsDoc.optionsJSON`, {
            mapDeclarations: declaration => {
                const root = normalize(`${__dirname}/..`);
                const relDecl = declaration.replace(root, "");
                return `<a href="https://codeberg.org/viperML/nix-maid/src/branch/master${relDecl}">&lt;nix-maid${relDecl}&gt;</a>`;
            },
        })
    }
}
