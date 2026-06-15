# Obfuscation Patterns

Detailed patterns for detecting code obfuscation and deception in remote skills.

## MEDIUM — Encoded Payloads

Flag code that uses encoding to hide its intent:

- Base64 strings that decode to commands: `atob("...")`, `Buffer.from("...", "base64")`
- Hex-encoded strings: `\x63\x75\x72\x6c` (spells "curl")
- Unicode escape sequences forming commands: `\u0065\u0076\u0061\u006c` (spells "eval")
- ROT13 or Caesar cipher encoded strings
- URL-encoded payloads: `%65%76%61%6C` (spells "eval")
- Template literal obfuscation: `` `${'ev'}${'al'}` ``

Upgrade to **CRITICAL** if the decoded content matches patterns from other rule files (e.g., decoded Base64 is a curl command).

## MEDIUM — String Concatenation Evasion

Flag code that splits dangerous function/command names:

- `'ev' + 'al'` or `['ev','al'].join('')`
- `'child_' + 'process'`
- `'ex' + 'ec'`
- `String.fromCharCode(101, 118, 97, 108)` (spells "eval")
- Array-based reconstruction: `['c','u','r','l'].join('')`
- Variable reassignment chains: `const a = 'ev'; const b = 'al'; globalThis[a+b](...)`

## MEDIUM — Minified Code

Flag code that appears deliberately minified or compressed:

- Single-line JavaScript/TypeScript files over 500 characters
- No whitespace, no comments, single-character variable names
- Webpack/Rollup bundle output without source maps
- Intentionally unreadable formatting

Note: Minified code is not inherently malicious but prevents auditing. Flag as MEDIUM with recommendation to request readable source.

## MEDIUM — Unusual File Extensions

Flag files with misleading or double extensions:

- `.md.sh` — markdown that's actually a shell script
- `.txt.js` — text file that's actually JavaScript
- `.json.exe` — JSON that's actually an executable
- `.png.js` — image that's actually JavaScript
- Files with no extension that contain `#!/bin/` shebang
- `.md` files that contain `#!/bin/bash` or similar

## LOW — Steganographic Indicators

Flag unusual binary or large base64 content:

- Large binary blobs in markdown or text files
- Image files embedded as base64 in skill documentation (may contain hidden data)
- Unusually large files for their stated purpose

## False Positive Indicators

- Legitimate minified vendor libraries (jQuery, lodash) included as dependencies
- Base64-encoded images in documentation (data URIs for icons/logos)
- Hex color codes in CSS/style files
- Unicode in internationalization/localization files
- Build artifacts that are typically minified
