use "../../web_link"

actor Main
  new create(env: Env) =>
    let header: String val =
      "<https://api.example.com/items?page=2>; rel=\"next\", " +
      "<https://api.example.com/items?page=5>; rel=\"last\""

    match ParseLinkHeader(header)
    | let links: Array[WebLink val] val =>
      env.out.print("Parsed " + links.size().string() + " links:")
      for link in links.values() do
        env.out.print("  target: " + link.target)
        env.out.print("  rel:    " + link.rel())
        env.out.print("  ---")
      end
    | let err: InvalidLinkHeader val =>
      env.err.print("Parse error: " + err.string())
    end
