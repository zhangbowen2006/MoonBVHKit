///|
/// Error categories returned by the tokenizer, parser, validator, and report API.
pub(all) enum BvhErrorKind {
  ErrorNone
  ErrorEmptyInput
  ErrorUnexpectedToken
  ErrorUnexpectedEof
  ErrorInvalidNumber
  ErrorInvalidHierarchy
  ErrorInvalidMotion
  ErrorFrameWidthMismatch
  ErrorUnsupportedFeature
} derive(Eq, @debug.Debug)

///|
pub fn BvhErrorKind::code(self : BvhErrorKind) -> String {
  match self {
    ErrorNone => "none"
    ErrorEmptyInput => "empty-input"
    ErrorUnexpectedToken => "unexpected-token"
    ErrorUnexpectedEof => "unexpected-eof"
    ErrorInvalidNumber => "invalid-number"
    ErrorInvalidHierarchy => "invalid-hierarchy"
    ErrorInvalidMotion => "invalid-motion"
    ErrorFrameWidthMismatch => "frame-width-mismatch"
    ErrorUnsupportedFeature => "unsupported-feature"
  }
}

///|
pub(all) struct BvhError {
  kind : BvhErrorKind
  line : Int
  column : Int
  token : String
  message : String
} derive(Eq, @debug.Debug)

///|
pub fn BvhError::none() -> BvhError {
  { kind: ErrorNone, line: 0, column: 0, token: "", message: "" }
}

///|
pub fn BvhError::new(
  kind : BvhErrorKind,
  message : String,
  line? : Int = 0,
  column? : Int = 0,
  token? : String = "",
) -> BvhError {
  { kind, line, column, token, message }
}

///|
pub fn BvhError::is_error(self : BvhError) -> Bool {
  self.kind != ErrorNone
}

///|
pub fn BvhError::code(self : BvhError) -> String {
  self.kind.code()
}

///|
pub(all) enum BvhTokenKind {
  TokenWord
  TokenOpenBrace
  TokenCloseBrace
} derive(Eq, @debug.Debug)

///|
pub(all) struct BvhToken {
  kind : BvhTokenKind
  text : String
  line : Int
  column : Int
} derive(Eq, @debug.Debug)

///|
pub fn BvhToken::new(
  kind : BvhTokenKind,
  text : String,
  line : Int,
  column : Int,
) -> BvhToken {
  { kind, text, line, column }
}

///|
pub fn BvhToken::is_text(self : BvhToken, text : String) -> Bool {
  self.text == text
}

///|
pub(all) struct BvhTokenizeResult {
  ok : Bool
  tokens : Array[BvhToken]
  error : BvhError
} derive(Eq, @debug.Debug)

///|
pub fn BvhTokenizeResult::success(
  tokens : Array[BvhToken],
) -> BvhTokenizeResult {
  { ok: true, tokens, error: BvhError::none() }
}

///|
pub fn BvhTokenizeResult::failure(error : BvhError) -> BvhTokenizeResult {
  { ok: false, tokens: [], error }
}

///|
pub(all) enum BvhChannel {
  ChannelXPosition
  ChannelYPosition
  ChannelZPosition
  ChannelXRotation
  ChannelYRotation
  ChannelZRotation
  ChannelUnknown(String)
} derive(Eq, @debug.Debug)

///|
pub fn BvhChannel::from_string(name : String) -> BvhChannel {
  match name {
    "Xposition" | "XPOSITION" | "XPosition" => ChannelXPosition
    "Yposition" | "YPOSITION" | "YPosition" => ChannelYPosition
    "Zposition" | "ZPOSITION" | "ZPosition" => ChannelZPosition
    "Xrotation" | "XROTATION" | "XRotation" => ChannelXRotation
    "Yrotation" | "YROTATION" | "YRotation" => ChannelYRotation
    "Zrotation" | "ZROTATION" | "ZRotation" => ChannelZRotation
    _ => ChannelUnknown(name)
  }
}

///|
pub fn BvhChannel::to_string(self : BvhChannel) -> String {
  match self {
    ChannelXPosition => "Xposition"
    ChannelYPosition => "Yposition"
    ChannelZPosition => "Zposition"
    ChannelXRotation => "Xrotation"
    ChannelYRotation => "Yrotation"
    ChannelZRotation => "Zrotation"
    ChannelUnknown(name) => name
  }
}

///|
pub fn BvhChannel::axis(self : BvhChannel) -> String {
  match self {
    ChannelXPosition | ChannelXRotation => "x"
    ChannelYPosition | ChannelYRotation => "y"
    ChannelZPosition | ChannelZRotation => "z"
    ChannelUnknown(_) => "unknown"
  }
}

