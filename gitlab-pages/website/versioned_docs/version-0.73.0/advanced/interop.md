---
id: interop
title: Interop
---

import Syntax from '@theme/Syntax';

LIGO can work together with other smart contract languages on Tezos. However,
data structures might have different representations in Michelson and not
correctly match the standard LIGO types.

## Michelson types and annotations

Michelson types consist of `or`'s and `pair`'s, combined with field
annotations.  Field annotations add constraints on a Michelson type,
for example a pair of `(pair (int %foo) (string %bar))` will only work
with the exact equivalence or the same type without the field
annotations.

To clarify:

```michelson
(pair (int %foo) (string %bar))
````

works with

```michelson
(pair (int %foo) (string %bar))
```

works with

```michelson
(pair int string)
```

works not with

```michelson
(pair (int %bar) (string %foo))
```

works not with

```michelson
(pair (string %bar) (int %foo))
```

:::info
In the case of annotated entrypoints --- the annotated `or` tree
directly under `parameter` in a contract --- you should use
annotations, as otherwise it's unclear which entrypoint you are
referring to.
:::

## Default LIGO output

By default LIGO translates its datatypes into a alphabetically left
balanced tree. So, for example:

<Syntax syntax="pascaligo">

```pascaligo group=orig
type animal is Elephant | Dog | Cat
```

</Syntax>
<Syntax syntax="cameligo">

```cameligo group=orig
type animal = Elephant | Dog | Cat
```

</Syntax>

<Syntax syntax="jsligo">

```jsligo group=orig
type animal = | ["Elephant"] | ["Dog"] | ["Cat"];
```

</Syntax>

will translate to:

```michelson
(or
  (or
    (unit %cat)
    (unit %dog))
  (unit %elephant))
```

## Right-combed tree output

If you want to change the data representation in Michelson to a
location retaining right combed tree, like this:

```
  (or
    (unit %elephant)
    (or (unit %dog)
        (unit %cat)))
```

You can use the `@layout comb` (or `@layout:comb`) attribute:

<Syntax syntax="pascaligo">

```pascaligo
type animal is
[@layout comb]
| Elephant
| Dog
| Cat
```

> Note how a vertical bar has been inserted between the attribute and
> the first variant: otherwise, the attribute would apply to the first
> variant.

</Syntax>
<Syntax syntax="cameligo">

```cameligo
type animal =
[@layout comb]
| Elephant
| Dog
| Cat
```

</Syntax>

<Syntax syntax="jsligo">

```jsligo
type animal =
// @layout comb
| ["Elephant"]
| ["Dog"]
| ["Cat"];
```

</Syntax>

The `@layout comb` (or `@layout:comb`) attribute can also be used on
record types:

<Syntax syntax="pascaligo">

```pascaligo
type artist is
  [@layout comb]
  record [
    genre : string;
    since : timestamp;
    name  : string;
  ]
```

</Syntax>
<Syntax syntax="cameligo">

```cameligo
type artist =
  [@layout comb] {
  genre : string;
  since : timestamp;
  name  : string
}
```

</Syntax>

<Syntax syntax="jsligo">

```jsligo
type artist =
// @layout comb
{
  genre : string,
  since : timestamp,
  name  : string
};
```

</Syntax>


## Different Michelson annotations

If the Michelson annotation should be different from the LIGO
attribute, give it as an argument to the LIGO attribute. For
example:

<Syntax syntax="pascaligo">

```pascaligo group=annot
type animal is
| [@annot memory] Elephant
| [@annot face] Dog
| [@annot fish] Cat
```

</Syntax>
<Syntax syntax="cameligo">

```cameligo group=annot
type animal =
| [@annot memory] Elephant
| [@annot face] Dog
| [@annot fish] Cat
```

</Syntax>

<Syntax syntax="jsligo">

```jsligo group=annot
type animal =
| /* @annot memory */ ["Elephant"]
| /* @annot face */ ["Dog"]
| /* @annot fish */ ["Cat"]
```

</Syntax>

will result into:

```michelson
(or
  (or
    (unit %fish)
    (unit %face))
  (unit %memory))
