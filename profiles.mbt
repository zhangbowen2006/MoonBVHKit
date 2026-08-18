///|
pub(all) enum BvhImportProfileKind {
  ProfileUnity
  ProfileBlender
  ProfileStrictCI
  ProfilePreview
} derive(Eq, @debug.Debug)

///|
pub fn BvhImportProfileKind::to_string(self : BvhImportProfileKind) -> String {
  match self {
    ProfileUnity => "unity"
    ProfileBlender => "blender"
    ProfileStrictCI => "strict-ci"
    ProfilePreview => "preview"
  }
}

///|
pub(all) struct BvhImportProfile {
  kind : BvhImportProfileKind
  name : String
  max_joint_count : Int
  max_depth : Int
  max_duration_seconds : Double
  min_frame_rate : Double
  max_frame_rate : Double
  max_root_speed : Double
  max_root_teleport : Double
  min_quality_score : Int
  require_root_position : Bool
  allow_unknown_channels : Bool
  allow_child_position_channels : Bool
  require_loop_closure : Bool
} derive(Eq, @debug.Debug)

///|
pub fn BvhImportProfile::new(
  kind : BvhImportProfileKind,
  name : String,
  max_joint_count? : Int = 0,
  max_depth? : Int = 0,
  max_duration_seconds? : Double = 0.0,
  min_frame_rate? : Double = 0.0,
  max_frame_rate? : Double = 0.0,
  max_root_speed? : Double = 0.0,
  max_root_teleport? : Double = 0.0,
  min_quality_score? : Int = 75,
  require_root_position? : Bool = true,
  allow_unknown_channels? : Bool = false,
  allow_child_position_channels? : Bool = false,
  require_loop_closure? : Bool = false,
) -> BvhImportProfile {
  {
    kind,
    name,
    max_joint_count,
    max_depth,
    max_duration_seconds,
    min_frame_rate,
    max_frame_rate,
    max_root_speed,
    max_root_teleport,
    min_quality_score,
    require_root_position,
    allow_unknown_channels,
    allow_child_position_channels,
    require_loop_closure,
  }
}

///|
pub fn unity_import_profile() -> BvhImportProfile {
  BvhImportProfile::new(
    ProfileUnity,
    "Unity humanoid/import gate",
    max_joint_count=256,
    max_depth=64,
    max_duration_seconds=180.0,
    min_frame_rate=24.0,
    max_frame_rate=120.0,
    max_root_speed=250.0,
    max_root_teleport=100.0,
    min_quality_score=75,
    require_root_position=true,
    allow_unknown_channels=false,
    allow_child_position_channels=false,
    require_loop_closure=false,
  )
}

///|
pub fn blender_import_profile() -> BvhImportProfile {
  BvhImportProfile::new(
    ProfileBlender,
    "Blender import gate",
    max_joint_count=512,
    max_depth=96,
    max_duration_seconds=600.0,
    min_frame_rate=12.0,
    max_frame_rate=240.0,
    max_root_speed=500.0,
    max_root_teleport=200.0,
    min_quality_score=75,
    require_root_position=false,
    allow_unknown_channels=false,
    allow_child_position_channels=true,
    require_loop_closure=false,
  )
}

///|
pub fn strict_ci_import_profile() -> BvhImportProfile {
  BvhImportProfile::new(
    ProfileStrictCI,
    "Strict CI asset gate",
    max_joint_count=128,
    max_depth=48,
    max_duration_seconds=120.0,
    min_frame_rate=24.0,
    max_frame_rate=120.0,
    max_root_speed=120.0,
    max_root_teleport=50.0,
    min_quality_score=90,
    require_root_position=true,
    allow_unknown_channels=false,
    allow_child_position_channels=false,
    require_loop_closure=false,
  )
}

///|
pub fn preview_import_profile() -> BvhImportProfile {
  BvhImportProfile::new(
    ProfilePreview,
    "Loose preview gate",
    max_joint_count=1024,
    max_depth=128,
    max_duration_seconds=1200.0,
    min_frame_rate=1.0,
    max_frame_rate=480.0,
    max_root_speed=0.0,
    max_root_teleport=0.0,
    min_quality_score=50,
    require_root_position=false,
    allow_unknown_channels=true,
    allow_child_position_channels=true,
    require_loop_closure=false,
  )
}

