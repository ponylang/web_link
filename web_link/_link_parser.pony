use "collections"

class ref _LinkParser
  """
  Hand-rolled recursive descent parser for RFC 8288 Link headers.

  Grammar:
    Link       = #link-value
    link-value = "<" URI-Reference ">" *( OWS ";" OWS link-param )
    link-param = token BWS [ "=" BWS ( token / quoted-string ) ]
  """
  let _input: String val
  var _pos: USize

  new ref create(input: String val) =>
    _input = input
    _pos = 0

  fun ref parse(): (Array[WebLink val] val | InvalidLinkHeader val) =>
    """
    Parse a complete Link header value into an array of links.

    Empty or whitespace-only input returns an empty array.
    Empty list elements (consecutive commas) are skipped per RFC 7230.
    """
    var result: Array[WebLink val] iso =
      recover iso Array[WebLink val] end

    _skip_ows()
    while _pos < _input.size() do
      // Skip empty list elements (leading/consecutive commas)
      try
        if _input(_pos)? == ',' then
          _pos = _pos + 1
          _skip_ows()
          continue
        end
      else
        _Unreachable()
        return InvalidLinkHeader
      end

      match _parse_link_value()
      | let link: WebLink val => result.push(link)
      | let err: InvalidLinkHeader val => return err
      end

      _skip_ows()
      if _pos < _input.size() then
        try
          if _input(_pos)? == ',' then
            _pos = _pos + 1
            _skip_ows()
          else
            return InvalidLinkHeader
          end
        else
          _Unreachable()
          return InvalidLinkHeader
        end
      end
    end

    consume result

  fun ref _parse_link_value(): (WebLink val | InvalidLinkHeader val) =>
    let target' = match _parse_uri_reference()
    | let u: String val => u
    | let err: InvalidLinkHeader val => return err
    end

    let params': Map[String val, String val] val = match _parse_params()
    | let m: Map[String val, String val] iso => consume m
    | let err: InvalidLinkHeader val => return err
    end

    if not params'.contains("rel") then
      return InvalidLinkHeader
    end

    WebLink(target', params')

  fun ref _parse_uri_reference(): (String val | InvalidLinkHeader val) =>
    // Expect '<'
    try
      if (_pos >= _input.size()) or (_input(_pos)? != '<') then
        return InvalidLinkHeader
      end
    else
      _Unreachable()
      return InvalidLinkHeader
    end
    _pos = _pos + 1

    let start = _pos
    // Scan for '>' — commas inside <...> are part of the URI
    while _pos < _input.size() do
      try
        if _input(_pos)? == '>' then
          let uri = _input.substring(start.isize(), _pos.isize())
          _pos = _pos + 1
          return uri
        end
        _pos = _pos + 1
      else
        _Unreachable()
        return InvalidLinkHeader
      end
    end

    // Unterminated URI reference
    InvalidLinkHeader

  fun ref _parse_params()
    : (Map[String val, String val] iso^ | InvalidLinkHeader val)
  =>
    var params': Map[String val, String val] iso =
      recover iso Map[String val, String val] end

    while _pos < _input.size() do
      _skip_ows()
      if _pos >= _input.size() then break end

      try
        let ch = _input(_pos)?
        if ch == ',' then break end
        if ch != ';' then return InvalidLinkHeader end
      else
        _Unreachable()
        return InvalidLinkHeader
      end

      _pos = _pos + 1 // consume ';'
      _skip_ows()

      match _parse_link_param()
      | (let k: String val, let v: String val) =>
        if not params'.contains(k) then
          params'(k) = v
        end
      | let err: InvalidLinkHeader val => return err
      end
    end

    consume params'

  fun ref _parse_link_param()
    : ((String val, String val) | InvalidLinkHeader val)
  =>
    let name = match _parse_token_lower()
    | let t: String val => t
    | let err: InvalidLinkHeader val => return err
    end

    _skip_ows() // BWS before '='

    // Check for '=' (valueless params get empty string)
    try
      if (_pos < _input.size()) and (_input(_pos)? == '=') then
        _pos = _pos + 1
        _skip_ows() // BWS after '='

        // Parse value: quoted-string or token
        if (_pos < _input.size()) and (_input(_pos)? == '"') then
          match _parse_quoted_string()
          | let v: String val => return (name, v)
          | let err: InvalidLinkHeader val => return err
          end
        else
          match _parse_token()
          | let v: String val => return (name, v)
          | let err: InvalidLinkHeader val => return err
          end
        end
      end
    else
      _Unreachable()
      return InvalidLinkHeader
    end

    // Valueless parameter
    (name, "")

  fun ref _parse_token(): (String val | InvalidLinkHeader val) =>
    let start = _pos
    while _pos < _input.size() do
      try
        if not _is_tchar(_input(_pos)?) then break end
        _pos = _pos + 1
      else
        _Unreachable()
        return InvalidLinkHeader
      end
    end

    if _pos == start then
      return InvalidLinkHeader
    end

    _input.substring(start.isize(), _pos.isize())

  fun ref _parse_token_lower(): (String val | InvalidLinkHeader val) =>
    """
    Parse a token and return it lowercased.
    """
    let start = _pos
    var result: String iso = recover iso String end
    while _pos < _input.size() do
      try
        let ch = _input(_pos)?
        if not _is_tchar(ch) then break end
        if (ch >= 'A') and (ch <= 'Z') then
          result.push(ch + 32)
        else
          result.push(ch)
        end
        _pos = _pos + 1
      else
        _Unreachable()
        return InvalidLinkHeader
      end
    end

    if _pos == start then
      return InvalidLinkHeader
    end

    consume result

  fun ref _parse_quoted_string(): (String val | InvalidLinkHeader val) =>
    // Expect opening '"'
    try
      if (_pos >= _input.size()) or (_input(_pos)? != '"') then
        return InvalidLinkHeader
      end
    else
      _Unreachable()
      return InvalidLinkHeader
    end
    _pos = _pos + 1

    var result: String iso = recover iso String end
    while _pos < _input.size() do
      try
        let ch = _input(_pos)?
        if ch == '"' then
          _pos = _pos + 1
          return consume result
        elseif ch == '\\' then
          _pos = _pos + 1
          if _pos >= _input.size() then return InvalidLinkHeader end
          result.push(_input(_pos)?)
          _pos = _pos + 1
        else
          result.push(ch)
          _pos = _pos + 1
        end
      else
        _Unreachable()
        return InvalidLinkHeader
      end
    end

    // Unterminated quoted string
    InvalidLinkHeader

  fun ref _skip_ows() =>
    """
    Skip optional whitespace (SP / HTAB).
    """
    while _pos < _input.size() do
      try
        if not _is_ows(_input(_pos)?) then return end
        _pos = _pos + 1
      else
        _Unreachable()
        return
      end
    end

  fun _is_tchar(ch: U8): Bool =>
    """
    Check if a byte is a valid token character per RFC 7230.
    tchar = "!" / "#" / "$" / "%" / "&" / "'" / "*" / "+" / "-" / "." /
            "^" / "_" / "`" / "|" / "~" / DIGIT / ALPHA
    """
    if (ch >= 'A') and (ch <= 'Z') then return true end
    if (ch >= 'a') and (ch <= 'z') then return true end
    if (ch >= '0') and (ch <= '9') then return true end
    match ch
    | '!' | '#' | '$' | '%' | '&' | '\'' | '*' | '+' | '-' | '.' => true
    | '^' | '_' | '`' | '|' | '~' => true
    else
      false
    end

  fun _is_ows(ch: U8): Bool =>
    """
    Check if a byte is optional whitespace (SP or HTAB).
    """
    (ch == ' ') or (ch == '\t')
