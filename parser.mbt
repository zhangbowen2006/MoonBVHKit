///|
priv struct BvhParser {
  tokens : Array[BvhToken]
  mut index : Int
  mut channel_cursor : Int
  mut error : BvhError
}

///|
fn BvhParser::new(tokens : Array[BvhToken]) -> BvhParser {
  { tokens, index: 0, channel_cursor: 0, error: BvhError::none(), }
}

///|
fn BvhParser::is_eof(self : BvhParser) -> Bool {
  self.index >= self.tokens.length()
}

///|
fn BvhParser::current(self : BvhParser) -> BvhToken? {
  self.tokens.get(self.index)
}

///|
fn BvhParser::peek_text(self : BvhParser) -> String {
  match self.current() {
    Some(token) => token.text
    None => ""
  }
}

///|
fn BvhParser::fail(
  self : BvhParser,
  kind : BvhErrorKind,
  message : String,
  token? : BvhToken = BvhToken::new(TokenWord, "", 0, 0),
) -> Unit {
  if !self.error.is_error() {
    self.error = BvhError::new(
      kind,
      message,
      line=token.line,
      column=token.column,
      token=token.text,
    )
  }
}

///|
fn BvhParser::fail_eof(
  self : BvhParser,
  kind : BvhErrorKind,
  message : String,
) -> Unit {
  if !self.error.is_error() {
    let last = if self.tokens.length() > 0 {
      self.tokens[self.tokens.length() - 1]
    } else {
      BvhToken::new(TokenWord, "", 0, 0)
    }
    self.error = BvhError::new(
      kind,
      message,
      line=last.line,
      column=last.column,
      token="",
    )
  }
}

///|
fn BvhParser::accept(self : BvhParser, text : String) -> Bool {
  match self.current() {
    Some(token) if token.text == text => {
      self.index += 1
      true
    }
    _ => false
  }
}

///|
fn BvhParser::expect(
  self : BvhParser,
  text : String,
  kind : BvhErrorKind,
) -> Bool {
  match self.current() {
    Some(token) if token.text == text => {
      self.index += 1
      true
    }
    Some(token) => {
      self.fail(kind, "expected '\{text}', got '\{token.text}'", token~)
      false
    }
    None => {
      self.fail_eof(kind, "expected '\{text}', reached end of file")
      false
    }
  }
}

///|
fn BvhParser::read_word(self : BvhParser, label : String) -> String {
  match self.current() {
    Some(token) if token.kind == TokenWord => {
      self.index += 1
      token.text
    }
    Some(token) => {
      self.fail(
        ErrorUnexpectedToken,
        "expected \{label}, got '\{token.text}'",
        token~,
      )
      ""
    }
    None => {
      self.fail_eof(
        ErrorUnexpectedEof,
        "expected \{label}, reached end of file",
      )
      ""
    }
  }
}

///|
fn BvhParser::read_int(self : BvhParser, label : String) -> Int {
  match self.current() {
    Some(token) => {
      let value = @string.parse_int(token.text) catch {
        _ => {
          self.fail(
            ErrorInvalidNumber,
            "expected integer \{label}, got '\{token.text}'",
            token~,
          )
          return 0
        }
      }
      self.index += 1
      value
    }
    None => {
      self.fail_eof(
        ErrorUnexpectedEof,
        "expected integer \{label}, reached end of file",
      )
      0
    }
  }
}

///|
fn BvhParser::read_double(self : BvhParser, label : String) -> Double {
  match self.current() {
    Some(token) => {
      let value = @string.parse_double(token.text) catch {
        _ => {
          self.fail(
            ErrorInvalidNumber,
            "expected number \{label}, got '\{token.text}'",
            token~,
          )
          return 0.0
        }
      }
      self.index += 1
      value
    }
    None => {
      self.fail_eof(
        ErrorUnexpectedEof,
        "expected number \{label}, reached end of file",
      )
      0.0
    }
  }
}

///|
fn BvhParser::read_offset(self : BvhParser, path : String) -> BvhVec3 {
  if !self.expect("OFFSET", ErrorInvalidHierarchy) {
    return BvhVec3::zero()
  }
  BvhVec3::new(
    self.read_double("\{path}.offset.x"),
    self.read_double("\{path}.offset.y"),
    self.read_double("\{path}.offset.z"),
  )
}

///|
fn BvhParser::read_channels(
  self : BvhParser,
  path : String,
) -> (Array[BvhChannel], Int) {
  if !self.expect("CHANNELS", ErrorInvalidHierarchy) {
    return ([], self.channel_cursor)
  }
  let count = self.read_int("\{path}.channels.count")
  let start = self.channel_cursor
  let channels : Array[BvhChannel] = []
  if count < 0 {
    match self.current() {
      Some(token) =>
        self.fail(
          ErrorInvalidHierarchy,
          "channel count cannot be negative",
          token~,
        )
      None =>
        self.fail_eof(ErrorUnexpectedEof, "channel count cannot be negative")
    }
    return (channels, start)
  }
  for i in 0..<count {
    let name = self.read_word("\{path}.channels[\{i}]")
    channels.push(BvhChannel::from_string(name))
  }
  self.channel_cursor += count
  (channels, start)
}

