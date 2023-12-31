---
id: strings-bytes
title: Strings & Bytes
---

import Syntax from '@theme/Syntax';

## Strings

Strings are defined using the built-in `string` type like this:

<Syntax syntax="pascaligo">

```
const a : string = "Hello Alice"
```

</Syntax>
<Syntax syntax="cameligo">

```
let a : string = "Hello Alice"
```

</Syntax>

<Syntax syntax="jsligo">

```jsligo
let a = "Hello Alice";
```

</Syntax>

### Concatenating Strings

<Syntax syntax="pascaligo">

Strings can be concatenated using the `^` operator.

```pascaligo group=a
const name : string = "Alice"
const greeting : string = "Hello"
const full_greeting : string = greeting ^ " " ^ name
```

</Syntax>
<Syntax syntax="cameligo">

Strings can be concatenated using the `^` operator.

```cameligo group=a
let name : string = "Alice"
let greeting : string = "Hello"
let full_greeting : string = greeting ^ " " ^ name
```

</Syntax>

<Syntax syntax="jsligo">

Strings can be concatenated using the `+` operator.

```jsligo group=a
let name = "Alice";
let greeting = "Hello";
let full_greeting = greeting + " " + name;
```

</Syntax>



### Extracting Substrings

Substrings can be extracted using the predefined function
`String.sub`. The first character has index 0 and the interval of
indices for the substring has inclusive bounds.

<Syntax syntax="pascaligo">

```pascaligo group=b
const name  : string = "Alice"
const slice : string = String.sub (0n, 1n, name)
```

</Syntax>
<Syntax syntax="cameligo">

```cameligo group=b
let name  : string = "Alice"
let slice : string = String.sub 0n 1n name
```

</Syntax>

<Syntax syntax="jsligo">

```jsligo group=b
let name = "Alice";
let slice = String.sub (0 as nat, 1 as nat, name);
```

</Syntax>

> ⚠️ Notice that the offset and length of the slice are natural
> numbers.

### Length of Strings

The length of a string can be found using a built-in function:

<Syntax syntax="pascaligo">

```pascaligo group=c
const name : string = "Alice"
const length : nat = String.length (name) // length = 5
```

> Note that `size` is *deprecated*. 

</Syntax>
<Syntax syntax="cameligo">

```cameligo group=c
let name : string = "Alice"
let length : nat = String.length name  // length = 5
```

> Note that `String.size` is *deprecated*.

</Syntax>

<Syntax syntax="jsligo">

```jsligo group=c
let name = "Alice";
let length = String.length(name);  // length == 5
```

</Syntax>

## Bytes

Byte literals are defined using the prefix `0x` followed by hexadecimal digits like this:

<Syntax syntax="pascaligo">

```pascaligo
const b : bytes = 0x7070
```

</Syntax>
<Syntax syntax="cameligo">

```cameligo
let b : bytes = 0x7070
```

</Syntax>

<Syntax syntax="jsligo">

```jsligo
let b = 0x7070;
```

</Syntax>

Moreover, a string literal can be converted to its bytes representation:

<Syntax syntax="pascaligo">

```pascaligo
const bs : bytes = [%bytes "foo"]
```

</Syntax>
<Syntax syntax="cameligo">

```cameligo
let bs : bytes = [%bytes "foo"]
```

</Syntax>

<Syntax syntax="jsligo">

```jsligo
let bs = (bytes `foo`);
```

</Syntax>


### Concatenating Bytes

Bytes can be concatenated using the `Bytes.concat` function.

<Syntax syntax="pascaligo">

```pascaligo group=d
const white : bytes = 0xffff
const black : bytes = 0x0000
const mixed : bytes = Bytes.concat (white, black) // 0xffff0000
```

</Syntax>
<Syntax syntax="cameligo">

```cameligo group=d
let white : bytes = 0xffff
let black : bytes = 0x0000
let mixed : bytes = Bytes.concat white black (* 0xffff0000 *)
```

</Syntax>

<Syntax syntax="jsligo">

```jsligo group=d
let white = 0xffff;
let black = 0x0000;
let mixed = Bytes.concat(white, black); // 0xffff0000
```

</Syntax>

### Extracting Bytes

Bytes can be extracted using the predefined function `Bytes.sub`.  The
first parameter takes the start index and the second parameter takes
the number of bytes. Pay special attention to how `bytes` are
indexed.

<Syntax syntax="pascaligo">

```pascaligo group=e
const b     : bytes = 0x12345678
const slice : bytes = Bytes.sub (1n, 2n, b) // 0x3456
```

</Syntax>
<Syntax syntax="cameligo">

```cameligo group=e
let b     : bytes = 0x12345678
let slice : bytes = Bytes.sub 1n 2n b (* 0x3456 *)
```

</Syntax>