///|
pub fn default_import_profiles() -> Array[BvhImportProfile] {
  [
    unity_import_profile(),
    blender_import_profile(),
    strict_ci_import_profile(),
    preview_import_profile(),
  ]
}

///|
pub fn import_profile_by_name(name : String) -> BvhImportProfile {
  match name {
    "unity" | "Unity" => unity_import_profile()
    "blender" | "Blender" => blender_import_profile()
    "strict" | "strict-ci" | "ci" => strict_ci_import_profile()
    "preview" | "loose" => preview_import_profile()
    _ => preview_import_profile()
  }
}

///|
pub fn document_frame_rate(document : BvhDocument) -> Double {
  if document.motion.frame_time > 0.0 {
    1.0 / document.motion.frame_time
  } else {
    0.0
  }
}

///|
fn profile_limit_enabled_int(value : Int) -> Bool {
  value > 0
}

///|
fn profile_limit_enabled_double(value : Double) -> Bool {
  value > 0.0
}

///|
fn profile_limit_severity(profile : BvhImportProfile) -> BvhIssueSeverity {
  match profile.kind {
    ProfileStrictCI => IssueError
    _ => IssueWarning
  }
}

///|
fn profile_issue(
  profile : BvhImportProfile,
  code : String,
  message : String,
  path? : String = "$",
) -> BvhValidationIssue {
  BvhValidationIssue::new(profile_limit_severity(profile), code, message, path~)
}

///|
fn blocking_profile_issue(
  code : String,
  message : String,
  path? : String = "$",
) -> BvhValidationIssue {
  BvhValidationIssue::error(code, message, path~)
}

///|
fn contains_child_position_channels(joint : BvhJoint) -> Bool {
  for child in joint.children {
    if child.position_channel_count() > 0 {
      break true
    }
    if contains_child_position_channels(child) {
      break true
    }
  } nobreak {
    false
  }
}

///|
fn validation_issue_allowed_by_profile(
  issue : BvhValidationIssue,
  profile : BvhImportProfile,
) -> Bool {
  if issue.code == "unknown-channel" && profile.allow_unknown_channels {
    true
  } else if issue.code == "child-position-channels" &&
    profile.allow_child_position_channels {
    true
  } else {
    false
  }
}

///|
fn push_baseline_validation_issues(
  document : BvhDocument,
  profile : BvhImportProfile,
  issues : Array[BvhValidationIssue],
) -> Unit {
  let validation = validate_document(document)
  for issue in validation.issues {
    if issue.severity == IssueError &&
      !validation_issue_allowed_by_profile(issue, profile) {
      issues.push(issue)
    }
  }
}

///|
fn push_shape_profile_issues(
  document : BvhDocument,
  profile : BvhImportProfile,
  issues : Array[BvhValidationIssue],
) -> Unit {
  let stats = analyze_bvh(document)
  if profile.require_root_position &&
    document.root.position_channel_count() == 0 {
    issues.push(
      blocking_profile_issue(
        "profile-root-position-required",
        "profile requires root position channels",
        path=document.root.path,
      ),
    )
  }
  if !profile.allow_unknown_channels && contains_unknown_channels(document.root) {
    issues.push(
      blocking_profile_issue(
        "profile-unknown-channels", "profile does not allow unknown BVH channels",
      ),
    )
  }
  if !profile.allow_child_position_channels &&
    contains_child_position_channels(document.root) {
    issues.push(
      profile_issue(
        profile, "profile-child-position-channels", "profile prefers position channels only on the root joint",
      ),
    )
  }
  if profile_limit_enabled_int(profile.max_joint_count) &&
    stats.joint_count > profile.max_joint_count {
    issues.push(
      profile_issue(
        profile,
        "profile-too-many-joints",
        "joint count \{stats.joint_count} exceeds profile limit \{profile.max_joint_count}",
      ),
    )
  }
  if profile_limit_enabled_int(profile.max_depth) &&
    stats.max_depth > profile.max_depth {
    issues.push(
      profile_issue(
        profile,
        "profile-too-deep",
        "skeleton depth \{stats.max_depth} exceeds profile limit \{profile.max_depth}",
      ),
    )
  }
}

