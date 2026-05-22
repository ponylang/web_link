# web_link

Web linking header parser library for Pony.

<!-- contributor-only -->
## Contributing with an AI assistant

This is a Pony project. The ponylang org maintains a set of LLM coding skills. Get set up with them before contributing:

- **Not set up yet?** Install them once:

  ```bash
  git clone https://github.com/ponylang/llm-skills.git
  cd llm-skills
  python install.py
  ```

- **Already set up?** Make sure you're on the latest. If you installed with the script above, `git pull` in the directory where you cloned `llm-skills` and the symlinked skills update automatically — if you set them up another way, refresh them however that setup expects.

See the [llm-skills README](https://github.com/ponylang/llm-skills) for details and other harnesses.

When you start working on this project, load the `pony-skills` skill — it tells your assistant which Pony skill to use for each task.

Read [CONTRIBUTING.md](CONTRIBUTING.md).
<!-- /contributor-only -->

## Building and Testing

```bash
make                    # build and run tests + examples (release)
make test               # same as above
make test-one t=TestName    # run a single test by name
make config=debug       # debug build
make examples     # examples only
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
