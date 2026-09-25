# Run with nix-instantiate --eval --strict lib/tests/gvariant.nix
let
  lib = import ../.;
  inherit (lib) gvariant;
in
lib.runTests {
  testMkTypedContainers = {
    expr =
      map
        (v: {
          text = toString v;
          inherit (v) type;
        })
        (
          with gvariant;
          [
            (mkTyped "ms" "hello'\\\n")
            (mkTyped "b" false)
            (mkTyped "a{sv}" [ ])
            (mkTyped "au" [
              1
              2
            ])
            (mkTyped "aau" [
              [ ]
              [ 1 ]
            ])
            (mkTyped "ms" null)
            (mkTyped "v" (mkVariant (mkTyped "u" 5)))
            (mkTyped "(su)" (mkTuple [
              "key"
              (mkUint32 5)
            ]))
          ]
        );
    expected = [
      {
        text = "@ms 'hello\\'\\\\\\n'";
        type = "ms";
      }
      {
        text = "@b false";
        type = "b";
      }
      {
        text = "@a{sv} []";
        type = "a{sv}";
      }
      {
        text = "@au [1,2]";
        type = "au";
      }
      {
        text = "@aau [[],[1]]";
        type = "aau";
      }
      {
        text = "@ms nothing";
        type = "ms";
      }
      {
        text = "@v <@u 5>";
        type = "v";
      }
      {
        text = "@(su) ('key',@u 5)";
        type = "(su)";
      }
    ];
  };
  testMkCast = {
    expr =
      map
        (v: {
          text = toString v;
          inherit (v) type;
        })
        (
          with gvariant;
          [
            (mkCast "boolean" false)
            (mkCast "byte" 255)
            (mkCast "int16" (-30))
            (mkCast "uint16" 25)
            (mkCast "int32" 26)
            (mkCast "uint32" 24)
            (mkCast "handle" 22)
            (mkCast "int64" 27)
            (mkCast "uint64" 21)
            (mkCast "double" 28.2)
            (mkCast "string" "foo'\\\n")
            (mkCast "objectpath" "/org/gnome/xyz")
            (mkCast "signature" "a{sv}")
            (mkCast "uint32" (mkCast "uint32" 7))
          ]
        );
    expected = [
      {
        text = "boolean false";
        type = "b";
      }
      {
        text = "byte 255";
        type = "y";
      }
      {
        text = "int16 -30";
        type = "n";
      }
      {
        text = "uint16 25";
        type = "q";
      }
      {
        text = "int32 26";
        type = "i";
      }
      {
        text = "uint32 24";
        type = "u";
      }
      {
        text = "handle 22";
        type = "h";
      }
      {
        text = "int64 27";
        type = "x";
      }
      {
        text = "uint64 21";
        type = "t";
      }
      {
        text = "double 28.200000";
        type = "d";
      }
      {
        text = "string 'foo\\'\\\\\\n'";
        type = "s";
      }
      {
        text = "objectpath '/org/gnome/xyz'";
        type = "o";
      }
      {
        text = "signature 'a{sv}'";
        type = "g";
      }
      {
        text = "uint32 uint32 7";
        type = "u";
      }
    ];
  };
  testMkCastUnknown = {
    expr = builtins.tryEval (toString (gvariant.mkCast "unknown" 5));
    expected = {
      success = false;
      value = false;
    };
  };
  testMkByteString = {
    expr =
      map
        (v: {
          text = toString v;
          inherit (v) type;
        })
        (
          with gvariant;
          [
            (mkByteString "")
            (mkByteString ''/home/alice/Music'"'')
            (mkByteString ''\\\a\b\f\n\r\t\v\3777\1\28'"'')
            (mkByteString ''\"'')
            (mkByteString "line\nbreak")
            (mkArray [
              (mkByteString "foo")
              (mkByteString "bar")
            ])
          ]
        );
    expected = [
      {
        text = ''b""'';
        type = "ay";
      }
      {
        text = ''b"/home/alice/Music'\""'';
        type = "ay";
      }
      {
        text = ''b"\\\a\b\f\n\r\t\v\3777\1\28'\""'';
        type = "ay";
      }
      {
        text = ''b"\""'';
        type = "ay";
      }
      {
        text = ''b"line\nbreak"'';
        type = "ay";
      }
      {
        text = ''@aay [b"foo",b"bar"]'';
        type = "aay";
      }
    ];
  };
  testMkByteStringTrailingBackslash = {
    expr = builtins.tryEval (toString (gvariant.mkByteString "\\"));
    expected = {
      success = false;
      value = false;
    };
  };
  testTypedSingletonTuple = {
    expr = toString (gvariant.mkTyped "(s)" (gvariant.mkTuple [ "one" ]));
    expected = "@(s) ('one',)";
  };
  testTypedNestedInferred = {
    expr = toString (
      gvariant.mkTyped "(ua{su}au)" (
        gvariant.mkTuple [
          1
          [ (gvariant.mkDictionaryEntry "key" 2) ]
          [ ]
        ]
      )
    );
    expected = "@(ua{su}au) (1,[{'key',2}],[])";
  };
  testContextDependentContainers = {
    expr =
      map
        ({ value, type }: {
          inferredType = (builtins.tryEval value.type).success;
          standalone = (builtins.tryEval (toString value)).success;
          annotated = toString (gvariant.mkTyped type value);
        })
        [
          {
            value = gvariant.mkTuple [ 1 ];
            type = "(u)";
          }
          {
            value = gvariant.mkTuple [ [ ] ];
            type = "(au)";
          }
          {
            value = gvariant.mkDictionaryEntry "key" 1;
            type = "{su}";
          }
          {
            value = gvariant.mkDictionaryEntry "key" [ ];
            type = "{sau}";
          }
        ];
    expected =
      map
        (annotated: {
          inferredType = false;
          standalone = false;
          inherit annotated;
        })
        [
          "@(u) (1,)"
          "@(au) ([],)"
          "@{su} {'key',1}"
          "@{sau} {'key',[]}"
        ];
  };
  testTypedExplicitInt = {
    expr = toString (gvariant.mkTyped "u" (gvariant.mkInt32 1));
    expected = "@u @i 1";
  };
  testMkTypedInteger = {
    expr = toString (gvariant.mkTyped "u" 5);
    expected = "@u 5";
  };
}