///|
fn push_motion_profile_issues(
  document : BvhDocument,
  profile : BvhImportProfile,
  issues : Array[BvhValidationIssue],
) -> Unit {
  let stats = analyze_bvh(document)
  let fps = document_frame_rate(document)
  if profile_limit_enabled_double(profile.max_duration_seconds) &&
    stats.duration_seconds > profile.max_duration_seconds {
    issues.push(
      profile_issue(
        profile,
        "profile-motion-too-long",
        "duration \{stats.duration_seconds}s exceeds profile limit \{profile.max_duration_seconds}s",
      ),
    )
  }
  if profile_limit_enabled_double(profile.min_frame_rate) &&
    fps < profile.min_frame_rate {
    issues.push(
      profile_issue(
        profile,
        "profile-frame-rate-low",
        "frame rate \{fps} is below profile minimum \{profile.min_frame_rate}",
      ),
    )
  }
  if profile_limit_enabled_double(profile.max_frame_rate) &&
    fps > profile.max_frame_rate {
    issues.push(
      profile_issue(
        profile,
        "profile-frame-rate-high",
        "frame rate \{fps} is above profile maximum \{profile.max_frame_rate}",
      ),
    )
  }
  if profile_limit_enabled_double(profile.max_root_speed) {
    let speed = max_root_speed(document)
    if speed > profile.max_root_speed {
      issues.push(
        profile_issue(
          profile,
          "profile-root-speed-high",
          "max root speed \{speed} exceeds profile limit \{profile.max_root_speed}",
        ),
      )
    }
  }
  if profile_limit_enabled_double(profile.max_root_teleport) {
    let teleports = detect_root_teleports(document, profile.max_root_teleport)
    if teleports.length() > 0 {
      issues.push(
        profile_issue(
          profile,
          "profile-root-teleport",
          "root motion has \{teleports.length()} large translation jump(s)",
        ),
      )
    }
  }
  if profile.require_loop_closure {
    let closure = loop_closure_error(document)
    if closure > 0.001 {
      issues.push(
        blocking_profile_issue(
          "profile-loop-not-closed",
          "loop closure error \{closure} exceeds 0.001",
        ),
      )
    }
  }
}

///|
fn push_quality_profile_issues(
  quality : BvhQualityReport,
  profile : BvhImportProfile,
  issues : Array[BvhValidationIssue],
) -> Unit {
  if quality.score < profile.min_quality_score {
    issues.push(
      blocking_profile_issue(
        "profile-quality-score-low",
        "quality score \{quality.score} is below profile minimum \{profile.min_quality_score}",
      ),
    )
  }
}

///|
pub fn import_profile_issues(
  document : BvhDocument,
  profile : BvhImportProfile,
) -> Array[BvhValidationIssue] {
  let issues : Array[BvhValidationIssue] = []
  push_baseline_validation_issues(document, profile, issues)
  push_shape_profile_issues(document, profile, issues)
  push_motion_profile_issues(document, profile, issues)
  push_quality_profile_issues(quality_report(document), profile, issues)
  issues
}

///|
fn count_issues_with_severity(
  issues : Array[BvhValidationIssue],
  severity : BvhIssueSeverity,
) -> Int {
  for issue in issues; count = 0 {
    if issue.severity == severity {
      continue count + 1
    } else {
      continue count
    }
  } nobreak {
    count
  }
}

///|
pub(all) struct BvhImportDecision {
  profile_name : String
  accepted : Bool
  action : String
  quality : BvhQualityReport
  issues : Array[BvhValidationIssue]
} derive(Eq, @debug.Debug)

///|
pub fn BvhImportDecision::error_count(self : BvhImportDecision) -> Int {
  count_issues_with_severity(self.issues, IssueError)
}

///|
pub fn BvhImportDecision::warning_count(self : BvhImportDecision) -> Int {
  count_issues_with_severity(self.issues, IssueWarning)
}

///|
pub fn BvhImportDecision::issue_count(self : BvhImportDecision) -> Int {
  self.issues.length()
}

///|
pub fn BvhImportDecision::ok(self : BvhImportDecision) -> Bool {
  self.accepted
}