```

The `@annot <name>` attribute can also be used on record field
annotations:

<Syntax syntax="pascaligo">

```pascaligo group=annot
type artist is record [
  [@annot style] genre: string;
  [@annot from] since: timestamp;
  [@annot performer] name: string;
]
```

</Syntax>
<Syntax syntax="cameligo">

```cameligo group=annot
type artist = {
  [@annot style] genre: string;
  [@annot from] since: timestamp;
  [@annot performer] name: string;
}
```

</Syntax>

<Syntax syntax="jsligo">

```jsligo group=annot
type artist = {
  /* @annot style */ genre: string,
  /* @annot from */ since: timestamp,
  /* @annot performer */ name: string
}
```

</Syntax>

If the `@layout comb` and `@annot <name>` attributes are not adequate
enough for your use-case, LIGO has more advanced advanced
interoperability features, which we will we discuss next.

## Advanced interoperability with Michelson

To interoperate with existing Michelson code or to be compatible with
certain development tooling, LIGO has two special interoperation
types: `michelson_or` and `michelson_pair`. These types give the
flexibility to model the exact Michelson output, including field
annotations.

Take for example the following Michelson type that we want to
interoperate with:

```michelson
(or
  (unit %z)
  (or %other
    (unit %y)
    (pair %other
      (string %x)
      (pair %other
        (int %w)
        (nat %v)))))
```

To reproduce this type we can use the following LIGO code:

<Syntax syntax="pascaligo">

```pascaligo
type w_and_v is michelson_pair (int, "w", nat, "v")
type x_and is michelson_pair (string, "x", w_and_v, "other")
type y_or is michelson_or (unit, "y", x_and, "other")
type z_or is michelson_or (unit, "z", y_or, "other")
```

</Syntax>
<Syntax syntax="cameligo">

```cameligo
type w_and_v = (int, "w", nat, "v") michelson_pair
type x_and = (string, "x", w_and_v, "other") michelson_pair
type y_or = (unit, "y", x_and, "other") michelson_or
type z_or = (unit, "z", y_or, "other") michelson_or
```

</Syntax>

<Syntax syntax="jsligo">

```jsligo
type w_and_v = michelson_pair<[int, "w", nat, "v"]>;
type x_and = michelson_pair<[string, "x", w_and_v, "other"]>;
type y_or = michelson_or<[unit, "y", x_and, "other"]>;
type z_or = michelson_or<[unit, "z", y_or, "other"]>;
```

</Syntax>

If you do not want to inject a Michelson annotation, the you simply
provide an empty string.

:::info
Alternatively, if annotations are not important you can also use plain tuples
for pair's instead. Plain tuples don't have any annotations.
:::

To use variables of type `michelson_or` you have to use `M_left` and
`M_right`.  `M_left` picks the left `or` case while `M_right` picks
the right `or` case.  For `michelson_pair` you need to use tuples.

<Syntax syntax="pascaligo">

```pascaligo
const z : z_or = (M_left (unit) : z_or);

const y_1 : y_or = (M_left (unit): y_or);
const y   : z_or = (M_right (y_1) : z_or);

const x_pair : x_and = ("foo", (2, 3n));
const x_1    : y_or  = (M_right (x_pair) : y_or);
const x      : z_or  = (M_right (y_1) : z_or);
```

</Syntax>
<Syntax syntax="cameligo">

```cameligo
let z : z_or = M_left unit

let y_1 : y_or = M_left unit
let y   : z_or = M_right y_1

let x_pair = "foo", (2, 3n)
let x_1 : y_or = M_right x_pair
let x : z_or = M_right y_1
```

</Syntax>

<Syntax syntax="jsligo">

```jsligo
let z : z_or = M_left(unit);

let y_1 : y_or = M_left(unit);
let y : z_or = M_right(y_1);

let x_pair = ["foo", [2, 3 as nat]];
let x_1 : y_or = M_right (x_pair);
let x : z_or = M_right (y_1);
```

</Syntax>

## Manual data structure conversion

If you want to get your hands dirty, it is also possible to do manual
data structure conversion. The following code can be used as
inspiration:

<Syntax syntax="pascaligo">

```pascaligo group=helper_functions
type z_to_v is
| Z
| Y
| X
| W
| V

