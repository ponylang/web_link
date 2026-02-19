"""
# Web Link

RFC 8288 (Web Linking) header parser.

The primary entry point is `ParseLinkHeader`, which takes a raw Link header
string and returns an array of `WebLink` values or an `InvalidLinkHeader` error.

```pony
match ParseLinkHeader(raw_header)
| let links: Array[WebLink val] val =>
  for link in links.values() do
    env.out.print(link.target + " rel=" + link.rel())
  end
| let err: InvalidLinkHeader val =>
  env.err.print("Parse error: " + err.string())
end
```

For simple use cases like HTTP API pagination, `WebLink.rel()` provides direct
access to the required `rel` parameter. Use `WebLink.param()` for other
parameters (`type`, `hreflang`, `title`, etc.).

## Limitations

Multiple `hreflang` values on a single link (RFC 8288 allows repeated
`hreflang` parameters) are not supported; only the first occurrence is kept.
RFC 8187 extended parameter decoding (e.g. `title*`) is not performed; the raw
value is stored as-is.
"""

use "collections"

class val WebLink is (Stringable & Equatable[WebLink])
  """
  A single parsed link from an RFC 8288 Link header.

  Each `WebLink` has a `target` URI-Reference and a set of `params`.
  The `rel` parameter is always present on links produced by
  `ParseLinkHeader`; direct construction does not enforce this.
  """
  let target: String val
  let params: Map[String val, String val] val

  new val create(target': String val,
    params': Map[String val, String val] val)
  =>
    """
    Create a WebLink with the given target URI-Reference and parameters.

    The parser guarantees `rel` presence; direct construction is at the
    caller's risk.
    """
    target = target'
    params = params'

  fun rel(): String val =>
    """
    Return the value of the `rel` parameter, or an empty string if absent.
    """
    try params("rel")? else "" end

  fun param(name: String): (String val | None) =>
    """
    Look up a parameter by name. Returns `None` if absent.
    """
    try params(name)? end

  fun eq(that: WebLink box): Bool =>
    """
    Two links are equal when their targets and all parameter key-value pairs
    match.
    """
    if target != that.target then return false end
    if params.size() != that.params.size() then return false end
    for (k, v) in params.pairs() do
      try
        if that.params(k)? != v then return false end
      else
        return false
      end
    end
    true

  fun string(): String iso^ =>
    """
    Serialize to link-value format. Parameter values are always quoted.
    `rel` is emitted first; remaining parameters are sorted alphabetically
    for deterministic output.
    """
    let t = target
    let p = params
    recover iso
      let buf = String
      buf.push('<')
      buf.append(t)
      buf.push('>')

      let other_keys = Array[String val]
      for (k, _) in p.pairs() do
        if k != "rel" then
          other_keys.push(k)
        end
      end
      Sort[Array[String val], String val](other_keys)

      try
        let rel_val = p("rel")?
        buf.append("; rel=\"")
        for ch in rel_val.values() do
          if ch == '"' then
            buf.append("\\\"")
          elseif ch == '\\' then
            buf.append("\\\\")
          else
            buf.push(ch)
          end
        end
        buf.push('"')
      end

      for key in other_keys.values() do
        try
          let v = p(key)?
          buf.append("; ")
          buf.append(key)
          buf.append("=\"")
          for ch in v.values() do
            if ch == '"' then
              buf.append("\\\"")
            elseif ch == '\\' then
              buf.append("\\\\")
            else
              buf.push(ch)
            end
          end
          buf.push('"')
        end
      end

      buf
    end
