use "pony_test"
use "pony_check"
use "collections"

// ---------------------------------------------------------------------------
// Generators
// ---------------------------------------------------------------------------

primitive _ValidLinkHeaderGen
  fun single_link(): Generator[(String val, String val, String val)] =>
    """
    Generate (header, expected_target, expected_rel) tuples for single links.
    """
    let uri_gen = Generators.one_of[String val](
      [ "https://example.com/page/2"
        "http://foo.bar/baz?q=1&r=2"
        "/relative/path"
        "https://api.github.com/repos?page=3"
        "urn:example:resource"
      ])
    let rel_gen = Generators.one_of[String val](
      ["next"; "prev"; "last"; "first"; "self"; "alternate"])

    Generators.zip2[String val, String val](uri_gen, rel_gen)
      .map[(String val, String val, String val)](
        {(pair: (String val, String val))
          : (String val, String val, String val)
        =>
          (let uri, let rel) = pair
          let header = recover val
            String
              .>push('<')
              .>append(uri)
              .>append(">; rel=\"")
              .>append(rel)
              .>push('"')
          end
          (header, uri, rel)
        })

  fun with_extra_params()
    : Generator[(String val, String val, String val)]
  =>
    """
    Generate single links with extra parameters beyond rel.
    """
    let uri_gen = Generators.one_of[String val](
      [ "https://example.com/page/2"
        "http://foo.bar/baz"
        "/items"
      ])
    let rel_gen = Generators.one_of[String val](
      ["next"; "prev"; "last"; "self"])
    let extra_gen = Generators.one_of[String val](
      [ "; type=\"text/html\""
        "; title=\"Page Title\""
        "; hreflang=\"en\""
        "; type=\"application/json\"; title=\"API\""
      ])

    Generators.zip3[String val, String val, String val](
      uri_gen, rel_gen, extra_gen)
      .map[(String val, String val, String val)](
        {(triple: (String val, String val, String val))
          : (String val, String val, String val)
        =>
          (let uri, let rel, let extra) = triple
          let header = recover val
            String
              .>push('<')
              .>append(uri)
              .>append(">; rel=\"")
              .>append(rel)
              .>push('"')
              .>append(extra)
          end
          (header, uri, rel)
        })

primitive _InvalidLinkHeaderGen
  fun apply(): Generator[String val] =>
    """
    Generate strings that should fail to parse as Link headers.
    Covers distinct failure modes.
    """
    Generators.one_of[String val](
      [ "https://example.com"                        // no angle brackets
        "<https://example.com>; type=\"text/html\""  // no rel
        "<https://example.com"                       // unterminated URI
        "<https://example.com>; rel=\"next"          // unterminated quote
        "<https://example.com> rel=\"next\""         // missing semicolon
        "< >; rel=\"next\" garbage"                  // trailing garbage
        "<https://example.com>; =\"next\""           // empty param name
      ])

// ---------------------------------------------------------------------------
// Property Tests
// ---------------------------------------------------------------------------

class iso _PropertyValidLinkHeaderAccepted is
  Property1[(String val, String val, String val)]
  """
  Valid single-link headers always parse successfully and produce a link
  whose target and rel match the generated inputs.
  """
  fun name(): String =>
    "property: valid link headers always parse successfully"

  fun gen(): Generator[(String val, String val, String val)] =>
    Generators.frequency[(String val, String val, String val)](
      [ (3, _ValidLinkHeaderGen.single_link())
        (1, _ValidLinkHeaderGen.with_extra_params())
      ])

  fun ref property(
    sample: (String val, String val, String val),
    h: PropertyHelper)
  =>
    (let header, let expected_target, let expected_rel) = sample
    match ParseLinkHeader(header)
    | let links: Array[WebLink val] val =>
      h.assert_eq[USize](links.size(), 1,
        "expected 1 link for: " + header)
      try
        h.assert_eq[String val](links(0)?.target, expected_target)
        h.assert_eq[String val](links(0)?.rel(), expected_rel)
      else
        h.fail("could not access first link")
      end
    | let err: InvalidLinkHeader val =>
      h.fail("expected success but got error for: " + header)
    end

class iso _PropertyInvalidLinkHeaderRejected is Property1[String val]
  """
  Generated invalid inputs always return InvalidLinkHeader.
  """
  fun name(): String =>
    "property: invalid link headers always rejected"

  fun gen(): Generator[String val] =>
    _InvalidLinkHeaderGen()

  fun ref property(sample: String val, h: PropertyHelper) =>
    match ParseLinkHeader(sample)
    | let links: Array[WebLink val] val =>
      h.fail("expected error but got " + links.size().string()
        + " links for: " + sample)
    | let err: InvalidLinkHeader val => None
    end

