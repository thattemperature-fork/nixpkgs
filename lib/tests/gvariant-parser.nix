# Integration test: nix-build lib/tests/gvariant-parser.nix
{
  pkgs ? import ../.. {
    config = { };
    overlays = [ ];
  },
}:
let
  lib = import ../.;
  cases = with lib.gvariant; [
    {
      value = mkTyped "(s)" (mkTuple [ "one" ]);
      expected = "('one',)";
    }
    {
      value = mkTyped "()" (mkTuple [ ]);
      expected = "()";
    }
    {
      value = mkTyped "mms" (mkJust (mkNothing "s"));
      expected = "@mms just nothing";
    }
    {
      value = mkByteString ''é\0'';
      expected = "[byte 195, 169, 0]";
    }
    {
      value = mkTyped "u" 5;
      expected = "uint32 5";
    }
    {
      value = mkTyped "ms" "hello'\\\n";
      expected = "@ms 'hello\\'\\\\\\n'";
    }
    {
      value = mkTyped "ms" null;
      expected = "@ms nothing";
    }
    {
      value = mkTyped "a{sv}" [ ];
      expected = "@a{sv} {}";
    }
    {
      value = mkTyped "au" [
        1
        2
      ];
      expected = "[uint32 1, 2]";
    }
    {
      value = mkTyped "aau" [
        [ ]
        [ 1 ]
      ];
      expected = "[@au [], [1]]";
    }
    {
      value = mkTyped "(su)" (mkTuple [
        "key"
        (mkUint32 5)
      ]);
      expected = "('key', uint32 5)";
    }
    {
      value = mkTyped "v" (mkVariant (mkTyped "u" 5));
      expected = "<uint32 5>";
    }
    {
      value = mkCast "boolean" false;
      expected = "false";
    }
    {
      value = mkCast "byte" 255;
      expected = "byte 255";
    }
    {
      value = mkCast "int16" (-30);
      expected = "int16 -30";
    }
    {
      value = mkCast "uint16" 25;
      expected = "uint16 25";
    }
    {
      value = mkCast "int32" 26;
      expected = "26";
    }
    {
      value = mkCast "uint32" 24;
      expected = "uint32 24";
    }
    {
      value = mkCast "handle" 22;
      expected = "handle 22";
    }
    {
      value = mkCast "int64" 27;
      expected = "int64 27";
    }
    {
      value = mkCast "uint64" 21;
      expected = "uint64 21";
    }
    {
      value = mkCast "double" 28.2;
      expected = "28.2";
    }
    {
      value = mkCast "string" "foo'\\\n";
      expected = "'foo\\'\\\\\\n'";
    }
    {
      value = mkCast "objectpath" "/org/gnome/xyz";
      expected = "objectpath '/org/gnome/xyz'";
    }
    {
      value = mkCast "signature" "a{sv}";
      expected = "signature 'a{sv}'";
    }
    {
      value = mkCast "uint32" (mkCast "uint32" 7);
      expected = "uint32 7";
    }
    {
      value = mkByteString "";
      expected = "[byte 0]";
    }
    {
      value = mkByteString ''a'"\\\n\3777'';
      expected = "[byte 97, 39, 34, 92, 10, 255, 55, 0]";
    }
    {
      value = mkByteString ''\"'';
      expected = "[byte 34, 0]";
    }
    {
      value = mkByteString "line\nbreak";
      expected = ''b"line\nbreak"'';
    }
    {
      value = mkByteString ''\a\b\f\n\r\t\v\1\28'';
      expected = "[byte 7, 8, 12, 10, 13, 9, 11, 1, 2, 56, 0]";
    }
    {
      value = mkArray [
        (mkByteString "foo")
        (mkByteString "bar")
      ];
      expected = ''[b"foo", b"bar"]'';
    }
    {
      value = mkArray [
        (mkCast "objectpath" "/a")
        (mkCast "objectpath" "/b")
      ];
      expected = "[objectpath '/a', '/b']";
    }
    {
      value = mkArray [ (mkDictionaryEntry "data" (mkVariant (mkByteString ''\377''))) ];
      expected = "{'data': <[byte 255, 0]>}";
    }
  ];
  data = pkgs.writeText "gvariant-cases.json" (
    builtins.toJSON (
      map (case: {
        text = toString case.value;
        type = case.value.type;
        inherit (case) expected;
      }) cases
    )
  );
in
pkgs.runCommand "gvariant-parser-tests" { nativeBuildInputs = [ pkgs.python3 ]; } ''
  python ${./gvariant-parser.py} ${pkgs.glib.out}/lib/libglib-2.0${pkgs.stdenv.hostPlatform.extensions.sharedLibrary} ${data}
  mkdir "$out"
''