///|
pub fn BvhChannel::is_position(self : BvhChannel) -> Bool {
  match self {
    ChannelXPosition | ChannelYPosition | ChannelZPosition => true
    _ => false
  }
}

///|
pub fn BvhChannel::is_rotation(self : BvhChannel) -> Bool {
  match self {
    ChannelXRotation | ChannelYRotation | ChannelZRotation => true
    _ => false
  }
}

///|
pub fn BvhChannel::is_known(self : BvhChannel) -> Bool {
  match self {
    ChannelUnknown(_) => false
    _ => true
  }
}

///|
pub(all) enum BvhJointKind {
  JointRoot
  JointRegular
} derive(Eq, @debug.Debug)

///|
pub fn BvhJointKind::to_string(self : BvhJointKind) -> String {
  match self {
    JointRoot => "ROOT"
    JointRegular => "JOINT"
  }
}

///|
pub(all) struct BvhVec3 {
  x : Double
  y : Double
  z : Double
} derive(Eq, @debug.Debug)

///|
pub fn BvhVec3::new(x : Double, y : Double, z : Double) -> BvhVec3 {
  { x, y, z }
}

///|
pub fn BvhVec3::zero() -> BvhVec3 {
  { x: 0.0, y: 0.0, z: 0.0 }
}

///|
pub fn BvhVec3::add(self : BvhVec3, other : BvhVec3) -> BvhVec3 {
  { x: self.x + other.x, y: self.y + other.y, z: self.z + other.z }
}

///|
pub fn BvhVec3::sub(self : BvhVec3, other : BvhVec3) -> BvhVec3 {
  { x: self.x - other.x, y: self.y - other.y, z: self.z - other.z }
}

///|
pub fn BvhVec3::scale(self : BvhVec3, factor : Double) -> BvhVec3 {
  { x: self.x * factor, y: self.y * factor, z: self.z * factor }
}

///|
pub fn BvhVec3::magnitude(self : BvhVec3) -> Double {
  (self.x * self.x + self.y * self.y + self.z * self.z).sqrt()
}

///|
pub fn BvhVec3::to_csv(self : BvhVec3) -> String {
  "\{self.x},\{self.y},\{self.z}"
}

///|
pub(all) struct BvhEndSite {
  path : String
  offset : BvhVec3
  depth : Int
} derive(Eq, @debug.Debug)

///|
pub fn BvhEndSite::new(
  path : String,
  offset : BvhVec3,
  depth : Int,
) -> BvhEndSite {
  { path, offset, depth }
}

///|
pub fn BvhEndSite::empty() -> BvhEndSite {
  { path: "", offset: BvhVec3::zero(), depth: 0 }
}

///|
pub(all) struct BvhJoint {
  name : String
  path : String
  kind : BvhJointKind
  offset : BvhVec3
  channels : Array[BvhChannel]
  channel_start : Int
  channel_count : Int
  depth : Int
  children : Array[BvhJoint]
  end_sites : Array[BvhEndSite]
} derive(Eq, @debug.Debug)

///|
pub fn BvhJoint::empty() -> BvhJoint {
  {
    name: "",
    path: "",
    kind: JointRegular,
    offset: BvhVec3::zero(),
    channels: [],
    channel_start: 0,
    channel_count: 0,
    depth: 0,
    children: [],
    end_sites: [],
  }
}

///|
pub fn BvhJoint::is_root(self : BvhJoint) -> Bool {
  self.kind == JointRoot
}

///|
pub fn BvhJoint::has_channel(self : BvhJoint, channel : BvhChannel) -> Bool {
  for item in self.channels {
    if item == channel {
      break true
    }
  } nobreak {
    false
  }
}

///|
pub fn BvhJoint::position_channel_count(self : BvhJoint) -> Int {
  for channel in self.channels; count = 0 {
    if channel.is_position() {
      continue count + 1
    } else {
      continue count
    }
  } nobreak {
    count
  }
}

///|
pub fn BvhJoint::rotation_channel_count(self : BvhJoint) -> Int {
  for channel in self.channels; count = 0 {
    if channel.is_rotation() {
      continue count + 1
    } else {
      continue count
    }
  } nobreak {
    count
  }
}

///|
pub(all) struct BvhMotion {
  frame_count : Int
  frame_time : Double
  channel_count : Int
  frames : Array[Array[Double]]
} derive(Eq, @debug.Debug)

///|
pub fn BvhMotion::empty() -> BvhMotion {
  { frame_count: 0, frame_time: 0.0, channel_count: 0, frames: [] }
}

///|
pub fn BvhMotion::duration_seconds(self : BvhMotion) -> Double {
  self.frame_count.to_double() * self.frame_time
}

