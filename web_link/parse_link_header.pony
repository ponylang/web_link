primitive ParseLinkHeader
  """
  Parse an RFC 8288 Link header value into an array of `WebLink` values.

  Returns `InvalidLinkHeader` when the input is malformed. Empty or
  whitespace-only input returns an empty array.

  ```pony
  match ParseLinkHeader(raw_header)
  | let links: Array[WebLink val] val =>
    for link in links.values() do
      // each link has .target, .rel(), .param(name)
    end
  | let err: InvalidLinkHeader val =>
    // malformed header
  end
  ```
  """
  fun apply(raw: String val)
    : (Array[WebLink val] val | InvalidLinkHeader val)
  =>
    _LinkParser(raw).parse()
