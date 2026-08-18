///|
fn count_joints(joint : BvhJoint) -> Int {
  for child in joint.children; count = 1 {
    continue count + count_joints(child)
  } nobreak {
    count
  }
}

///|
fn count_end_sites(joint : BvhJoint) -> Int {
  let self_count = joint.end_sites.length()
  for child in joint.children; count = self_count {
    continue count + count_end_sites(child)
  } nobreak {
    count
  }
}

///|
fn max_int(a : Int, b : Int) -> Int {
  if a >= b {
    a
  } else {
    b
  }
}

///|
fn abs_double(value : Double) -> Double {
  if value < 0.0 {
    -value
  } else {
    value
  }
}

///|
fn max_double(a : Double, b : Double) -> Double {
  if a >= b {
    a
  } else {
    b
  }
}

///|
fn min_double(a : Double, b : Double) -> Double {
  if a <= b {
    a
  } else {
    b
  }
}

///|
pub fn max_joint_depth(joint : BvhJoint) -> Int {
  for child in joint.children; depth = joint.depth {
    continue max_int(depth, max_joint_depth(child))
  } nobreak {
    depth
  }
}

///|
fn collect_joint_paths_into(joint : BvhJoint, out : Array[String]) -> Unit {
  out.push(joint.path)
  for child in joint.children {
    collect_joint_paths_into(child, out)
  }
}

///|
pub fn joint_paths(document : BvhDocument) -> Array[String] {
  let out : Array[String] = []
  if document.root.name.length() > 0 {
    collect_joint_paths_into(document.root, out)
  }
  out
}

///|
fn collect_joint_names_into(joint : BvhJoint, out : Array[String]) -> Unit {
  out.push(joint.name)
  for child in joint.children {
    collect_joint_names_into(child, out)
  }
}

///|
pub fn joint_names(document : BvhDocument) -> Array[String] {
  let out : Array[String] = []
  if document.root.name.length() > 0 {
    collect_joint_names_into(document.root, out)
  }
  out
}

///|
fn find_joint_by_name_in(joint : BvhJoint, name : String) -> BvhJoint? {
  if joint.name == name {
    Some(joint)
  } else {
    for child in joint.children {
      match find_joint_by_name_in(child, name) {
        Some(found) => break Some(found)
        None => ()
      }
    } nobreak {
      None
    }
  }
}

///|
pub fn find_joint(document : BvhDocument, name : String) -> BvhJoint? {
  if document.root.name.length() == 0 {
    None
  } else {
    find_joint_by_name_in(document.root, name)
  }
}

///|
fn find_joint_by_path_in(joint : BvhJoint, path : String) -> BvhJoint? {
  if joint.path == path {
    Some(joint)
  } else {
    for child in joint.children {
      match find_joint_by_path_in(child, path) {
        Some(found) => break Some(found)
        None => ()
      }
    } nobreak {
      None
    }
  }
}

///|
pub fn find_joint_by_path(document : BvhDocument, path : String) -> BvhJoint? {
  if document.root.name.length() == 0 {
    None
  } else {
    find_joint_by_path_in(document.root, path)
  }
}

///|
pub fn channel_names(channels : Array[BvhChannel]) -> Array[String] {
  let out : Array[String] = []
  for channel in channels {
    out.push(channel.to_string())
  }
  out
}

///|
pub fn joint_channel_names(joint : BvhJoint) -> Array[String] {
  channel_names(joint.channels)
}

///|
pub fn frame_values_for_joint(
  document : BvhDocument,
  joint : BvhJoint,
  frame_index : Int,
) -> Array[Double] {
  if frame_index < 0 ||
    frame_index >= document.motion.frames.length() ||
    joint.channel_count <= 0 {
    []
  } else {
    let frame = document.motion.frames[frame_index]
    if joint.channel_start < 0 ||
      joint.channel_start + joint.channel_count > frame.length() {
      []
    } else {
      frame[joint.channel_start:joint.channel_start + joint.channel_count].to_owned()
    }
  }
}

