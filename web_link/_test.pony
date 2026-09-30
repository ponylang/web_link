use "pony_test"

actor \nodoc\ Main is TestList
  new create(env: Env) =>
    PonyTest(env, this)

  fun tag tests(test: PonyTest) =>
    // Property tests
    test.property(_PropertyValidLinkHeaderAccepted)
    test.property(_PropertyInvalidLinkHeaderRejected)
    test.property(_PropertyWebLinkStringRoundtrip)
    test.property(_PropertyRelAlwaysPresent)
    test.property(_PropertyMultipleLinksParsed)

    // Example-based tests
    test(_TestSingleLinkWithRel)
    test(_TestMultipleCommaLinks)
    test(_TestMultipleParams)
    test(_TestValuelessParam)
    test(_TestTokenValues)
    test(_TestQuotedStringEscapes)
    test(_TestExtraWhitespace)
    test(_TestEmptyElements)
    test(_TestCommaInsideURI)
    test(_TestCaseInsensitiveParams)
    test(_TestMultipleRels)
    test(_TestGitHubPagination)
    test(_TestEmptyInput)
    test(_TestWhitespaceInput)
    test(_TestSemicolonsInQuotedString)
    test(_TestDuplicateParamsFirstWins)
    test(_TestInvalidNoAngleBrackets)
    test(_TestInvalidMissingRel)
    test(_TestInvalidUnterminatedURI)
    test(_TestInvalidUnterminatedQuote)

    // WebLink type tests
    test(_TestWebLinkEquality)
    test(_TestWebLinkString)
    test(_TestWebLinkStringEscaping)