type w_or_v is michelson_or (unit, "w", unit, "v")
type x_or is michelson_or (unit, "x", w_or_v, "other")
type y_or is michelson_or (unit, "y", x_or, "other")
type z_or is michelson_or (unit, "z", y_or, "other")

type test is record [
  z: string;
  y: int;
  x: string;
  w: bool;
  v: int;
]

function make_concrete_sum (const r: z_to_v) : z_or is {
  const z: z_or = (M_left (unit) : z_or);

  const y_1: y_or = (M_left (unit): y_or);
  const y: z_or = (M_right (y_1) : z_or);

  const x_2: x_or = (M_left (unit): x_or);
  const x_1: y_or = (M_right (x_2): y_or);
  const x: z_or = (M_right (x_1) : z_or);

  const w_3: w_or_v = (M_left (unit): w_or_v);
  const w_2: x_or = (M_right (w_3): x_or);
  const w_1: y_or = (M_right (w_2): y_or);
  const w: z_or = (M_right (w_1) : z_or);

  const v_3: w_or_v = (M_right (unit): w_or_v);
  const v_2: x_or = (M_right (v_3): x_or);
  const v_1: y_or = (M_right (v_2): y_or);
  const v: z_or = (M_right (v_1) : z_or);
}
 with case r of [
  | Z -> z
  | Y -> y
  | X -> x
  | W -> w
  | V -> v
  ]


function make_concrete_record (const r : test) : string * int * string * bool * int is
  (r.z, r.y, r.x, r.w, r.v)

function make_abstract_sum (const z_or: z_or) : z_to_v is
  case z_or of [
  | M_left (n) -> Z
  | M_right (y_or) ->
    case y_or of [
    | M_left (n) -> Y
    | M_right (x_or) ->
        case x_or of [
        | M_left (n) -> X
        | M_right (w_or) ->
            case (w_or) of [
            | M_left (n) -> W
            | M_right (n) -> V
            ]
        ]
    ]
  ]

function make_abstract_record
  (const z : string;
   const y : int;
   const x : string;
   const w : bool;
   const v : int) : test is
  record [z = z; y = y; x = x; w = w; v = v]

```

</Syntax>

<Syntax syntax="cameligo">

```cameligo group=helper_functions
type z_to_v =
  Z
| Y
| X
| W
| V

type w_or_v = (unit, "w", unit, "v") michelson_or
type x_or = (unit, "x", w_or_v, "other") michelson_or
type y_or = (unit, "y", x_or, "other") michelson_or
type z_or = (unit, "z", y_or, "other") michelson_or

type test = {
  z: string;
  y: int;
  x: string;
  w: bool;
  v: int
}

let make_concrete_sum (r: z_to_v) : z_or =
  match r with
    Z -> M_left (unit)
  | Y -> M_right (M_left (unit))
  | X -> M_right (M_right (M_left (unit)))
  | W -> M_right (M_right (M_right (M_left (unit))))
  | V -> M_right (M_right (M_right (M_right (unit))))

let make_concrete_record (r: test) =
  (r.z, r.y, r.x, r.w, r.v)

let make_abstract_sum (z_or: z_or) =
  match z_or with
  | M_left n -> Z
  | M_right y_or ->
    (match y_or with
    | M_left n -> Y
    | M_right x_or -> (
        match x_or with
        | M_left n -> X
        | M_right w_or -> (
            match w_or with
            | M_left n -> W
            | M_right n -> V)))

let make_abstract_record z y x w v =
  { z = z; y = y; x = x; w = w; v = v }

```

</Syntax>



<Syntax syntax="jsligo">

```jsligo group=helper_functions
type z_to_v =
  ["Z"]
| ["Y"]
| ["X"]
| ["W"]
| ["V"];

type w_or_v = michelson_or<[unit, "w", unit, "v"]>;
type x_or = michelson_or<[unit, "x", w_or_v, "other"]>;
type y_or = michelson_or<[unit, "y", x_or, "other"]>;
type z_or = michelson_or<[unit, "z", y_or, "other"]>;

type test = {
  z: string,
  y: int,
  x: string,
  w: bool,
  v: int
};

