///|
pub fn analyze_bvh(document : BvhDocument) -> BvhStats {
  if !document.is_complete() {
    BvhStats::empty()
  } else {
    {
      joint_count: document.joint_count(),
      end_site_count: document.end_site_count(),
      max_depth: max_joint_depth(document.root),
      channel_count: document.motion.channel_count,
      frame_count: document.motion.frame_count,
      frame_time: document.motion.frame_time,
      duration_seconds: document.duration_seconds(),
      root_motion_distance: root_motion_distance(document),
    }
  }
}

///|
pub(all) struct BvhChannelRange {
  path : String
  channel : String
  index : Int
  min : Double
  max : Double
  span : Double
} derive(Eq, @debug.Debug)

///|
pub fn BvhChannelRange::new(
  path : String,
  channel : String,
  index : Int,
  min : Double,
  max : Double,
) -> BvhChannelRange {
  { path, channel, index, min, max, span: max - min, }
}

///|
fn collect_channel_ranges_for_joint(
  document : BvhDocument,
  joint : BvhJoint,
  out : Array[BvhChannelRange],
) -> Unit {
  for channel_offset in 0..<joint.channels.length() {
    let index = joint.channel_start + channel_offset
    let first = if document.motion.frames.length() > 0 &&
      index < document.motion.frames[0].length() {
      document.motion.frames[0][index]
    } else {
      0.0
    }
    let mut min_value = first
    let mut max_value = first
    for frame in document.motion.frames {
      if index >= 0 && index < frame.length() {
        min_value = min_double(min_value, frame[index])
        max_value = max_double(max_value, frame[index])
      }
    }
    out.push(
      BvhChannelRange::new(
        joint.path,
        joint.channels[channel_offset].to_string(),
        index,
        min_value,
        max_value,
      ),
    )
  }
  for child in joint.children {
    collect_channel_ranges_for_joint(document, child, out)
  }
}

///|
pub fn channel_ranges(document : BvhDocument) -> Array[BvhChannelRange] {
  let out : Array[BvhChannelRange] = []
  if document.root.name.length() > 0 {
    collect_channel_ranges_for_joint(document, document.root, out)
  }
  out
}

///|
pub fn widest_channel_range(document : BvhDocument) -> BvhChannelRange? {
  let ranges = channel_ranges(document)
  if ranges.length() == 0 {
    None
  } else {
    let mut best = ranges[0]
    for i in 1..<ranges.length() {
      if abs_double(ranges[i].span) > abs_double(best.span) {
        best = ranges[i]
      }
    }
    Some(best)
  }
}

///|
pub fn detect_static_channels(
  document : BvhDocument,
  epsilon? : Double = 0.00001,
) -> Array[BvhChannelRange] {
  let out : Array[BvhChannelRange] = []
  for range in channel_ranges(document) {
    if abs_double(range.span) <= epsilon {
      out.push(range)
    }
  }
  out
}

///|
pub(all) struct BvhPoseSample {
  frame_index : Int
  root_position : BvhVec3
  root_delta_from_first : BvhVec3
} derive(Eq, @debug.Debug)

///|
pub fn BvhPoseSample::new(
  frame_index : Int,
  root_position : BvhVec3,
  root_delta_from_first : BvhVec3,
) -> BvhPoseSample {
  { frame_index, root_position, root_delta_from_first, }
}

///|
pub fn sample_root_motion(
  document : BvhDocument,
  max_samples? : Int = 8,
) -> Array[BvhPoseSample] {
  if document.motion.frames.length() == 0 || max_samples <= 0 {
    []
  } else {
    let out : Array[BvhPoseSample] = []
    let first = root_position_at(document, 0)
    let step = max_int(1, document.motion.frames.length() / max_samples)
    let mut index = 0
    while index < document.motion.frames.length() {
      let position = root_position_at(document, index)
      out.push(BvhPoseSample::new(index, position, position.sub(first)))
      index += step
    }
    if out.length() == 0 ||
      out[out.length() - 1].frame_index != document.motion.frames.length() - 1 {
      let last_index = document.motion.frames.length() - 1
      let position = root_position_at(document, last_index)
      out.push(BvhPoseSample::new(last_index, position, position.sub(first)))
    }
    out
  }
}

///|
pub fn bvh_summary_line(document : BvhDocument) -> String {
  let stats = analyze_bvh(document)
  "joints=\{stats.joint_count}, end_sites=\{stats.end_site_count}, channels=\{stats.channel_count}, frames=\{stats.frame_count}, duration=\{stats.duration_seconds}s"
}