<Syntax syntax="jsligo">

```jsligo group=e
let b     = 0x12345678;
let slice = Bytes.sub (1 as nat, 2 as nat, b); // 0x3456
```

</Syntax>

### Length of Bytes

The length of `bytes` can be found using a built-in function `Bytes.length`:

<Syntax syntax="pascaligo">

```pascaligo group=f
const b      : bytes = 0x123456
const length : nat   = Bytes.length (b) // length = 3
```

</Syntax>
<Syntax syntax="cameligo">

```cameligo group=f
let b      : bytes = 0x123456
let length : nat   = Bytes.length b  (* length = 3 *)
```

</Syntax>

<Syntax syntax="jsligo">

```jsligo group=f
let b      = 0x123456;
let length = Bytes.length(b);  // length = 3
```

</Syntax>

### Bitwise operators

You can perform bitwise operation on `bytes` as follows:

<Syntax syntax="pascaligo">

```pascaligo group=g
(* Bitwise and *)
const b_and           = Bitwise.and         (0x0005, 0x0106); // 0x0004

(* Bitwise or *)
const b_or            = Bitwise.or          (0x0005, 0x0106); // 0x0107

(* Bitwise xor *)
const b_xor           = Bitwise.xor         (0x0005, 0x0106); // 0x0103

(* Bitwise shift left *)
const b_shift_left    = Bitwise.shift_left  (0x06  , 8n    ); // 0x0600

(* Bitwise shift right *)
const b_shift_right   = Bitwise.shift_right (0x0006, 1n    ); // 0x0003
```

</Syntax>
<Syntax syntax="cameligo">

```cameligo group=g
(* Bitwise and *)
let b_and         = 0x0005 land 0x0106 (* 0x0004 *)

(* Bitwise or *)
let b_or          = 0x0005 lor  0x0106 (* 0x0107 *)

(* Bitwise xor *)
let b_xor         = 0x0005 lxor 0x0106 (* 0x0103 *)

(* Bitwise shift left *)
let b_shift_left  = 0x06   lsl  8n     (* 0x0600 *)

(* Bitwise shift right *)
let b_shift_right = 0x0006 lsr  1n     (* 0x0003 *)
```

</Syntax>

<Syntax syntax="jsligo">

```jsligo group=g
/* Bitwise and */
const b_and           = Bitwise.and         (0x0005, 0x0106  ); // 0x0004

/* Bitwise or */
const b_or            = Bitwise.or          (0x0005, 0x0106  ); // 0x0107

/* Bitwise xor */
const b_xor           = Bitwise.xor         (0x0005, 0x0106  ); // 0x0103

/* Bitwise shift left */
const b_shift_left    = Bitwise.shift_left  (0x06  , 8 as nat); // 0x0600

/* Bitwise shift right */
const b_shift_right   = Bitwise.shift_right (0x0006, 1 as nat); // 0x0003
```

</Syntax>


### From `bytes` to `nat` and back

You can case `bytes` to `nat` using the built-in `nat` function and vice-versa 
using using the `bytes` built-in function.

<Syntax syntax="pascaligo">

```pascaligo group=h
(* bytes -> nat *)
const test_bytes_nat = nat(0x1234) // 1234n

(* nat -> bytes *)
const test_nat_bytes = bytes(4660n) // 0x1234
```

</Syntax>
<Syntax syntax="cameligo">

```cameligo group=h
(* bytes -> nat *)
let test_bytes_nat = nat 0x1234 (* 1234n *)

(* nat -> bytes *)
let test_nat_bytes = bytes 4660n (* 0x1234 *)
```

</Syntax>

<Syntax syntax="jsligo">

```jsligo group=h
/* bytes -> nat */
const test_bytes_nat = nat(0x1234) // (1234 as nat)

/* nat -> bytes */
const test_nat_bytes = bytes(4660 as nat) // 0x1234
```

</Syntax>

### From `bytes` to `int` and back

You can cast `bytes` to `int` using the built-in `int` function and vice-versa 
using the `bytes` built-in function.

<Syntax syntax="pascaligo">

```pascaligo group=h
(* bytes -> int *)
const test_bytes_int = int(0x1234) // 4660

(* int -> bytes *)
const test_int_bytes = bytes(4660) // 0x1234
```

</Syntax>
<Syntax syntax="cameligo">

```cameligo group=h
(* bytes -> int *)
let test_bytes_int = int 0x1234 (* 4660 *)

(* int -> bytes *)
let test_int_bytes = bytes 4660 (* 0x1234 *)
```

</Syntax>

<Syntax syntax="jsligo">

```jsligo group=h
/* bytes -> int */
const test_bytes_int = int(0x1234) // 4660

/* int -> bytes */
const test_int_bytes = bytes(4660) // 0x1234
```

</Syntax>