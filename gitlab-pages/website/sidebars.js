/**
 * Creating a sidebar enables you to:
 - create an ordered group of docs
 - render a sidebar for each doc of that group
 - provide next/previous navigation

 The sidebars can be generated from the filesystem, or explicitly defined here.

 Create as many sidebars as you want.
 */

// @ts-check

/** @type {import('@docusaurus/plugin-content-docs').SidebarsConfig} */
const sidebars = {
  "docs": {
    "Getting started": [
      "tutorials/getting-started/getting-started",
      "intro/installation"
    ],
    "Learn": [
      {
      "type": "link",
      "label": "Learn with Academy",
      "href": "https://academy.ligolang.org/",
      },
      {
        "type": "link",
        "label": "Learn with Marigold",
        "href": "https://www.marigold.dev/learn",
      },
    ],
    "Basics": [
      "language-basics/types",
      "language-basics/composite-types",
      "language-basics/type-annotations",
      "language-basics/functions",
      "language-basics/boolean-if-else",
      "language-basics/constants-and-variables",
      "language-basics/maps-records",
      "language-basics/sets-lists-tuples",
      /* TODO: + mutation */
      "language-basics/exceptions",
      "language-basics/math-numbers-tez",
      "language-basics/loops",
      "language-basics/unit-option-pattern-matching",
      "language-basics/tezos-specific"
    ],
    "Writing a Contract": [
      "intro/introduction",
      {
        "type": "category",
        "label": "First contract",
        "items": [
          "tutorials/taco-shop/tezos-taco-shop-smart-contract",
          "tutorials/taco-shop/tezos-taco-shop-payout"
        ],
      },
      "advanced/entrypoints-contracts",
      "contract/views",
      "contract/events",
      "tutorials/start-a-project-from-a-template",
    ],
    "Testing and Debugging": [
      "advanced/testing",
      "advanced/mutation-testing",
      "advanced/michelson_testing",
      //TODO: write doc "testing/debugging"
    ],
    "Combining Code": [
      "language-basics/modules",
      "advanced/global-constants",
      "advanced/package-management"
    ],
    "Advanced Topics": [
      "advanced/polymorphism",
      "advanced/inline",
      "tutorials/inter-contract-calls/inter-contract-calls",
      "tutorials/optimisation/optimisation",
      "tutorials/security/security",
      //TODO: write doc "advanced/best-practices",
      "advanced/timestamps-addresses",
      "advanced/include",
      "advanced/first-contract",
      "advanced/michelson-and-ligo",
      "advanced/interop",
      "advanced/embedded-michelson"
    ],
    "Misc": [
      "intro/editor-support",
      "api/cli-commands",
      "api/cheat-sheet",
      "contributors/origin",
      "contributors/philosophy",
      "contributors/getting-started",
      "contributors/documentation-and-releases",
      "contributors/big-picture/overview",
      "contributors/big-picture/front-end",
      "contributors/big-picture/middle-end",
      "contributors/big-picture/back-end",
      "contributors/big-picture/vendors",
      "contributors/road-map/short-term",
      "contributors/road-map/long-term",
      "tutorials/registry/what-is-the-registry",
      "tutorials/registry/how-to-make-an-audit",
      "tutorials/tz-vs-eth/tz-vs-eth",
    ],
  },
  "API": {
    "CLI": [
       {
        "type": "doc",
        "id": "manpages/ligo"
      },
      {
        "type": "category",
        "label": "ligo compile",
        "items": [
          "manpages/compile constant",
          "manpages/compile contract",
          "manpages/compile expression",
          "manpages/compile parameter",
          "manpages/compile storage"
        ]
      },
      {
        "type": "category",
        "label": "ligo run",
        "items": [
          "manpages/run dry-run",
          "manpages/run evaluate-call",
          "manpages/run evaluate-expr",
          "manpages/run interpret",
          "manpages/run test",
          "manpages/run test-expr"
        ]
      },
      {
        "type": "category",
        "label": "ligo print",
        "items": [
          "manpages/print ast-aggregated",
          "manpages/print ast-core",
          "manpages/print ast-typed",
          "manpages/print ast-expanded",
          "manpages/print ast-unified",
          "manpages/print cst",
          "manpages/print dependency-graph",
          "manpages/print mini-c",
          "manpages/print preprocessed",
          "manpages/print pretty"
        ]
      },
      {
        "type": "category",
        "label": "ligo transpile",
        "items": [
          "manpages/transpile contract",
          "manpages/transpile-with-ast contract",
          "manpages/transpile-with-ast expression"
        ]
      },
      {
        "type": "category",
        "label": "ligo info",
        "items": [
          "manpages/info get-scope",
          "manpages/info list-declarations",
          "manpages/info measure-contract"
        ]
      },
      {
        "type": "category",
        "label": "ligo analytics",
        "items": [
          "manpages/analytics accept",
          "manpages/analytics deny"
        ]
      },
      {
        "type": "category",
        "label": "ligo init",
        "items": [
          "manpages/init contract",
          "manpages/init library"
        ]
      },
      {
        "type": "doc",
        "label": "ligo changelog",
        "id": "manpages/changelog"
      },
      {
        "type": "doc",
        "label": "ligo add-user",
        "id": "manpages/add-user"
      },
      {
        "type": "doc",
        "label": "ligo install",
        "id": "manpages/install"
      },
      {
        "type": "doc",
        "label": "ligo login",
        "id": "manpages/login"
      },
      {
        "type": "doc",
        "label": "ligo publish",
        "id": "manpages/publish"
      },
      {
        "type": "doc",
        "label": "ligo repl",
        "id": "manpages/repl"
      }
    ],
    "Language": [
      "reference/toplevel",
      "reference/big-map-reference",
      "reference/bitwise-reference",
      "reference/bytes-reference",
      "reference/crypto-reference",
      "reference/list-reference",
      "reference/map-reference",
      "reference/set-reference",
      "reference/string-reference",
      "reference/option-reference",
      "reference/current-reference",
      "reference/test",
      "reference/proxy-ticket-reference",
      "contract/tickets"
    ],
    "Changelog": [
      "intro/changelog",
      "protocol/hangzhou",
      "protocol/ithaca",
      "protocol/jakarta",
      "protocol/kathmandu",
      "protocol/lima",
      "protocol/mumbai",
      "protocol/nairobi"
    ],
  },
  "faq": {
    "FAQ": [
      "faq/intro",
      "faq/convert-address-to-contract",
      "faq/polymorphic-comparison",
      "faq/catch-error-view",
      "faq/cameligo-ocaml-syntax-diff",
      "faq/tezos-now-advance-time",
      "faq/transpile-pascaligo-to-jsligo"
    ]
  }
};

module.exports = sidebars;
