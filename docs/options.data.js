// @ts-check
"use strict";

import { dirname } from 'node:path'
import { fileURLToPath } from 'node:url'
import { loadOptions, stripNixStore } from "easy-nix-documentation/loader"

export default {
    async load() {
        const __dirname = dirname(fileURLToPath(import.meta.url));
        return await loadOptions(`-f ${__dirname}/../test config.build.optionsDoc.optionsJSON`, {
            mapDeclarations: declaration => {
                const relDecl = stripNixStore(declaration);
                return `<a href="http://github.com/viperML/nix-maid/tree/master/${relDecl}">&lt;${relDecl}&gt;</a>`
            },
        })
    }
}