class iso _PropertyWebLinkStringRoundtrip is
  Property1[(String val, String val, String val)]
  """
  For any parsed WebLink, serializing with string() and re-parsing produces
  an equivalent link.
  """
  fun name(): String =>
    "property: WebLink.string() roundtrips through parser"

  fun gen(): Generator[(String val, String val, String val)] =>
    _ValidLinkHeaderGen.single_link()

  fun ref property(
    sample: (String val, String val, String val),
    h: PropertyHelper)
  =>
    (let header, _, _) = sample
    match ParseLinkHeader(header)
    | let links: Array[WebLink val] val =>
      try
        let link = links(0)?
        let serialized: String val = link.string()
        match ParseLinkHeader(serialized)
        | let reparsed: Array[WebLink val] val =>
          h.assert_eq[USize](reparsed.size(), 1,
            "reparsed should have 1 link")
          try
            h.assert_true(link == reparsed(0)?,
              "roundtrip should produce equal link")
          else
            h.fail("could not access reparsed link")
          end
        | let err: InvalidLinkHeader val =>
          h.fail("reparsing failed for: " + serialized)
        end
      else
        h.fail("could not access first link")
      end
    | let err: InvalidLinkHeader val =>
      h.fail("initial parse failed for: " + header)
    end

class iso _PropertyRelAlwaysPresent is
  Property1[(String val, String val, String val)]
  """
  Every parsed WebLink has a non-empty rel().
  """
  fun name(): String =>
    "property: parsed links always have non-empty rel"

  fun gen(): Generator[(String val, String val, String val)] =>
    _ValidLinkHeaderGen.single_link()

  fun ref property(
    sample: (String val, String val, String val),
    h: PropertyHelper)
  =>
    (let header, _, _) = sample
    match ParseLinkHeader(header)
    | let links: Array[WebLink val] val =>
      for link in links.values() do
        h.assert_true(link.rel().size() > 0,
          "rel should be non-empty")
      end
    | let err: InvalidLinkHeader val =>
      h.fail("expected success for: " + header)
    end

class iso _PropertyMultipleLinksParsed is Property1[USize]
  """
  Joining N valid link inputs with commas parses to exactly N links
  with matching targets and rels.
  """
  fun name(): String =>
    "property: joined valid links parse to correct count"

  fun gen(): Generator[USize] =>
    Generators.usize(2, 5)

  fun ref property(count: USize, h: PropertyHelper) =>
    let uris = [as String val:
      "https://a.com"; "https://b.com"; "https://c.com"
      "https://d.com"; "https://e.com"
    ]
    let rels = [as String val:
      "next"; "prev"; "last"; "first"; "self"
    ]

    var header = recover iso String end
    var i: USize = 0
    while i < count do
      if i > 0 then header.append(", ") end
      try
        header.push('<')
        header.append(uris(i)?)
        header.append(">; rel=\"")
        header.append(rels(i)?)
        header.push('"')
      else
        _Unreachable()
      end
      i = i + 1
    end

    let hdr: String val = consume header
    match ParseLinkHeader(hdr)
    | let links: Array[WebLink val] val =>
      h.assert_eq[USize](links.size(), count,
        "expected " + count.string() + " links")
      var j: USize = 0
      while j < count do
        try
          h.assert_eq[String val](links(j)?.target, uris(j)?)
          h.assert_eq[String val](links(j)?.rel(), rels(j)?)
        else
          h.fail("could not access link or expected value at index "
            + j.string())
        end
        j = j + 1
      end
    | let err: InvalidLinkHeader val =>
      h.fail("expected success for: " + hdr)
    end

// ---------------------------------------------------------------------------
// Example-Based Tests
// ---------------------------------------------------------------------------

class iso _TestSingleLinkWithRel is UnitTest
  fun name(): String => "parse: single link with rel"

  fun apply(h: TestHelper) =>
    let input = "<https://example.com/page/2>; rel=\"next\""
    match ParseLinkHeader(input)
    | let links: Array[WebLink val] val =>
      h.assert_eq[USize](links.size(), 1)
      try
        h.assert_eq[String val](links(0)?.target,
          "https://example.com/page/2")
        h.assert_eq[String val](links(0)?.rel(), "next")
      else
        h.fail("could not access first link")
      end
    | let err: InvalidLinkHeader val =>
      h.fail("expected success")
    end

