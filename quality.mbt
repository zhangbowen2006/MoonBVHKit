///|
pub(all) enum BvhQualityGrade {
  QualityExcellent
  QualityUsable
  QualityNeedsReview
  QualityBlocked
} derive(Eq, @debug.Debug)

///|
pub fn BvhQualityGrade::to_string(self : BvhQualityGrade) -> String {
  match self {
    QualityExcellent => "excellent"
    QualityUsable => "usable"
    QualityNeedsReview => "needs-review"
    QualityBlocked => "blocked"
  }
}

///|
pub fn BvhQualityGrade::recommended_action(self : BvhQualityGrade) -> String {
  match self {
    QualityExcellent => "accept"
    QualityUsable => "accept-with-notes"
    QualityNeedsReview => "inspect-before-import"
    QualityBlocked => "fix-before-import"
  }
}

///|
pub(all) struct BvhQualitySignal {
  severity : BvhIssueSeverity
  code : String
  score_delta : Int
  message : String
} derive(Eq, @debug.Debug)

///|
pub fn BvhQualitySignal::new(
  severity : BvhIssueSeverity,
  code : String,
  score_delta : Int,
  message : String,
) -> BvhQualitySignal {
  { severity, code, score_delta, message }
}

///|
fn quality_signal_from_issue(issue : BvhValidationIssue) -> BvhQualitySignal {
  let delta = match issue.severity {
    IssueError => -40
    IssueWarning => -10
    IssueInfo => 0
  }
  BvhQualitySignal::new(issue.severity, issue.code, delta, issue.message)
}

///|
pub(all) struct BvhQualityReport {
  grade : BvhQualityGrade
  score : Int
  signals : Array[BvhQualitySignal]
  recommended_action : String
} derive(Eq, @debug.Debug)

///|
pub fn BvhQualityReport::new(
  score : Int,
  signals : Array[BvhQualitySignal],
) -> BvhQualityReport {
  let grade = if score >= 90 {
    QualityExcellent
  } else if score >= 75 {
    QualityUsable
  } else if score >= 50 {
    QualityNeedsReview
  } else {
    QualityBlocked
  }
  { grade, score, signals, recommended_action: grade.recommended_action() }
}

///|
pub fn BvhQualityReport::ok_for_import(self : BvhQualityReport) -> Bool {
  self.grade == QualityExcellent || self.grade == QualityUsable
}

///|
fn clamp_quality_score(score : Int) -> Int {
  if score < 0 {
    0
  } else if score > 100 {
    100
  } else {
    score
  }
}

///|
fn push_motion_quality_signals(
  document : BvhDocument,
  signals : Array[BvhQualitySignal],
) -> Unit {
  if document.motion.frame_count < 2 {
    signals.push(
      BvhQualitySignal::new(
        IssueWarning,
        "very-short-motion",
        -8,
        "motion has fewer than two frames",
      ),
    )
  }
  if document.motion.frame_time > 0.1 {
    signals.push(
      BvhQualitySignal::new(
        IssueWarning,
        "low-frame-rate",
        -5,
        "frame time is above 0.1s; importer preview may look choppy",
      ),
    )
  }
  if detect_root_teleports(document, 100.0).length() > 0 {
    signals.push(
      BvhQualitySignal::new(
        IssueWarning,
        "root-teleport",
        -12,
        "root motion contains a large per-frame translation jump",
      ),
    )
  }
  if loop_closure_error(document) < 0.001 &&
    root_motion_distance(document) > 0.0 {
    signals.push(
      BvhQualitySignal::new(
        IssueInfo,
        "loop-closes",
        2,
        "first and last root positions are close",
      ),
    )
  }
}

///|
fn quality_score_from_signals(signals : Array[BvhQualitySignal]) -> Int {
  let raw = for signal in signals; score = 100 {
    continue score + signal.score_delta
  } nobreak {
    score
  }
  clamp_quality_score(raw)
}

///|
pub fn quality_report(document : BvhDocument) -> BvhQualityReport {
  let validation = validate_document(document)
  let signals : Array[BvhQualitySignal] = []
  for issue in validation.issues {
    signals.push(quality_signal_from_issue(issue))
  }
  push_motion_quality_signals(document, signals)
  BvhQualityReport::new(quality_score_from_signals(signals), signals)
}

///|
pub fn quality_report_from_bvh(input : String) -> BvhQualityReport {
  let parsed = parse_bvh(input)
  if !parsed.ok {
    BvhQualityReport::new(0, [
      BvhQualitySignal::new(
        IssueError,
        parsed.error.code(),
        -100,
        parsed.error.message,
      ),
    ])
  } else {
    quality_report(parsed.document)
  }
}

///|
pub fn quality_report_to_text(report : BvhQualityReport) -> String {
  let lines : Array[String] = [
    "quality=\{report.grade.to_string()}",
    "score=\{report.score}",
    "action=\{report.recommended_action}",
  ]
  for signal in report.signals {
    lines.push(
      "- \{signal.severity.to_string()} \{signal.code} \{signal.score_delta}: \{signal.message}",
    )
  }
  lines.join("\n")
}

///|
pub fn quality_signal_to_json(signal : BvhQualitySignal) -> String {
  let result =
    $|{"severity":\{json_string(signal.severity.to_string())},"code":\{json_string(signal.code)},"scoreDelta":\{signal.score_delta},"message":\{json_string(signal.message)}}
  result
}

///|
pub fn quality_report_to_json(report : BvhQualityReport) -> String {
  let signals : Array[String] = []
  for signal in report.signals {
    signals.push(quality_signal_to_json(signal))
  }
  let result =
    $|{"grade":\{json_string(report.grade.to_string())},"score":\{report.score},"okForImport":\{report.ok_for_import()},"recommendedAction":\{json_string(report.recommended_action)},"signals":[\{signals.join(",")}]}
  result
}

///|
pub fn quality_report_to_csv(report : BvhQualityReport) -> String {
  let rows : Array[String] = [
    "grade,score,ok_for_import,recommended_action,severity,code,score_delta,message",
  ]
  if report.signals.length() == 0 {
    rows.push(
      "\{report.grade.to_string()},\{report.score},\{report.ok_for_import()},\{report.recommended_action},,,,",
    )
  } else {
    for signal in report.signals {
      rows.push(
        "\{report.grade.to_string()},\{report.score},\{report.ok_for_import()},\{report.recommended_action},\{signal.severity.to_string()},\{signal.code},\{signal.score_delta},\{signal.message}",
      )
    }
  }
  rows.join("\n")
}

///|
pub fn quality_action_for_bvh(input : String) -> String {
  quality_report_from_bvh(input).recommended_action
}
