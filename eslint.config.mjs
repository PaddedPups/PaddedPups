import globals from "globals";
import eslint from "@eslint/js";
import stylistic from "@stylistic/eslint-plugin-js";

export default [
  eslint.configs.recommended,
  {
    files: ["**/*.js"],
    languageOptions: {
      ecmaVersion: "latest",
      globals: {
        ...globals.browser,
        $: false,
        Danbooru: false,
      },
    },
    plugins: {
      "@stylistic/js": stylistic,
    },
    rules: {
      "no-unused-vars": "off",

      // https://eslint.style/packages/js
      /*
      "array-bracket-newline": "warn",
      "array-bracket-spacing": "off",
      "array-element-newline": ["warn", "consistent"],
      "arrow-parens": "off",
      "arrow-spacing": "warn",
      "block-spacing": "warn",
      "brace-style": "warn",
      "comma-dangle": ["warn", "always-multiline"],
      "comma-spacing": "warn",
      "comma-style": "warn",
      "computed-property-spacing": "warn",
      "dot-location": ["warn", "property"],
      "eol-last": "warn",
      "function-call-argument-newline": ["warn", "consistent"],
      "func-call-spacing": "warn",  // function-call-spacing does not work ???
      "implicit-arrow-linebreak": "warn",
      "indent": ["warn", 2],
      "key-spacing": ["warn", { "align": "value" }], // Might get annoying
      "keyword-spacing": "warn",
      "line-comment-position": "off",
      "linebreak-style": "error",
      "lines-around-comment": "off",
      "lines-between-class-members": "warn",
      "max-len": "warn", // Might get annoying, see https://eslint.style/rules/js/max-len
      "max-statements-per-line": "warn",
      "multiline-comment-style": "off",
      "multiline-ternary": ["warn", "always-multiline"],
      "new-parens": "warn",
      "newline-per-chained-call": "off",
      "no-confusing-arrow": "warn",
      "no-extra-parens": "warn",
      "no-extra-semi": "warn",
      "no-floating-decimal": "warn",
      "no-mixed-operators": "error",
      "no-mixed-spaces-and-tabs": "error",
      "no-multi-spaces": ["warn", { ignoreEOLComments: false }],
      "no-multiple-empty-lines": "warn",
      "no-tabs": "warn",
      "no-trailing-spaces": "warn",
      "no-whitespace-before-property": "warn",
      "nonblock-statement-body-position": "off",
      "object-curly-newline": ["warn", { "consistent": true }],
      "one-var-declaration-per-line": "off",
      "operator-linebreak": ["warn", "before"],
      "padded-blocks": "off",
      "padding-line-between-statements": "off",
      "quote-props": ["warn", "consistent"],
      "quotes": "warn",
      "rest-spread-spacing": "warn",
      "semi": "warn",
      "semi-spacing": "warn",
      "semi-style": "warn",
      "space-before-blocks": "warn",
      "space-before-function-paren": "warn", // good idea?
      "space-in-parens": "warn",
      "space-infix-ops": "warn",
      "space-unary-ops": "warn",
      "spaced-comment": "warn",
      "switch-colon-spacing": "warn",
      "template-curly-spacing": "warn",
      "template-tag-spacing": "warn",
      */
    },
  },
]