///|
pub fn frame_values_for_joint_name(
  document : BvhDocument,
  name : String,
  frame_index : Int,
) -> Array[Double] {
  match find_joint(document, name) {
    Some(joint) => frame_values_for_joint(document, joint, frame_index)
    None => []
  }
}

///|
fn channel_value(
  document : BvhDocument,
  joint : BvhJoint,
  frame_index : Int,
  wanted : BvhChannel,
  default : Double,
) -> Double {
  if frame_index < 0 || frame_index >= document.motion.frames.length() {
    return default
  }
  let channel_offset = for i in 0..<joint.channels.length() {
    if joint.channels[i] == wanted {
      break Some(i)
    }
  } nobreak {
    None
  }
  match channel_offset {
    Some(i) => {
      let absolute = joint.channel_start + i
      let frame = document.motion.frames[frame_index]
      if absolute >= 0 && absolute < frame.length() {
        frame[absolute]
      } else {
        default
      }
    }
    None => default
  }
}

///|
pub fn root_position_at(document : BvhDocument, frame_index : Int) -> BvhVec3 {
  let root = document.root
  BvhVec3::new(
    channel_value(document, root, frame_index, ChannelXPosition, 0.0),
    channel_value(document, root, frame_index, ChannelYPosition, 0.0),
    channel_value(document, root, frame_index, ChannelZPosition, 0.0),
  )
}

///|
pub fn joint_rotation_at(
  document : BvhDocument,
  joint : BvhJoint,
  frame_index : Int,
) -> BvhVec3 {
  BvhVec3::new(
    channel_value(document, joint, frame_index, ChannelXRotation, 0.0),
    channel_value(document, joint, frame_index, ChannelYRotation, 0.0),
    channel_value(document, joint, frame_index, ChannelZRotation, 0.0),
  )
}

///|
pub fn root_motion_delta(document : BvhDocument) -> BvhVec3 {
  if document.motion.frames.length() == 0 {
    BvhVec3::zero()
  } else {
    let first = root_position_at(document, 0)
    let last = root_position_at(document, document.motion.frames.length() - 1)
    last.sub(first)
  }
}

///|
pub fn root_motion_distance(document : BvhDocument) -> Double {
  if document.motion.frames.length() <= 1 {
    0.0
  } else {
    for i in 1..<document.motion.frames.length(); distance = 0.0 {
      let prev = root_position_at(document, i - 1)
      let current = root_position_at(document, i)
      continue distance + current.sub(prev).magnitude()
    } nobreak {
      distance
    }
  }
}

///|
pub fn channel_index_for_path(
  document : BvhDocument,
  path : String,
  channel : BvhChannel,
) -> Int {
  match find_joint_by_path(document, path) {
    Some(joint) =>
      for i in 0..<joint.channels.length() {
        if joint.channels[i] == channel {
          break joint.channel_start + i
        }
      } nobreak {
        -1
      }
    None => -1
  }
}

///|
pub fn has_joint(document : BvhDocument, name : String) -> Bool {
  find_joint(document, name) != None
}

///|
pub fn contains_unknown_channels(joint : BvhJoint) -> Bool {
  for channel in joint.channels {
    if !channel.is_known() {
      break true
    }
  } nobreak {
    for child in joint.children {
      if contains_unknown_channels(child) {
        break true
      }
    } nobreak {
      false
    }
  }
}

///|
fn collect_channels_in_order_into(
  joint : BvhJoint,
  out : Array[String],
) -> Unit {
  for channel in joint.channels {
    out.push(joint.path + "." + channel.to_string())
  }
  for child in joint.children {
    collect_channels_in_order_into(child, out)
  }
}

///|
pub fn channels_in_motion_order(document : BvhDocument) -> Array[String] {
  let out : Array[String] = []
  if document.root.name.length() > 0 {
    collect_channels_in_order_into(document.root, out)
  }
  out
}
