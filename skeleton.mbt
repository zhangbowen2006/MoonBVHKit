///|
pub(all) struct BvhSkeletonBone {
  path : String
  parent_path : String
  name : String
  depth : Int
  offset : BvhVec3
  offset_length : Double
  channel_count : Int
  has_end_site : Bool
} derive(Eq, @debug.Debug)

///|
pub fn BvhSkeletonBone::new(
  path : String,
  parent_path : String,
  name : String,
  depth : Int,
  offset : BvhVec3,
  channel_count : Int,
  has_end_site : Bool,
) -> BvhSkeletonBone {
  {
    path,
    parent_path,
    name,
    depth,
    offset,
    offset_length: offset.magnitude(),
    channel_count,
    has_end_site,
  }
}

///|
fn parent_path_of(path : String) -> String {
  match path.rev_find("/") {
    Some(index) => path[:index].to_owned()
    None => ""
  }
}

///|
fn collect_bones_into(joint : BvhJoint, out : Array[BvhSkeletonBone]) -> Unit {
  out.push(
    BvhSkeletonBone::new(
      joint.path,
      parent_path_of(joint.path),
      joint.name,
      joint.depth,
      joint.offset,
      joint.channel_count,
      joint.end_sites.length() > 0,
    ),
  )
  for child in joint.children {
    collect_bones_into(child, out)
  }
}

///|
pub fn skeleton_bones(document : BvhDocument) -> Array[BvhSkeletonBone] {
  let out : Array[BvhSkeletonBone] = []
  if document.root.name.length() > 0 {
    collect_bones_into(document.root, out)
  }
  out
}

///|
fn collect_leaf_paths_into(joint : BvhJoint, out : Array[String]) -> Unit {
  if joint.children.length() == 0 {
    out.push(joint.path)
  } else {
    for child in joint.children {
      collect_leaf_paths_into(child, out)
    }
  }
}

///|
pub fn leaf_joint_paths(document : BvhDocument) -> Array[String] {
  let out : Array[String] = []
  if document.root.name.length() > 0 {
    collect_leaf_paths_into(document.root, out)
  }
  out
}

///|
fn collect_end_site_paths_into(joint : BvhJoint, out : Array[String]) -> Unit {
  for end_site in joint.end_sites {
    out.push(end_site.path)
  }
  for child in joint.children {
    collect_end_site_paths_into(child, out)
  }
}

///|
pub fn end_site_paths(document : BvhDocument) -> Array[String] {
  let out : Array[String] = []
  if document.root.name.length() > 0 {
    collect_end_site_paths_into(document.root, out)
  }
  out
}

///|
fn string_array_contains(items : Array[String], value : String) -> Bool {
  for item in items {
    if item == value {
      break true
    }
  } nobreak {
    false
  }
}

///|
pub fn skeleton_signature(document : BvhDocument) -> String {
  let parts : Array[String] = []
  for bone in skeleton_bones(document) {
    parts.push(
      "\{bone.path}#d\{bone.depth}#c\{bone.channel_count}#e\{bone.has_end_site}",
    )
  }
  parts.join(";")
}

///|
pub(all) struct BvhSkeletonSummary {
  root_name : String
  bone_count : Int
  leaf_count : Int
  end_site_count : Int
  max_depth : Int
  total_offset_length : Double
  signature : String
} derive(Eq, @debug.Debug)

///|
pub fn BvhSkeletonSummary::empty() -> BvhSkeletonSummary {
  {
    root_name: "",
    bone_count: 0,
    leaf_count: 0,
    end_site_count: 0,
    max_depth: 0,
    total_offset_length: 0.0,
    signature: "",
  }
}

///|
pub fn summarize_skeleton(document : BvhDocument) -> BvhSkeletonSummary {
  if document.root.name.length() == 0 {
    BvhSkeletonSummary::empty()
  } else {
    let bones = skeleton_bones(document)
    let total = for bone in bones; sum = 0.0 {
      continue sum + bone.offset_length
    } nobreak {
      sum
    }
    {
      root_name: document.root.name,
      bone_count: bones.length(),
      leaf_count: leaf_joint_paths(document).length(),
      end_site_count: end_site_paths(document).length(),
      max_depth: max_joint_depth(document.root),
      total_offset_length: total,
      signature: skeleton_signature(document),
    }
  }
}

///|
pub(all) struct BvhSkeletonDiff {
  compatible : Bool
  matched_paths : Array[String]
  missing_paths : Array[String]
  extra_paths : Array[String]
  channel_mismatch_paths : Array[String]
  offset_warning_paths : Array[String]
} derive(Eq, @debug.Debug)

///|
pub fn BvhSkeletonDiff::new(
  matched_paths : Array[String],
  missing_paths : Array[String],
  extra_paths : Array[String],
  channel_mismatch_paths : Array[String],
  offset_warning_paths : Array[String],
) -> BvhSkeletonDiff {
  {
    compatible: missing_paths.length() == 0 &&
    extra_paths.length() == 0 &&
    channel_mismatch_paths.length() == 0,
    matched_paths,
    missing_paths,
    extra_paths,
    channel_mismatch_paths,
    offset_warning_paths,
  }
}

///|
pub fn BvhSkeletonDiff::issue_count(self : BvhSkeletonDiff) -> Int {
  self.missing_paths.length() +
  self.extra_paths.length() +
  self.channel_mismatch_paths.length() +
  self.offset_warning_paths.length()
}

