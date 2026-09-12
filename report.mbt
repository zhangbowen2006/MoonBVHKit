///|
pub(all) struct BvhReport {
  ok : Bool
  summary : String
  stats : BvhStats
  validation : BvhValidationReport
  error_code : String
} derive(Eq, @debug.Debug)

///|
pub fn BvhReport::success(
  summary : String,
  stats : BvhStats,
  validation : BvhValidationReport,
) -> BvhReport {
  { ok: validation.ok(), summary, stats, validation, error_code: "", }
}

///|
pub fn BvhReport::failure(error : BvhError) -> BvhReport {
  {
    ok: false,
    summary: "parse failed: \{error.code()} at \{error.line}:\{error.column}",
    stats: BvhStats::empty(),
    validation: BvhValidationReport::new([
      BvhValidationIssue::error(error.code(), error.message),
    ]),
    error_code: error.code(),
  }
}

///|
pub fn build_report(input : String) -> BvhReport {
  let parsed = parse_bvh(input)
  if !parsed.ok {
    BvhReport::failure(parsed.error)
  } else {
    let validation = validate_document(parsed.document)
    BvhReport::success(
      bvh_summary_line(parsed.document),
      analyze_bvh(parsed.document),
      validation,
    )
  }
}

///|
pub fn report_to_text(report : BvhReport) -> String {
  let lines : Array[String] = [
    "MoonBVHKit report",
    "status=\{if report.ok { "ok" } else { "failed" }}",
    "summary=\{report.summary}",
    "joints=\{report.stats.joint_count}",
    "end_sites=\{report.stats.end_site_count}",
    "channels=\{report.stats.channel_count}",
    "frames=\{report.stats.frame_count}",
    "duration_seconds=\{report.stats.duration_seconds}",
    "root_motion_distance=\{report.stats.root_motion_distance}",
    "validation=\{validation_summary(report.validation)}",
  ]
  if report.validation.issues.length() > 0 {
    for issue in report.validation.issues {
      lines.push(
        "- \{issue.severity.to_string()} \{issue.code} \{issue.path}: \{issue.message}",
      )
    }
  }
  lines.join("\n")
}

///|
pub fn report_to_json(report : BvhReport) -> String {
  let result =
    $|{"ok":\{report.ok},"summary":\{json_string(report.summary)},"stats":\{stats_to_json(report.stats)},"validation":\{validation_to_json(report.validation)},"errorCode":\{json_string(report.error_code)}}
  result
}

///|
pub fn report_to_csv(report : BvhReport) -> String {
  [
    "metric,value",
    "ok,\{report.ok}",
    "joints,\{report.stats.joint_count}",
    "end_sites,\{report.stats.end_site_count}",
    "channels,\{report.stats.channel_count}",
    "frames,\{report.stats.frame_count}",
    "duration_seconds,\{report.stats.duration_seconds}",
    "root_motion_distance,\{report.stats.root_motion_distance}",
    "errors,\{report.validation.error_count}",
    "warnings,\{report.validation.warning_count}",
    "info,\{report.validation.info_count}",
  ].join("\n")
}

///|
pub fn format_report(
  report : BvhReport,
  format? : BvhReportFormat = ReportText,
) -> String {
  match format {
    ReportText => report_to_text(report)
    ReportJson => report_to_json(report)
    ReportCsv => report_to_csv(report)
  }
}

///|
pub fn bvh_fixture_report(format? : BvhReportFormat = ReportText) -> String {
  format_report(build_report(fixture_walk_bvh()), format~)
}
