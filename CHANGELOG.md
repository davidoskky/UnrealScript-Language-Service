# UnrealScript Language Service

## 0.6.4 (Feb 16, 2023)

- Fixed [Class-function field hint](https://github.com/EliotVU/UnrealScript-Language-Service/issues/161).
- Fixed [Type checking error when passing an Enum object to a function as argument](https://github.com/EliotVU/UnrealScript-Language-Service/issues/166).
- Fixed [Enum tag reference in a condition expression produces an error when type checking is enabled](https://github.com/EliotVU/UnrealScript-Language-Service/issues/167).
- Fixed [Request textDocument/documentSymbol failed](https://github.com/EliotVU/UnrealScript-Language-Service/issues/169).
- [Add a new diagnostic for UC3 enum based element dimensions; and fix the misplaced range for array dimension diagnostics.](https://github.com/EliotVU/UnrealScript-Language-Service/commit/97e7b1ec9dbd62ae98c81f473a79f20826f18ac5).
- [Fail auto detection when no Object.uc document is present](https://github.com/EliotVU/UnrealScript-Language-Service/commit/1d64bc3771c5e23fa34f9624962e6567d197e879).

## 0.6.3 (Feb 10, 2023)

- Fixed an issue with skipLine() failing on UnrealScript directives i.e. "#exec obj load ..."

## 0.6.2 (Feb 9, 2023)

- Implemented an option to enable auto-detection of the UnrealScript language generation that's being used by the workspace.
- Implemented a new code-action to inline a constant's evaluated value.

- Quality of Life
  - General improvements to how indexing of documents is handled.
  - Fixed parser support for string types that have a fixed size e.g. ```String[255]``` (UE1).
  - Fixed type ```Pointer``` will be no longer recognized if the language is set to generation 3 (this has been displaced by the Core.Object.Pointer struct).
  - Fixed [No symbols found](https://github.com/EliotVU/UnrealScript-Language-Service/issues/157)

## 0.6.1 (Jan 29, 2023)

- The service will now register .u/.upk (the extensions are configurable) files as known package symbols, this means such packages will be included in the auto-completion and indexing of references.
  - Note: The contents of the packages are not yet indexed.

- Implemented [Auto-insert when overriding a function](https://github.com/EliotVU/UnrealScript-Language-Service/issues/153).
- Further improvements have been made to the auto-completion suggestions.

## 0.6.0 (Jan 26, 2023)

- Implemented [LSP Semantic-Tokens #137](https://github.com/EliotVU/UnrealScript-Language-Service/issues/137) (References to a class will now be highlighted as such even where the tmLanguage cannot determine the identifier's type)
  - ![image](https://user-images.githubusercontent.com/808593/211020346-38724ace-2fbe-4d92-b68c-69640ded824f.png)

- Implemented [LSP Workspace Symbols #148](https://github.com/EliotVU/UnrealScript-Language-Service/issues/148)
  - ![image](./docs/media/workspaceSymbols.png)

- Added [UnrealScript snippets #149](https://github.com/EliotVU/UnrealScript-Language-Service/issues/149).

- Typing, major improvements have been made to the type-checking system, there are almost no false-positive errors anymore!
- Archetypes, overall better support for "begin object" constructions.
- Better and more responsive auto-completion suggestions.

- Quality of Life
  - Overall improvements have been made to UnrealScript parsing.
  - Overall improvements to UnrealScript syntax highlighting.
  - Fixed [(DefaultProperties) Issue with structs written on multiple lines](https://github.com/EliotVU/UnrealScript-Language-Service/issues/138).
  - Fixed an issue where a Function call in a member context ```Outer.SomeIdentifier(...)``` could mismatch a Class's name.
  - Partially fixed an issue (in some cases) where a Function/Class invocation could be mistaken for one another.
  - Fixed LSP/documentSymbol [VSCode's Sticky scroll feature](https://github.com/EliotVU/UnrealScript-Language-Service/issues/148).
  - Fixed an issue that caused the document transformer to abort when trying to build a property with bad type-grammar (actually usually triggered by use of  macros).

## 0.5.0 (Nov 8, 2021)

- Autocomplete and IntelliSense
  - Has been displaced with the help of a third-party library [c3](https://github.com/mike-lischke/antlr4-c3).
  - This switch has made it much easier to implement context-aware autocompletes, but more work will be needed to bring it the quality that we all take for granted in popular languages.

- Added the first CodeAction
  - If a type is missing where a class type is expected, the service will now suggest to generate the class for you.

- Syntax highlighting has seen some improvements
  - C++ highlighting in cpptext and structcpptext and fragments.
  - Various tweaks.

- Added missing parameters to UC3 Array intrinsics

    ```UnrealScript
    // This should no longer output a missing argument error.
    ArrayRef.find(value)
    ```

- NameOf and ArrayCount with an expressive argument are now recognized

    ```UnrealScript
    // Even works in const assignments!
    const MY_ARRAYCOUNT              = arraycount(class'Object'.default.ObjectInternal);
    const MY_NAMEOF                  = nameof(class'Object'.default.ObjectInternal);
    ```

- Intrinsic (a relict of UC1) is now a recognized keyword for variables

    ```UnrealScript
    var intrinsic int myInteger;
    ```

- Added a new configuration option
  - Licensee - Epic|XCom

    This option tells the service which UnrealScript edition it should optimize for.

- Quality of Life
  - Fixed [Closing unopened comment](https://github.com/EliotVU/UnrealScript-Language-Service/issues/28).
  - Fixed ["default:" is not highlighted](https://github.com/EliotVU/UnrealScript-Language-Service/issues/22).
  - Fixed ["Spawn" return type is not coerced to its first parameter's type. #21](https://github.com/EliotVU/UnrealScript-Language-Service/issues/21).
  - Fixed ["no viable alternative at input 'return A -='"](https://github.com/EliotVU/UnrealScript-Language-Service/issues/20).
  - Fixed [Highlighting issue regarding a comment if on the same line as a struct declaration #19](https://github.com/EliotVU/UnrealScript-Language-Service/issues/19).
  - Fixed [Class and package name confusion](https://github.com/EliotVU/UnrealScript-Language-Service/issues/15).
  - Fixed ["const ref" argument confusing the parser](https://github.com/EliotVU/UnrealScript-Language-Service/issues/14).
