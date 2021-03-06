/**
 * Copyright: Copyright (c) 2016 Wojciech Szęszoł. All rights reserved.
 * Authors: Wojciech Szęszoł
 * Version: Initial created: Jun 26, 2016
 * License: $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost Software License 1.0)
 */
import std.stdio;
import Common;
import dstep.translator.Translator;


// Test a nested struct.
unittest
{
    assertTranslates(
q"C
struct A
{
    struct B
    {
        int x;
    } b;
};
C",
q"D
extern (C):

struct A
{
    struct B
    {
        int x;
    }

    B b;
}
D");
}

// Test translation and declaration of typedef and struct in one statement.
unittest
{
    assertTranslates(
q"C
typedef struct A B;

struct A { };
C",
q"D
extern (C):

alias B = A;

struct A
{
}
D");
}

// Test translation and definition of typedef and struct in one statement.
unittest
{
    assertTranslates(
q"C
typedef struct A { } B;

struct Q { };
C",
q"D
extern (C):

struct A
{
}

alias B = A;

struct Q
{
}
D");
}

// Test translation of a nested anonymous structures.
unittest
{
    assertTranslates(q"C
struct C
{
    union {
        int x;
        int y;
    };

    struct {
        int z;
        int w;

        union {
            int r, g, b;
        };
    };
};
C",
q"D
extern (C):

struct C
{
    union
    {
        int x;
        int y;
    }

    struct
    {
        int z;
        int w;

        union
        {
            int r;
            int g;
            int b;
        }
    }
}
D");

}

// Test packed structures.
unittest
{
    assertTranslates(
q"C

typedef struct __attribute__((__packed__)) { } name;

struct Foo
{
	char x;
	short y;
	int z;
} __attribute__((__packed__));

C",
q"D
extern (C):

struct name
{
    align (1):
}

struct Foo
{
    align (1):

    char x;
    short y;
    int z;
}
D");

}

// Translate immediately declared array variable in global scope.
unittest
{
    assertTranslates(
q"C

struct Bar {
const char *foo;
const char *oof;
} baz[64];

C",
q"D
extern (C):

struct Bar
{
    const(char)* foo;
    const(char)* oof;
}

extern __gshared Bar[64] baz;
D");

}

// Do not put an extra newline after array declaration.
unittest
{
    assertTranslates(q"C
struct Foo {
    int data[32];
    char len;
};
C",
q"D
extern (C):

struct Foo
{
    int[32] data;
    char len;
}
D");

}

// Translate nested structure with immediate array variable.
unittest
{
    assertTranslates(q"C
struct Foo {
  struct Bar {
    const char *qux0;
    const char *qux1;
  } baz[64];
};
C",
q"D
extern (C):

struct Foo
{
    struct Bar
    {
        const(char)* qux0;
        const(char)* qux1;
    }

    Bar[64] baz;
}
D");

    // Anonymous variant.
    assertTranslates(q"C
struct Foo {
  struct {
    const char *qux;
  } baz[64];
};
C",
q"D
extern (C):

struct Foo
{
    struct _Anonymous_0
    {
        const(char)* qux;
    }

    _Anonymous_0[64] baz;
}
D");

}

// Maintain ordering of record definitions in presence of forward declarations.
unittest
{
    assertTranslates(
q"C
struct A;

union B {
};

struct A {
    int foo;
};

union B;
C",
q"D
extern (C):

union B
{
}

struct A
{
    int foo;
}
D");
}

// Translate nested structure with immediate pointer variable.
unittest
{
     assertTranslates(q"C
struct Foo {
  struct Bar {
  } *baz;
};
C",
q"D
extern (C):

struct Foo
{
    struct Bar
    {
    }

    Bar* baz;
}
D");

    assertTranslates(q"C
struct Foo {
  struct {
  } *baz;
};
C",
q"D
extern (C):

struct Foo
{
    struct _Anonymous_0
    {
    }

    _Anonymous_0* baz;
}

D");

    // Multiple pointers.
    assertTranslates(q"C
struct Foo {
  struct {
  } **baz;
};
C",
q"D
extern (C):

struct Foo
{
    struct _Anonymous_0
    {
    }

    _Anonymous_0** baz;
}

D");

}

// Skip typedef of structure when the names of typedef and structure are the
// same and the structure has definition somewhere else.
unittest
{
    assertTranslates(q"C
typedef struct Foo Foo;
struct Foo;
struct Foo
{
    struct Bar
    {
        int x;
    } bar;
};

typedef union Baz Baz;

typedef struct Qux {
    int tmp;
} Qux;
C",
q"D
extern (C):

struct Foo
{
    struct Bar
    {
        int x;
    }

    Bar bar;
}

union Baz;

struct Qux
{
    int tmp;
}
D");
}

// Do not skip typedef of structure when the names of typedef and structure
// are the same and the structure has not definition.
unittest
{
    assertTranslates(q"C
typedef struct Foo Foo;
C",
q"D
extern (C):

struct Foo;
D");

    assertTranslates(q"C
typedef struct Foo Foo;

struct Bar;

struct Foo;
C",
q"D
extern (C):

struct Foo;

struct Bar;
D");
}

// Handle recursive types.
unittest
{
    assertTranslates(q"C
typedef struct Foo {
    struct Foo *next;
} Foo;

struct Bar {
    struct Bar* bar;
};

struct Baz;
typedef struct Baz Qux;

struct Baz {
    Qux* ptr;
};
C",
q"D
extern (C):

struct Foo
{
    Foo* next;
}

struct Bar
{
    Bar* bar;
}

alias Qux = Baz;

struct Baz
{
    Qux* ptr;
}
D");

// Don't generate nested declaration of the structure if its declared in global
// scope.
assertTranslates(q"C

// dummy comment #1
typedef struct {
    struct bar_s *vfs;
} foo_t;

typedef int baz_t;

// dummy comment #2
// dummy comment #3
// dummy comment #4
typedef struct bar_s {
    // dummy comment #5
    const char **(*fptr_0) (void);

    int (*is_sth) (void); // dummy comment #6

    // dummy comment #7
    void (*do_sth) (foo_t *foo);
} bar_t;
C",
q"D
extern (C):

// dummy comment #1
struct foo_t
{
    bar_s* vfs;
}

alias baz_t = int;

// dummy comment #2
// dummy comment #3
// dummy comment #4
struct bar_s
{
    // dummy comment #5
    const(char*)* function () fptr_0;

    int function () is_sth; // dummy comment #6

    // dummy comment #7
    void function (foo_t* foo) do_sth;
}

alias bar_t = bar_s;
D");

}

