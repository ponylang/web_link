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

## Project Status

**Current state**: Initial setup, no features implemented yet.

## Architecture

Single package: `web_link`.

### `web_link` Package

- **Public API**: (none yet)

### Testing

Single test runner in `web_link/_test.pony`.
