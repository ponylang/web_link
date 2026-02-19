use "pony_test"
use "pony_check"

actor \nodoc\ Main is TestList
  new create(env: Env) =>
    PonyTest(env, this)

  fun tag tests(test: PonyTest) =>
    // Property tests
    test(Property1UnitTest[
      (String val, String val, String val)
    ](_PropertyValidLinkHeaderAccepted))
    test(Property1UnitTest[String val](
      _PropertyInvalidLinkHeaderRejected))
    test(Property1UnitTest[
      (String val, String val, String val)
    ](_PropertyWebLinkStringRoundtrip))
    test(Property1UnitTest[
      (String val, String val, String val)
    ](_PropertyRelAlwaysPresent))
    test(Property1UnitTest[USize](
      _PropertyMultipleLinksParsed))

    // Example-based tests
    test(_TestSingleLinkWithRel)
    test(_TestMultipleCommaLinks)
    test(_TestMultipleParams)
    test(_TestValuelessParam)
    test(_TestTokenValues)
    test(_TestQuotedStringEscapes)
    test(_TestExtraWhitespace)
    test(_TestEmptyElements)
    test(_TestCommaInsideUri)
    test(_TestCaseInsensitiveParams)
    test(_TestMultipleRels)
    test(_TestGitHubPagination)
    test(_TestEmptyInput)
    test(_TestWhitespaceInput)
    test(_TestSemicolonsInQuotedString)
    test(_TestDuplicateParamsFirstWins)
    test(_TestInvalidNoAngleBrackets)
    test(_TestInvalidMissingRel)
    test(_TestInvalidUnterminatedUri)
    test(_TestInvalidUnterminatedQuote)

    // WebLink type tests
    test(_TestWebLinkEquality)
    test(_TestWebLinkString)
    test(_TestWebLinkStringEscaping)