///|
fn bone_by_path(
  bones : Array[BvhSkeletonBone],
  path : String,
) -> BvhSkeletonBone? {
  for bone in bones {
    if bone.path == path {
      break Some(bone)
    }
  } nobreak {
    None
  }
}

///|
pub fn compare_skeletons(
  reference : BvhDocument,
  candidate : BvhDocument,
  offset_epsilon? : Double = 0.001,
) -> BvhSkeletonDiff {
  let ref_bones = skeleton_bones(reference)
  let cand_bones = skeleton_bones(candidate)
  let ref_paths = joint_paths(reference)
  let cand_paths = joint_paths(candidate)
  let matched : Array[String] = []
  let missing : Array[String] = []
  let extra : Array[String] = []
  let channel_mismatches : Array[String] = []
  let offset_warnings : Array[String] = []
  for ref_bone in ref_bones {
    match bone_by_path(cand_bones, ref_bone.path) {
      Some(cand_bone) => {
        matched.push(ref_bone.path)
        if ref_bone.channel_count != cand_bone.channel_count {
          channel_mismatches.push(ref_bone.path)
        }
        if abs_double(ref_bone.offset_length - cand_bone.offset_length) >
          offset_epsilon {
          offset_warnings.push(ref_bone.path)
        }
      }
      None => missing.push(ref_bone.path)
    }
  }
  for cand_path in cand_paths {
    if !string_array_contains(ref_paths, cand_path) {
      extra.push(cand_path)
    }
  }
  BvhSkeletonDiff::new(
    matched, missing, extra, channel_mismatches, offset_warnings,
  )
}

///|
pub(all) struct BvhRetargetMapEntry {
  source_path : String
  target_path : String
  source_channel_count : Int
  target_channel_count : Int
  channel_compatible : Bool
  notes : String
} derive(Eq, @debug.Debug)

///|
pub fn BvhRetargetMapEntry::new(
  source_path : String,
  target_path : String,
  source_channel_count : Int,
  target_channel_count : Int,
) -> BvhRetargetMapEntry {
  let compatible = source_channel_count == target_channel_count
  {
    source_path,
    target_path,
    source_channel_count,
    target_channel_count,
    channel_compatible: compatible,
    notes: if compatible {
      "channels match"
    } else {
      "channel count differs"
    },
  }
}

///|
fn bone_by_name(
  bones : Array[BvhSkeletonBone],
  name : String,
) -> BvhSkeletonBone? {
  for bone in bones {
    if bone.name == name {
      break Some(bone)
    }
  } nobreak {
    None
  }
}

///|
pub fn build_name_based_retarget_map(
  source : BvhDocument,
  target : BvhDocument,
) -> Array[BvhRetargetMapEntry] {
  let out : Array[BvhRetargetMapEntry] = []
  let source_bones = skeleton_bones(source)
  let target_bones = skeleton_bones(target)
  for source_bone in source_bones {
    match bone_by_name(target_bones, source_bone.name) {
      Some(target_bone) =>
        out.push(
          BvhRetargetMapEntry::new(
            source_bone.path,
            target_bone.path,
            source_bone.channel_count,
            target_bone.channel_count,
          ),
        )
      None => ()
    }
  }
  out
}

///|
pub fn skeleton_summary_to_json(summary : BvhSkeletonSummary) -> String {
  let result =
    $|{"rootName":\{json_string(summary.root_name)},"boneCount":\{summary.bone_count},"leafCount":\{summary.leaf_count},"endSiteCount":\{summary.end_site_count},"maxDepth":\{summary.max_depth},"totalOffsetLength":\{summary.total_offset_length},"signature":\{json_string(summary.signature)}}
  result
}

///|
pub fn skeleton_diff_to_json(diff : BvhSkeletonDiff) -> String {
  fn quoted(items : Array[String]) -> String {
    let out : Array[String] = []
    for item in items {
      out.push(json_string(item))
    }
    "[" + out.join(",") + "]"
  }
  let result =
    $|{"compatible":\{diff.compatible},"matchedPaths":\{quoted(diff.matched_paths)},"missingPaths":\{quoted(diff.missing_paths)},"extraPaths":\{quoted(diff.extra_paths)},"channelMismatchPaths":\{quoted(diff.channel_mismatch_paths)},"offsetWarningPaths":\{quoted(diff.offset_warning_paths)}}
  result
}

///|
pub fn retarget_map_to_csv(entries : Array[BvhRetargetMapEntry]) -> String {
  let rows : Array[String] = [
    "source_path,target_path,source_channel_count,target_channel_count,channel_compatible,notes",
  ]
  for entry in entries {
    rows.push(
      "\{entry.source_path},\{entry.target_path},\{entry.source_channel_count},\{entry.target_channel_count},\{entry.channel_compatible},\{entry.notes}",
    )
  }
  rows.join("\n")
}

///|
pub fn skeleton_bones_csv(document : BvhDocument) -> String {
  let rows : Array[String] = [
    "path,parent_path,name,depth,offset_x,offset_y,offset_z,offset_length,channel_count,has_end_site",
  ]
  for bone in skeleton_bones(document) {
    rows.push(
      "\{bone.path},\{bone.parent_path},\{bone.name},\{bone.depth},\{bone.offset.to_csv()},\{bone.offset_length},\{bone.channel_count},\{bone.has_end_site}",
    )
  }
  rows.join("\n")
}
