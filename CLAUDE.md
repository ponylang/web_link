# web_link

Web linking header parser library for Pony.

## Building and Testing

```bash
make                    # build and run tests + examples (release)
make test               # same as above
make config=debug       # debug build
make build-examples     # examples only
make clean              # clean build artifacts + corral cache
```

## Architecture

Single package: `web_link`.

### `web_link` Package

- **Public API**:
  - `ParseLinkHeader` — primitive, parses an RFC 8288 Link header string into `(Array[WebLink val] val | InvalidLinkHeader val)`
  - `WebLink` — `class val`, a single parsed link with `target`, `params`, `rel()`, `param()`, `eq()`, `string()`
  - `InvalidLinkHeader` — primitive, error type implementing `Stringable`
- **Internal**:
  - `_LinkParser` — hand-rolled recursive descent parser
  - `_Unreachable` — crash primitive for guarded code paths

### Testing

Single test runner in `web_link/_test.pony`. Tests in `web_link/_test_parse_link_header.pony` (property-based + example-based).

## Pony Pitfalls Discovered

- **`String.lower()` returns a new string; `lower_in_place()` mutates**: `lower()` is `fun lower(): String iso^` — it clones, lowercases the clone, and returns it. Calling `s.lower()` and discarding the return does nothing. Use `s.lower_in_place()` to mutate, or capture the return: `let lowered = s.lower()`.
- **String concatenation with `+` returns `iso`**: `"a" + "b"` returns `String iso^`. Without a `: String val` type annotation on the `let` binding, the variable captures as `String iso`, which can't be passed where `String val` is expected. Always annotate: `let s: String val = "a" + "b"`.