class iso _TestMultipleCommaLinks is UnitTest
  fun name(): String => "parse: multiple comma-separated links"

  fun apply(h: TestHelper) =>
    let input: String val =
      "<https://example.com/2>; rel=\"next\", " +
      "<https://example.com/5>; rel=\"last\""
    match ParseLinkHeader(input)
    | let links: Array[WebLink val] val =>
      h.assert_eq[USize](links.size(), 2)
      try
        h.assert_eq[String val](links(0)?.target,
          "https://example.com/2")
        h.assert_eq[String val](links(0)?.rel(), "next")
        h.assert_eq[String val](links(1)?.target,
          "https://example.com/5")
        h.assert_eq[String val](links(1)?.rel(), "last")
      else
        h.fail("could not access links")
      end
    | let err: InvalidLinkHeader val =>
      h.fail("expected success")
    end

class iso _TestMultipleParams is UnitTest
  fun name(): String => "parse: link with multiple parameters"

  fun apply(h: TestHelper) =>
    let input: String val =
      "<https://example.com>; rel=\"alternate\"; " +
      "type=\"text/html\"; hreflang=\"en\""
    match ParseLinkHeader(input)
    | let links: Array[WebLink val] val =>
      h.assert_eq[USize](links.size(), 1)
      try
        let link = links(0)?
        h.assert_eq[String val](link.rel(), "alternate")
        match link.param("type")
        | let v: String val =>
          h.assert_eq[String val](v, "text/html")
        | None => h.fail("expected type param")
        end
        match link.param("hreflang")
        | let v: String val =>
          h.assert_eq[String val](v, "en")
        | None => h.fail("expected hreflang param")
        end
      else
        h.fail("could not access link")
      end
    | let err: InvalidLinkHeader val =>
      h.fail("expected success")
    end

class iso _TestValuelessParam is UnitTest
  fun name(): String => "parse: valueless parameter"

  fun apply(h: TestHelper) =>
    let input = "<https://example.com>; rel=\"next\"; myext"
    match ParseLinkHeader(input)
    | let links: Array[WebLink val] val =>
      h.assert_eq[USize](links.size(), 1)
      try
        let link = links(0)?
        match link.param("myext")
        | let v: String val =>
          h.assert_eq[String val](v, "")
        | None => h.fail("expected myext param")
        end
      else
        h.fail("could not access link")
      end
    | let err: InvalidLinkHeader val =>
      h.fail("expected success")
    end

class iso _TestTokenValues is UnitTest
  fun name(): String => "parse: token (unquoted) parameter values"

  fun apply(h: TestHelper) =>
    let input = "<https://example.com>; rel=next"
    match ParseLinkHeader(input)
    | let links: Array[WebLink val] val =>
      h.assert_eq[USize](links.size(), 1)
      try
        h.assert_eq[String val](links(0)?.rel(), "next")
      else
        h.fail("could not access link")
      end
    | let err: InvalidLinkHeader val =>
      h.fail("expected success")
    end

class iso _TestQuotedStringEscapes is UnitTest
  fun name(): String => "parse: quoted string with backslash escapes"

  fun apply(h: TestHelper) =>
    let input: String val =
      "<https://example.com>; rel=\"next\"; " +
      "title=\"say \\\"hello\\\" and \\\\done\""
    match ParseLinkHeader(input)
    | let links: Array[WebLink val] val =>
      h.assert_eq[USize](links.size(), 1)
      try
        let link = links(0)?
        match link.param("title")
        | let v: String val =>
          h.assert_eq[String val](v, "say \"hello\" and \\done")
        | None => h.fail("expected title param")
        end
      else
        h.fail("could not access link")
      end
    | let err: InvalidLinkHeader val =>
      h.fail("expected success")
    end

class iso _TestExtraWhitespace is UnitTest
  fun name(): String => "parse: extra whitespace around ; and ="

  fun apply(h: TestHelper) =>
    let input =
      "<https://example.com> ; rel = \"next\" ; type = \"text/html\""
    match ParseLinkHeader(input)
    | let links: Array[WebLink val] val =>
      h.assert_eq[USize](links.size(), 1)
      try
        h.assert_eq[String val](links(0)?.rel(), "next")
        match links(0)?.param("type")
        | let v: String val =>
          h.assert_eq[String val](v, "text/html")
        | None => h.fail("expected type param")
        end
      else
        h.fail("could not access link")
      end
    | let err: InvalidLinkHeader val =>
      h.fail("expected success")
    end

