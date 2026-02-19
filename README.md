# web_link

Parser for [RFC 8288](https://www.rfc-editor.org/rfc/rfc8288) (Web Linking) HTTP Link headers in Pony. Implements the link-value grammar from Section 3 including quoted-string parameters, OWS/BWS handling, and multi-link comma-separated headers.

Multiple `hreflang` values on a single link (RFC 8288 allows repeated `hreflang` parameters) are not supported; only the first occurrence is kept. RFC 8187 extended parameter decoding (e.g. `title*`) is not performed; the raw value is stored as-is.

## Status

Under development. The API is not yet stable.

## Installation

* Install [corral](https://github.com/ponylang/corral)
* `corral add github.com/ponylang/web_link.git --version 0.1.0`
* `corral fetch` to fetch your dependencies
* `use "web_link"` to include this package
* `corral run -- ponyc` to compile your application

## Usage

See [examples](examples/) for usage demonstrations.

## API Documentation

[https://ponylang.github.io/web_link](https://ponylang.github.io/web_link)
