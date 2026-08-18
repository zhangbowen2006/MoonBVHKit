///|
test "quality report grades valid fixture as excellent" {
  let report = @moonbvhkit.quality_report_from_bvh(
    @moonbvhkit.fixture_walk_bvh(),
  )
  assert_true(report.grade == @moonbvhkit.QualityExcellent)
  assert_eq(report.score, 100)
  assert_true(report.ok_for_import())
}

///|
test "quality report converts parse failure into blocked grade" {
  let report = @moonbvhkit.quality_report_from_bvh(
    @moonbvhkit.fixture_invalid_frame_width(),
  )
  assert_true(report.grade == @moonbvhkit.QualityBlocked)
  assert_eq(report.score, 0)
  assert_true(!report.ok_for_import())
}

///|
test "quality report includes validation warnings" {
  let parsed = @moonbvhkit.parse_bvh(@moonbvhkit.fixture_unknown_channel())
  assert_true(parsed.ok)
  let report = @moonbvhkit.quality_report(parsed.document)
  assert_true(report.score < 100)
  assert_true(report.signals.length() > 0)
}

///|
test "quality report text and json are exportable" {
  let report = @moonbvhkit.quality_report_from_bvh(
    @moonbvhkit.fixture_walk_bvh(),
  )
  assert_true(
    @moonbvhkit.quality_report_to_text(report).find("quality=") != None,
  )
  assert_true(
    @moonbvhkit.quality_report_to_json(report).find("\"score\":100") != None,
  )
  assert_true(
    @moonbvhkit.quality_report_to_csv(report).find("recommended_action") != None,
  )
}

///|
test "JUnit quality report represents a clean asset" {
  let report = @moonbvhkit.quality_report_from_bvh(
    @moonbvhkit.fixture_walk_bvh(),
  )
  let xml = @moonbvhkit.quality_report_to_junit_xml(report)
  assert_true(xml.find("tests=\"1\"") != None)
  assert_true(xml.find("failures=\"0\"") != None)
  assert_true(xml.find("<testcase name=\"quality\"") != None)
}

///|
test "JUnit quality report maps parser errors to failures" {
  let report = @moonbvhkit.quality_report_from_bvh(
    @moonbvhkit.fixture_invalid_frame_width(),
  )
  let xml = @moonbvhkit.quality_report_to_junit_xml(report)
  assert_true(xml.find("failures=\"1\"") != None)
  assert_true(xml.find("<failure type=\"error\"") != None)
}

///|
test "JUnit quality report escapes signal and suite text" {
  let report = @moonbvhkit.BvhQualityReport::new(0, [
    @moonbvhkit.BvhQualitySignal::new(
      @moonbvhkit.IssueError,
      "bad<tag>",
      -100,
      "unsafe & \"quoted\" value",
    ),
  ])
  let xml = @moonbvhkit.quality_report_to_junit_xml(
    report,
    suite_name="asset<&>",
  )
  assert_true(xml.find("asset&lt;&amp;&gt;") != None)
  assert_true(xml.find("bad&lt;tag&gt;") != None)
  assert_true(xml.find("unsafe &amp; &quot;quoted&quot; value") != None)
}

///|
test "quality action helper returns stable import action" {
  assert_eq(
    @moonbvhkit.quality_action_for_bvh(@moonbvhkit.fixture_walk_bvh()),
    "accept",
  )
  assert_eq(
    @moonbvhkit.quality_action_for_bvh(
      @moonbvhkit.fixture_invalid_missing_motion(),
    ),
    "fix-before-import",
  )
}

///|
test "quality grade labels are stable" {
  assert_eq(@moonbvhkit.QualityExcellent.to_string(), "excellent")
  assert_eq(@moonbvhkit.QualityUsable.recommended_action(), "accept-with-notes")
  assert_eq(@moonbvhkit.QualityNeedsReview.to_string(), "needs-review")
  assert_eq(
    @moonbvhkit.QualityBlocked.recommended_action(),
    "fix-before-import",
  )
}