class iso _TestEmptyElements is UnitTest
  fun name(): String => "parse: empty elements from consecutive commas"

  fun apply(h: TestHelper) =>
    let input: String val =
      ",, <https://example.com/a>; rel=\"first\",, " +
      "<https://example.com/b>; rel=\"last\" ,,"
    match ParseLinkHeader(input)
    | let links: Array[WebLink val] val =>
      h.assert_eq[USize](links.size(), 2)
      try
        h.assert_eq[String val](links(0)?.target,
          "https://example.com/a")
        h.assert_eq[String val](links(1)?.target,
          "https://example.com/b")
      else
        h.fail("could not access links")
      end
    | let err: InvalidLinkHeader val =>
      h.fail("expected success")
    end

class iso _TestCommaInsideUri is UnitTest
  fun name(): String => "parse: URI containing comma inside angle brackets"

  fun apply(h: TestHelper) =>
    let input = "<https://example.com/a,b,c>; rel=\"next\""
    match ParseLinkHeader(input)
    | let links: Array[WebLink val] val =>
      h.assert_eq[USize](links.size(), 1)
      try
        h.assert_eq[String val](links(0)?.target,
          "https://example.com/a,b,c")
      else
        h.fail("could not access link")
      end
    | let err: InvalidLinkHeader val =>
      h.fail("expected success")
    end

class iso _TestCaseInsensitiveParams is UnitTest
  fun name(): String => "parse: parameter names are lowercased"

  fun apply(h: TestHelper) =>
    let input = "<https://example.com>; REL=\"next\"; Type=\"text/html\""
    match ParseLinkHeader(input)
    | let links: Array[WebLink val] val =>
      h.assert_eq[USize](links.size(), 1)
      try
        h.assert_eq[String val](links(0)?.rel(), "next")
        match links(0)?.param("type")
        | let v: String val =>
          h.assert_eq[String val](v, "text/html")
        | None => h.fail("expected type param")
        end
      else
        h.fail("could not access link")
      end
    | let err: InvalidLinkHeader val =>
      h.fail("expected success")
    end

class iso _TestMultipleRels is UnitTest
  fun name(): String => "parse: multiple space-separated rels"

  fun apply(h: TestHelper) =>
    let input = "<https://example.com>; rel=\"next prefetch\""
    match ParseLinkHeader(input)
    | let links: Array[WebLink val] val =>
      h.assert_eq[USize](links.size(), 1)
      try
        h.assert_eq[String val](links(0)?.rel(), "next prefetch")
      else
        h.fail("could not access link")
      end
    | let err: InvalidLinkHeader val =>
      h.fail("expected success")
    end

class iso _TestGitHubPagination is UnitTest
  fun name(): String => "parse: real GitHub pagination Link header"

  fun apply(h: TestHelper) =>
    let input: String val =
      "<https://api.github.com/repos/octocat/Hello-World/issues?page=2>" +
      "; rel=\"next\", " +
      "<https://api.github.com/repos/octocat/Hello-World/issues?page=5>" +
      "; rel=\"last\""
    match ParseLinkHeader(input)
    | let links: Array[WebLink val] val =>
      h.assert_eq[USize](links.size(), 2)
      try
        h.assert_eq[String val](links(0)?.rel(), "next")
        h.assert_eq[String val](links(1)?.rel(), "last")
        h.assert_true(
          links(0)?.target.contains("page=2"),
          "first link should contain page=2")
        h.assert_true(
          links(1)?.target.contains("page=5"),
          "second link should contain page=5")
      else
        h.fail("could not access links")
      end
    | let err: InvalidLinkHeader val =>
      h.fail("expected success")
    end

class iso _TestEmptyInput is UnitTest
  fun name(): String => "parse: empty input returns empty array"

  fun apply(h: TestHelper) =>
    match ParseLinkHeader("")
    | let links: Array[WebLink val] val =>
      h.assert_eq[USize](links.size(), 0)
    | let err: InvalidLinkHeader val =>
      h.fail("expected empty array, not error")
    end

class iso _TestWhitespaceInput is UnitTest
  fun name(): String => "parse: whitespace-only input returns empty array"

  fun apply(h: TestHelper) =>
    match ParseLinkHeader("   \t  ")
    | let links: Array[WebLink val] val =>
      h.assert_eq[USize](links.size(), 0)
    | let err: InvalidLinkHeader val =>
      h.fail("expected empty array, not error")
    end

class iso _TestSemicolonsInQuotedString is UnitTest
  fun name(): String => "parse: semicolons inside quoted string values"

  fun apply(h: TestHelper) =>
    let input =
      "<https://example.com>; rel=\"next\"; title=\"a;b;c\""
    match ParseLinkHeader(input)
    | let links: Array[WebLink val] val =>
      h.assert_eq[USize](links.size(), 1)
      try
        match links(0)?.param("title")
        | let v: String val =>
          h.assert_eq[String val](v, "a;b;c")
        | None => h.fail("expected title param")
        end
      else
        h.fail("could not access link")
      end
    | let err: InvalidLinkHeader val =>
      h.fail("expected success")
    end