let make_concrete_sum = (r: z_to_v): z_or =>
  match(r, {
    Z: () => M_left(unit),
    Y: () => M_right(M_left(unit)),
    X: () => M_right (M_right (M_left(unit))),
    W: () => M_right (M_right (M_right(M_left(unit)))),
    V: () => M_right (M_right (M_right(M_right(unit))))
  });


let make_concrete_record = (r: test) =>
  [r.z, r.y, r.x, r.w, r.v];

let make_abstract_sum = (z_or: z_or): z_to_v =>
  match(z_or, {
    M_left: (n: unit) => Z(),
    M_right: (y_or: y_or) => {
      return match(y_or, {
        M_left: (n: unit) => Y(),
        M_right: (x_or: x_or) => {
          return match(x_or, {
            M_left: (n: unit) => X(),
            M_right: (w_or: w_or_v) => {
              return match(w_or, {
                M_left: (n: unit) => W(),
                M_right: (n: unit) => V()
              })
            }
          })
        }
      })
    }
  });

let make_abstract_record = (z: string, y: int, x: string, w: bool, v: int) =>  ({z,y,x,w,v});
```

</Syntax>


## Entrypoints and annotations
It's possible for a contract to have multiple entrypoints, which translates in
LIGO to a `parameter` with a variant type as shown here:
<Syntax syntax="pascaligo">

```pascaligo
type storage is int

type parameter is
 | Left of int
 | Right of int

function main (const p: parameter; const x: storage): (list(operation) * storage) is
  (nil, case p of [
  | Left  (i) -> x - i
  | Right (i) -> x + i
  ])
```

</Syntax>
<Syntax syntax="cameligo">

```cameligo
type storage = int

type parameter =
 | Left of int
 | Right of int

let main ((p, x): (parameter * storage)): (operation list * storage) =
  [],
  (match p with
  | Left i -> x - i
  | Right i -> x + i
  )

```

</Syntax>

<Syntax syntax="jsligo">

```jsligo
type storage = int;

type parameter =
   ["Left", int]
 | ["Right", int];

let main = (p: parameter, x: storage): [list<operation>, storage] =>
  [list ([]), match(p, {
    Left: (i: int) => x - i,
    Right: (i: int) => x + i
  })];

```

</Syntax>

This contract can be called by another contract, like this one:

<Syntax syntax="pascaligo">

```pascaligo group=get_entrypoint_opt
type storage is int

type parameter is int

type x is Left of int

function main (const p: parameter; const s: storage): (list(operation) * storage) is {
  const contract =
    case Tezos.get_entrypoint_opt("%left", ("tz1KqTpEZ7Yob7QbPE4Hy4Wo8fHG8LhKxZSx":address)) of [
    | Some (c) -> c
    | None -> failwith("not a correct contract")
    ];
} with (list [Tezos.transaction(Left(2), 2mutez, contract)], s)
```

</Syntax>


<Syntax syntax="cameligo">

```cameligo group=get_entrypoint_opt
type storage = int

type parameter = int

type x = Left of int

let main (p, s: parameter * storage): operation list * storage =
  let contract =
    match Tezos.get_entrypoint_opt "%left" ("tz1KqTpEZ7Yob7QbPE4Hy4Wo8fHG8LhKxZSx": address) with
    | Some c -> c
    | None -> failwith "contract does not match"
  in
  [Tezos.transaction (Left 2) 2mutez contract], s
```

</Syntax>



<Syntax syntax="jsligo">

```jsligo group=get_entrypoint_opt
type storage = int;

type parameter = int;

type x = | ["Left", int];

let main = (p: parameter, s: storage): [list<operation>, storage] => {
  let contract =
    match (Tezos.get_entrypoint_opt("%left", "tz1KqTpEZ7Yob7QbPE4Hy4Wo8fHG8LhKxZSx" as address), {
      Some: c => c,
      None: () => failwith ("contract does not match")
    });
  return [
    list([Tezos.transaction(Left(2), 2 as mutez, contract)]),
    s];
};
```

</Syntax>


Notice how we directly use the `%left` entrypoint without mentioning the
`%right` entrypoint. This is done with the help of annotations. Without
annotations it wouldn't be clear what our `int` would be referring to.

This currently only works for `or`'s or variant types in LIGO.

## Amendment
With the upcoming 007 amendment to Tezos this will change though, and also
`pair`'s can be ordered differently.