///|
fn child_path(parent_path : String, name : String) -> String {
  if parent_path == "" {
    name
  } else {
    parent_path + "/" + name
  }
}

///|
fn BvhParser::parse_end_site(
  self : BvhParser,
  parent_path : String,
  depth : Int,
) -> BvhEndSite {
  if !self.expect("{", ErrorInvalidHierarchy) {
    return BvhEndSite::empty()
  }
  let path = parent_path + "/EndSite"
  let offset = self.read_offset(path)
  ignore(self.expect("}", ErrorInvalidHierarchy))
  BvhEndSite::new(path, offset, depth)
}

///|
fn BvhParser::parse_joint_node(
  self : BvhParser,
  kind : BvhJointKind,
  parent_path : String,
  depth : Int,
) -> BvhJoint {
  let name = self.read_word("joint name")
  let path = child_path(parent_path, name)
  if !self.expect("{", ErrorInvalidHierarchy) {
    return BvhJoint::empty()
  }
  let offset = self.read_offset(path)
  let (channels, start) = self.read_channels(path)
  let children : Array[BvhJoint] = []
  let end_sites : Array[BvhEndSite] = []
  while !self.is_eof() && self.peek_text() != "}" && !self.error.is_error() {
    if self.accept("JOINT") {
      children.push(self.parse_joint_node(JointRegular, path, depth + 1))
    } else if self.accept("End") {
      if self.expect("Site", ErrorInvalidHierarchy) {
        end_sites.push(self.parse_end_site(path, depth + 1))
      }
    } else {
      match self.current() {
        Some(token) =>
          self.fail(
            ErrorUnexpectedToken,
            "expected JOINT, End Site, or closing brace inside hierarchy",
            token~,
          )
        None =>
          self.fail_eof(
            ErrorUnexpectedEof,
            "expected hierarchy item or closing brace",
          )
      }
    }
  }
  ignore(self.expect("}", ErrorInvalidHierarchy))
  {
    name,
    path,
    kind,
    offset,
    channels,
    channel_start: start,
    channel_count: channels.length(),
    depth,
    children,
    end_sites,
  }
}

///|
fn BvhParser::parse_motion(self : BvhParser) -> BvhMotion {
  if !self.expect("MOTION", ErrorInvalidMotion) {
    return BvhMotion::empty()
  }
  if !self.expect("Frames:", ErrorInvalidMotion) {
    return BvhMotion::empty()
  }
  let frame_count = self.read_int("motion frame count")
  if !self.expect("Frame", ErrorInvalidMotion) {
    return BvhMotion::empty()
  }
  if !self.expect("Time:", ErrorInvalidMotion) {
    return BvhMotion::empty()
  }
  let frame_time = self.read_double("motion frame time")
  if frame_count < 0 {
    self.fail_eof(ErrorInvalidMotion, "frame count cannot be negative")
    return BvhMotion::empty()
  }
  let frames : Array[Array[Double]] = []
  for frame_index in 0..<frame_count {
    let values : Array[Double] = []
    for channel_index in 0..<self.channel_cursor {
      if self.is_eof() {
        self.fail_eof(
          ErrorFrameWidthMismatch,
          "frame \{frame_index} has fewer values than declared channel count \{self.channel_cursor}",
        )
        return {
          frame_count,
          frame_time,
          channel_count: self.channel_cursor,
          frames,
        }
      }
      values.push(self.read_double("frame[\{frame_index}][\{channel_index}]"))
    }
    frames.push(values)
  }
  { frame_count, frame_time, channel_count: self.channel_cursor, frames, }
}

///|
fn BvhParser::parse_document(
  self : BvhParser,
  source_length : Int,
) -> BvhDocument {
  if !self.expect("HIERARCHY", ErrorInvalidHierarchy) {
    return BvhDocument::empty()
  }
  if !self.expect("ROOT", ErrorInvalidHierarchy) {
    return BvhDocument::empty()
  }
  let root = self.parse_joint_node(JointRoot, "", 0)
  let motion = self.parse_motion()
  { root, motion, source_length, token_count: self.tokens.length(), }
}

///|
/// Parse ASCII BVH source into hierarchy and motion data.
pub fn parse_bvh(input : String) -> BvhParseResult {
  let tokenized = tokenize_bvh(input)
  if !tokenized.ok {
    BvhParseResult::failure(tokenized.error)
  } else {
    let parser = BvhParser::new(tokenized.tokens)
    let document = parser.parse_document(input.length())
    if parser.error.is_error() {
      BvhParseResult::failure(parser.error)
    } else if !parser.is_eof() {
      match parser.current() {
        Some(token) =>
          BvhParseResult::failure(
            BvhError::new(
              ErrorUnexpectedToken,
              "unexpected trailing token '\{token.text}'",
              line=token.line,
              column=token.column,
              token=token.text,
            ),
          )
        None => BvhParseResult::success(document)
      }
    } else {
      BvhParseResult::success(document)
    }
  }
}

///|
pub fn parse_bvh_or_empty(input : String) -> BvhDocument {
  let parsed = parse_bvh(input)
  if parsed.ok {
    parsed.document
  } else {
    BvhDocument::empty()
  }
}