///|
fn import_action(
  accepted : Bool,
  errors : Int,
  warnings : Int,
  quality : BvhQualityReport,
) -> String {
  if accepted {
    if warnings > 0 || quality.grade == QualityUsable {
      "accept-with-notes"
    } else {
      "accept"
    }
  } else if errors > 0 || quality.grade == QualityBlocked {
    "block"
  } else {
    "review"
  }
}

///|
pub fn evaluate_import_profile(
  document : BvhDocument,
  profile : BvhImportProfile,
) -> BvhImportDecision {
  let quality = quality_report(document)
  let issues = import_profile_issues(document, profile)
  let errors = count_issues_with_severity(issues, IssueError)
  let warnings = count_issues_with_severity(issues, IssueWarning)
  let accepted = errors == 0 &&
    quality.score >= profile.min_quality_score &&
    quality.ok_for_import()
  {
    profile_name: profile.name,
    accepted,
    action: import_action(accepted, errors, warnings, quality),
    quality,
    issues,
  }
}

///|
pub fn evaluate_bvh_import_profile(
  input : String,
  profile : BvhImportProfile,
) -> BvhImportDecision {
  let parsed = parse_bvh(input)
  if parsed.ok {
    evaluate_import_profile(parsed.document, profile)
  } else {
    let quality = quality_report_from_bvh(input)
    let issues = [
      BvhValidationIssue::error(
        parsed.error.code(),
        parsed.error.message,
        path="\{parsed.error.line}:\{parsed.error.column}",
      ),
    ]
    {
      profile_name: profile.name,
      accepted: false,
      action: "block",
      quality,
      issues,
    }
  }
}

///|
pub fn evaluate_default_import_profiles(
  document : BvhDocument,
) -> Array[BvhImportDecision] {
  let out : Array[BvhImportDecision] = []
  for profile in default_import_profiles() {
    out.push(evaluate_import_profile(document, profile))
  }
  out
}

///|
pub(all) struct BvhNamedAsset {
  name : String
  source : String
} derive(Eq, @debug.Debug)

///|
pub fn BvhNamedAsset::new(name : String, source : String) -> BvhNamedAsset {
  { name, source }
}

///|
pub(all) struct BvhBatchAssetDecision {
  asset_name : String
  decision : BvhImportDecision
} derive(Eq, @debug.Debug)

///|
pub(all) struct BvhBatchImportReport {
  profile_name : String
  asset_count : Int
  accepted_count : Int
  blocked_count : Int
  assets : Array[BvhBatchAssetDecision]
} derive(Eq, @debug.Debug)

///|
pub fn BvhBatchImportReport::all_accepted(self : BvhBatchImportReport) -> Bool {
  self.blocked_count == 0
}

///|
pub fn evaluate_bvh_batch(
  assets : Array[BvhNamedAsset],
  profile : BvhImportProfile,
) -> BvhBatchImportReport {
  let decisions : Array[BvhBatchAssetDecision] = []
  let mut accepted_count = 0
  let mut blocked_count = 0
  for asset in assets {
    let decision = evaluate_bvh_import_profile(asset.source, profile)
    if decision.accepted {
      accepted_count += 1
    } else {
      blocked_count += 1
    }
    decisions.push({ asset_name: asset.name, decision })
  }
  {
    profile_name: profile.name,
    asset_count: decisions.length(),
    accepted_count,
    blocked_count,
    assets: decisions,
  }
}

///|
pub fn batch_import_report_to_json(report : BvhBatchImportReport) -> String {
  let assets : Array[String] = []
  for asset in report.assets {
    assets.push(
      (
        $|{"asset":\{json_string(asset.asset_name)},"decision":\{import_decision_to_json(asset.decision)}},
      ),
    )
  }
  (
    $|{"profile":\{json_string(report.profile_name)},"assetCount":\{report.asset_count},"acceptedCount":\{report.accepted_count},"blockedCount":\{report.blocked_count},"allAccepted":\{report.all_accepted()},"assets":[\{assets.join(",")}]}
  )
}