///|
pub fn BvhMotion::is_empty(self : BvhMotion) -> Bool {
  self.frame_count == 0 || self.frames.length() == 0
}

///|
pub(all) struct BvhDocument {
  root : BvhJoint
  motion : BvhMotion
  source_length : Int
  token_count : Int
} derive(Eq, @debug.Debug)

///|
pub fn BvhDocument::empty() -> BvhDocument {
  {
    root: BvhJoint::empty(),
    motion: BvhMotion::empty(),
    source_length: 0,
    token_count: 0,
  }
}

///|
pub fn BvhDocument::channel_count(self : BvhDocument) -> Int {
  self.motion.channel_count
}

///|
pub fn BvhDocument::joint_count(self : BvhDocument) -> Int {
  count_joints(self.root)
}

///|
pub fn BvhDocument::end_site_count(self : BvhDocument) -> Int {
  count_end_sites(self.root)
}

///|
pub fn BvhDocument::duration_seconds(self : BvhDocument) -> Double {
  self.motion.duration_seconds()
}

///|
pub fn BvhDocument::is_complete(self : BvhDocument) -> Bool {
  self.root.name.length() > 0 &&
  self.motion.frame_count == self.motion.frames.length() &&
  self.motion.channel_count > 0
}

///|
pub(all) struct BvhParseResult {
  ok : Bool
  document : BvhDocument
  error : BvhError
} derive(Eq, @debug.Debug)

///|
pub fn BvhParseResult::success(document : BvhDocument) -> BvhParseResult {
  { ok: true, document, error: BvhError::none() }
}

///|
pub fn BvhParseResult::failure(error : BvhError) -> BvhParseResult {
  { ok: false, document: BvhDocument::empty(), error }
}

///|
pub fn BvhParseResult::is_ok(self : BvhParseResult) -> Bool {
  self.ok
}

///|
pub(all) enum BvhIssueSeverity {
  IssueError
  IssueWarning
  IssueInfo
} derive(Eq, @debug.Debug)

///|
pub fn BvhIssueSeverity::to_string(self : BvhIssueSeverity) -> String {
  match self {
    IssueError => "error"
    IssueWarning => "warning"
    IssueInfo => "info"
  }
}

///|
pub(all) struct BvhValidationIssue {
  severity : BvhIssueSeverity
  path : String
  code : String
  message : String
} derive(Eq, @debug.Debug)

///|
pub fn BvhValidationIssue::new(
  severity : BvhIssueSeverity,
  code : String,
  message : String,
  path? : String = "$",
) -> BvhValidationIssue {
  { severity, path, code, message }
}

///|
pub fn BvhValidationIssue::error(
  code : String,
  message : String,
  path? : String = "$",
) -> BvhValidationIssue {
  BvhValidationIssue::new(IssueError, code, message, path~)
}

///|
pub fn BvhValidationIssue::warning(
  code : String,
  message : String,
  path? : String = "$",
) -> BvhValidationIssue {
  BvhValidationIssue::new(IssueWarning, code, message, path~)
}

///|
pub fn BvhValidationIssue::info(
  code : String,
  message : String,
  path? : String = "$",
) -> BvhValidationIssue {
  BvhValidationIssue::new(IssueInfo, code, message, path~)
}

///|
pub(all) struct BvhValidationReport {
  issues : Array[BvhValidationIssue]
  error_count : Int
  warning_count : Int
  info_count : Int
} derive(Eq, @debug.Debug)

///|
pub fn BvhValidationReport::new(
  issues : Array[BvhValidationIssue],
) -> BvhValidationReport {
  let mut errors = 0
  let mut warnings = 0
  let mut infos = 0
  for issue in issues {
    match issue.severity {
      IssueError => errors += 1
      IssueWarning => warnings += 1
      IssueInfo => infos += 1
    }
  }
  { issues, error_count: errors, warning_count: warnings, info_count: infos }
}

///|
pub fn BvhValidationReport::ok(self : BvhValidationReport) -> Bool {
  self.error_count == 0
}

///|
pub(all) struct BvhStats {
  joint_count : Int
  end_site_count : Int
  max_depth : Int
  channel_count : Int
  frame_count : Int
  frame_time : Double
  duration_seconds : Double
  root_motion_distance : Double
} derive(Eq, @debug.Debug)

///|
pub fn BvhStats::empty() -> BvhStats {
  {
    joint_count: 0,
    end_site_count: 0,
    max_depth: 0,
    channel_count: 0,
    frame_count: 0,
    frame_time: 0.0,
    duration_seconds: 0.0,
    root_motion_distance: 0.0,
  }
}

///|
pub(all) enum BvhReportFormat {
  ReportText
  ReportJson
  ReportCsv
} derive(Eq, @debug.Debug)