class iso _TestDuplicateParamsFirstWins is UnitTest
  fun name(): String => "parse: duplicate parameters — first wins"

  fun apply(h: TestHelper) =>
    let input =
      "<https://example.com>; rel=\"next\"; title=\"first\"; title=\"second\""
    match ParseLinkHeader(input)
    | let links: Array[WebLink val] val =>
      h.assert_eq[USize](links.size(), 1)
      try
        match links(0)?.param("title")
        | let v: String val =>
          h.assert_eq[String val](v, "first")
        | None => h.fail("expected title param")
        end
      else
        h.fail("could not access link")
      end
    | let err: InvalidLinkHeader val =>
      h.fail("expected success")
    end

// --- Invalid input tests ---

class iso _TestInvalidNoAngleBrackets is UnitTest
  fun name(): String => "parse invalid: no angle brackets"

  fun apply(h: TestHelper) =>
    match ParseLinkHeader("https://example.com; rel=\"next\"")
    | let links: Array[WebLink val] val =>
      h.fail("expected error")
    | let err: InvalidLinkHeader val => None
    end

class iso _TestInvalidMissingRel is UnitTest
  fun name(): String => "parse invalid: missing rel parameter"

  fun apply(h: TestHelper) =>
    match ParseLinkHeader("<https://example.com>; type=\"text/html\"")
    | let links: Array[WebLink val] val =>
      h.fail("expected error")
    | let err: InvalidLinkHeader val => None
    end

class iso _TestInvalidUnterminatedUri is UnitTest
  fun name(): String => "parse invalid: unterminated URI"

  fun apply(h: TestHelper) =>
    match ParseLinkHeader("<https://example.com")
    | let links: Array[WebLink val] val =>
      h.fail("expected error")
    | let err: InvalidLinkHeader val => None
    end

class iso _TestInvalidUnterminatedQuote is UnitTest
  fun name(): String => "parse invalid: unterminated quoted string"

  fun apply(h: TestHelper) =>
    match ParseLinkHeader("<https://example.com>; rel=\"next")
    | let links: Array[WebLink val] val =>
      h.fail("expected error")
    | let err: InvalidLinkHeader val => None
    end

// --- WebLink equality and string() tests ---

class iso _TestWebLinkEquality is UnitTest
  fun name(): String => "WebLink: equality"

  fun apply(h: TestHelper) =>
    let params1 = recover val
      let m = Map[String val, String val]
      m("rel") = "next"
      m("type") = "text/html"
      m
    end
    let params2 = recover val
      let m = Map[String val, String val]
      m("rel") = "next"
      m("type") = "text/html"
      m
    end
    let params3 = recover val
      let m = Map[String val, String val]
      m("rel") = "prev"
      m
    end

    let a = WebLink("https://a.com", params1)
    let b = WebLink("https://a.com", params2)
    let c = WebLink("https://a.com", params3)
    let d = WebLink("https://b.com", params1)

    h.assert_true(a == b, "same target+params should be equal")
    h.assert_false(a == c, "different params should not be equal")
    h.assert_false(a == d, "different targets should not be equal")

class iso _TestWebLinkString is UnitTest
  fun name(): String => "WebLink: string() serialization"

  fun apply(h: TestHelper) =>
    let params' = recover val
      let m = Map[String val, String val]
      m("rel") = "next"
      m("type") = "text/html"
      m("title") = "Page 2"
      m
    end
    let link = WebLink("https://example.com", params')
    let result: String val = link.string()

    // rel comes first, then remaining sorted: title, type
    h.assert_eq[String val](result,
      "<https://example.com>; rel=\"next\"; title=\"Page 2\"" +
      "; type=\"text/html\"")

class iso _TestWebLinkStringEscaping is UnitTest
  fun name(): String => "WebLink: string() escapes quotes and backslashes"

  fun apply(h: TestHelper) =>
    let params' = recover val
      let m = Map[String val, String val]
      m("rel") = "next"
      m("title") = "say \"hi\" \\ done"
      m
    end
    let link = WebLink("https://example.com", params')
    let result: String val = link.string()

    h.assert_eq[String val](result,
      "<https://example.com>; rel=\"next\"" +
      "; title=\"say \\\"hi\\\" \\\\ done\"")