///|
pub fn batch_import_report_to_csv(report : BvhBatchImportReport) -> String {
  let rows : Array[String] = [
    "asset,profile,accepted,action,quality,score,errors,warnings,issues",
  ]
  for asset in report.assets {
    let decision = asset.decision
    let safe_name = asset.asset_name.replace_all(old=",", new=" ")
    rows.push(
      "\{safe_name},\{decision.profile_name},\{decision.accepted},\{decision.action},\{decision.quality.grade.to_string()},\{decision.quality.score},\{decision.error_count()},\{decision.warning_count()},\{decision.issue_count()}",
    )
  }
  rows.join("\n")
}

///|
pub fn import_profile_to_json(profile : BvhImportProfile) -> String {
  let result =
    $|{"kind":\{json_string(profile.kind.to_string())},"name":\{json_string(profile.name)},"maxJointCount":\{profile.max_joint_count},"maxDepth":\{profile.max_depth},"maxDurationSeconds":\{profile.max_duration_seconds},"minFrameRate":\{profile.min_frame_rate},"maxFrameRate":\{profile.max_frame_rate},"maxRootSpeed":\{profile.max_root_speed},"maxRootTeleport":\{profile.max_root_teleport},"minQualityScore":\{profile.min_quality_score},"requireRootPosition":\{profile.require_root_position},"allowUnknownChannels":\{profile.allow_unknown_channels},"allowChildPositionChannels":\{profile.allow_child_position_channels},"requireLoopClosure":\{profile.require_loop_closure}}
  result
}

///|
fn profile_issue_to_json(issue : BvhValidationIssue) -> String {
  let result =
    $|{"severity":\{json_string(issue.severity.to_string())},"path":\{json_string(issue.path)},"code":\{json_string(issue.code)},"message":\{json_string(issue.message)}}
  result
}

///|
pub fn import_decision_to_json(decision : BvhImportDecision) -> String {
  let issues : Array[String] = []
  for issue in decision.issues {
    issues.push(profile_issue_to_json(issue))
  }
  let result =
    $|{"profile":\{json_string(decision.profile_name)},"accepted":\{decision.accepted},"action":\{json_string(decision.action)},"quality":\{quality_report_to_json(decision.quality)},"issueCount":\{decision.issue_count()},"errors":\{decision.error_count()},"warnings":\{decision.warning_count()},"issues":[\{issues.join(",")}]}
  result
}

///|
pub fn import_decision_to_text(decision : BvhImportDecision) -> String {
  let lines : Array[String] = [
    "profile=\{decision.profile_name}",
    "accepted=\{decision.accepted}",
    "action=\{decision.action}",
    "quality=\{decision.quality.grade.to_string()}",
    "score=\{decision.quality.score}",
  ]
  for issue in decision.issues {
    lines.push(
      "- \{issue.severity.to_string()} \{issue.code}: \{issue.message}",
    )
  }
  lines.join("\n")
}

///|
pub fn import_decisions_to_csv(decisions : Array[BvhImportDecision]) -> String {
  let rows : Array[String] = [
    "profile,accepted,action,quality,score,errors,warnings,issues",
  ]
  for decision in decisions {
    rows.push(
      "\{decision.profile_name},\{decision.accepted},\{decision.action},\{decision.quality.grade.to_string()},\{decision.quality.score},\{decision.error_count()},\{decision.warning_count()},\{decision.issue_count()}",
    )
  }
  rows.join("\n")
}

///|
pub fn import_profiles_to_csv(profiles : Array[BvhImportProfile]) -> String {
  let rows : Array[String] = [
    "kind,name,max_joint_count,max_depth,max_duration_seconds,min_frame_rate,max_frame_rate,max_root_speed,max_root_teleport,min_quality_score,require_root_position,allow_unknown_channels,allow_child_position_channels,require_loop_closure",
  ]
  for profile in profiles {
    rows.push(
      "\{profile.kind.to_string()},\{profile.name},\{profile.max_joint_count},\{profile.max_depth},\{profile.max_duration_seconds},\{profile.min_frame_rate},\{profile.max_frame_rate},\{profile.max_root_speed},\{profile.max_root_teleport},\{profile.min_quality_score},\{profile.require_root_position},\{profile.allow_unknown_channels},\{profile.allow_child_position_channels},\{profile.require_loop_closure}",
    )
  }
  rows.join("\n")
}
