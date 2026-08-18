///|
test "CLI selects requested output formats" {
  assert_true(output_format(["--json"]) == @moonbvhkit.ReportJson)
  assert_true(output_format(["--csv"]) == @moonbvhkit.ReportCsv)
  assert_true(output_format([]) == @moonbvhkit.ReportText)
}

///|
test "CLI resample target parses and clamps input" {
  assert_eq(resample_target(["--resample", "12"]), 12)
  assert_eq(resample_target(["--resample", "invalid"]), 8)
  assert_eq(resample_target(["--resample", "0"]), 1)
}

///|
test "CLI batch fixture includes accepted and blocked assets" {
  let report = fixture_batch_report(["--profile", "strict-ci"])
  assert_eq(report.asset_count, 3)
  assert_true(report.accepted_count > 0)
  assert_true(report.blocked_count > 0)
}

///|
test "CLI batch text identifies every fixture" {
  let text = batch_report_to_text(fixture_batch_report([]))
  assert_true(text.find("walk:") != None)
  assert_true(text.find("static-pose:") != None)
  assert_true(text.find("broken-frame-width:") != None)
}
