///|
fn validate_joint_shape(
  joint : BvhJoint,
  issues : Array[BvhValidationIssue],
) -> Unit {
  if joint.name.length() == 0 {
    issues.push(
      BvhValidationIssue::error(
        "joint-name-empty",
        "joint name is empty",
        path=joint.path,
      ),
    )
  }
  if joint.channel_count != joint.channels.length() {
    issues.push(
      BvhValidationIssue::error(
        "channel-count-mismatch",
        "joint channel_count does not match channel array length",
        path=joint.path,
      ),
    )
  }
  if joint.is_root() && joint.position_channel_count() == 0 {
    issues.push(
      BvhValidationIssue::warning(
        "root-without-position",
        "root joint has no position channels; root motion will be zero",
        path=joint.path,
      ),
    )
  }
  if !joint.is_root() && joint.position_channel_count() > 0 {
    issues.push(
      BvhValidationIssue::warning(
        "child-position-channels",
        "non-root joint has position channels, which many game importers do not expect",
        path=joint.path,
      ),
    )
  }
  if joint.rotation_channel_count() == 0 && joint.children.length() > 0 {
    issues.push(
      BvhValidationIssue::warning(
        "joint-without-rotation",
        "joint has children but no rotation channels",
        path=joint.path,
      ),
    )
  }
  for channel in joint.channels {
    if !channel.is_known() {
      issues.push(
        BvhValidationIssue::error(
          "unknown-channel",
          "unsupported channel '\{channel.to_string()}'",
          path=joint.path,
        ),
      )
    }
  }
  for child in joint.children {
    validate_joint_shape(child, issues)
  }
}

///|
fn validate_channel_offsets(
  joint : BvhJoint,
  expected : Int,
  issues : Array[BvhValidationIssue],
) -> Int {
  if joint.channel_start != expected {
    issues.push(
      BvhValidationIssue::error(
        "channel-start-gap",
        "joint channel_start \{joint.channel_start} does not match expected \{expected}",
        path=joint.path,
      ),
    )
  }
  let mut next = expected + joint.channel_count
  for child in joint.children {
    next = validate_channel_offsets(child, next, issues)
  }
  next
}

///|
fn validate_motion(
  document : BvhDocument,
  issues : Array[BvhValidationIssue],
) -> Unit {
  if document.motion.frame_count <= 0 {
    issues.push(
      BvhValidationIssue::error(
        "no-frames",
        "BVH motion must declare at least one frame",
        path="$.motion.frames",
      ),
    )
  }
  if document.motion.frame_time <= 0.0 {
    issues.push(
      BvhValidationIssue::error(
        "invalid-frame-time",
        "Frame Time must be greater than zero",
        path="$.motion.frame_time",
      ),
    )
  }
  if document.motion.frame_count != document.motion.frames.length() {
    issues.push(
      BvhValidationIssue::error(
        "frame-count-mismatch",
        "declared frame count does not match parsed frame array length",
        path="$.motion.frames",
      ),
    )
  }
  for i in 0..<document.motion.frames.length() {
    if document.motion.frames[i].length() != document.motion.channel_count {
      issues.push(
        BvhValidationIssue::error(
          "frame-width-mismatch",
          "frame \{i} has \{document.motion.frames[i].length()} values, expected \{document.motion.channel_count}",
          path="$.motion.frames[\{i}]",
        ),
      )
    }
  }
}

///|
fn validate_stats(
  document : BvhDocument,
  issues : Array[BvhValidationIssue],
) -> Unit {
  let stats = analyze_bvh(document)
  if stats.joint_count == 1 {
    issues.push(
      BvhValidationIssue::warning(
        "single-joint-skeleton", "skeleton has only one joint; check whether children were exported",
      ),
    )
  }
  if stats.max_depth > 64 {
    issues.push(
      BvhValidationIssue::warning(
        "very-deep-skeleton", "skeleton depth is unusually high and may be difficult to import",
      ),
    )
  }
  if stats.duration_seconds > 600.0 {
    issues.push(
      BvhValidationIssue::warning(
        "long-motion", "motion is longer than ten minutes; consider splitting clips",
      ),
    )
  }
  if stats.root_motion_distance == 0.0 {
    issues.push(
      BvhValidationIssue::info(
        "static-root", "root position channels do not move across frames",
      ),
    )
  }
}

///|
pub fn validate_document(document : BvhDocument) -> BvhValidationReport {
  let issues : Array[BvhValidationIssue] = []
  if document.root.name.length() == 0 {
    issues.push(
      BvhValidationIssue::error("missing-root", "missing ROOT hierarchy"),
    )
  } else {
    validate_joint_shape(document.root, issues)
    let next = validate_channel_offsets(document.root, 0, issues)
    if next != document.motion.channel_count {
      issues.push(
        BvhValidationIssue::error(
          "motion-channel-total",
          "hierarchy declares \{next} channels, motion expects \{document.motion.channel_count}",
          path="$.motion.channel_count",
        ),
      )
    }
  }
  validate_motion(document, issues)
  validate_stats(document, issues)
  BvhValidationReport::new(issues)
}

///|
pub fn validate_bvh(input : String) -> BvhValidationReport {
  let parsed = parse_bvh(input)
  if !parsed.ok {
    BvhValidationReport::new([
      BvhValidationIssue::error(
        parsed.error.code(),
        parsed.error.message,
        path="\{parsed.error.line}:\{parsed.error.column}",
      ),
    ])
  } else {
    validate_document(parsed.document)
  }
}

///|
pub fn validation_summary(report : BvhValidationReport) -> String {
  if report.ok() {
    "ok: \{report.warning_count} warning(s), \{report.info_count} info"
  } else {
    "failed: \{report.error_count} error(s), \{report.warning_count} warning(s)"
  }
}
