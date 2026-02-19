primitive InvalidLinkHeader is Stringable
  """
  Returned when a Link header string cannot be parsed.
  """
  fun string(): String iso^ =>
    "InvalidLinkHeader".clone()
