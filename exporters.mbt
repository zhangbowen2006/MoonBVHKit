///|
fn json_escape(text : String) -> String {
  text
  .replace_all(old="\\", new="\\\\")
  .replace_all(old="\"", new="\\\"")
  .replace_all(old="\n", new="\\n")
}

///|
fn json_string(text : String) -> String {
  "\"" + json_escape(text) + "\""
}

///|
pub fn channels_to_json(channels : Array[BvhChannel]) -> String {
  let parts : Array[String] = []
  for channel in channels {
    parts.push(json_string(channel.to_string()))
  }
  "[" + parts.join(",") + "]"
}

///|
pub fn vec3_to_json(vec : BvhVec3) -> String {
  let result =
    $|{"x":\{vec.x},"y":\{vec.y},"z":\{vec.z}}
  result
}

///|
pub fn joint_to_json(joint : BvhJoint) -> String {
  let children : Array[String] = []
  for child in joint.children {
    children.push(joint_to_json(child))
  }
  let ends : Array[String] = []
  for end_site in joint.end_sites {
    let row =
      $|{"path":\{json_string(end_site.path)},"offset":\{vec3_to_json(end_site.offset)},"depth":\{end_site.depth}}
    ends.push(row)
  }
  let result =
    $|{"name":\{json_string(joint.name)},"path":\{json_string(joint.path)},"kind":\{json_string(joint.kind.to_string())},"offset":\{vec3_to_json(joint.offset)},"channels":\{channels_to_json(joint.channels)},"channelStart":\{joint.channel_start},"channelCount":\{joint.channel_count},"depth":\{joint.depth},"children":[\{children.join(",")}],"endSites":[\{ends.join(",")}]}
  result
}

///|
pub fn stats_to_json(stats : BvhStats) -> String {
  let result =
    $|{"jointCount":\{stats.joint_count},"endSiteCount":\{stats.end_site_count},"maxDepth":\{stats.max_depth},"channelCount":\{stats.channel_count},"frameCount":\{stats.frame_count},"frameTime":\{stats.frame_time},"durationSeconds":\{stats.duration_seconds},"rootMotionDistance":\{stats.root_motion_distance}}
  result
}

///|
pub fn validation_to_json(report : BvhValidationReport) -> String {
  let issues : Array[String] = []
  for issue in report.issues {
    let row =
      $|{"severity":\{json_string(issue.severity.to_string())},"path":\{json_string(issue.path)},"code":\{json_string(issue.code)},"message":\{json_string(issue.message)}}
    issues.push(row)
  }
  let result =
    $|{"ok":\{report.ok()},"errors":\{report.error_count},"warnings":\{report.warning_count},"info":\{report.info_count},"issues":[\{issues.join(",")}]}
  result
}

///|
pub fn document_to_json(document : BvhDocument) -> String {
  let stats = analyze_bvh(document)
  let result =
    $|{"format":"BVH","sourceLength":\{document.source_length},"tokenCount":\{document.token_count},"stats":\{stats_to_json(stats)},"root":\{joint_to_json(document.root)}}
  result
}

///|
pub fn joint_table_csv(document : BvhDocument) -> String {
  let rows : Array[String] = [
    "path,name,depth,channel_start,channel_count,channels,offset_x,offset_y,offset_z",
  ]
  fn walk(joint : BvhJoint, rows : Array[String]) -> Unit {
    rows.push(
      "\{joint.path},\{joint.name},\{joint.depth},\{joint.channel_start},\{joint.channel_count},\{channel_names(joint.channels).join("|")},\{joint.offset.to_csv()}",
    )
    for child in joint.children {
      walk(child, rows)
    }
  }
  if document.root.name.length() > 0 {
    walk(document.root, rows)
  }
  rows.join("\n")
}

///|
pub fn channel_range_csv(document : BvhDocument) -> String {
  let rows : Array[String] = ["path,channel,index,min,max,span"]
  for range in channel_ranges(document) {
    rows.push(
      "\{range.path},\{range.channel},\{range.index},\{range.min},\{range.max},\{range.span}",
    )
  }
  rows.join("\n")
}

///|
pub fn root_motion_csv(document : BvhDocument) -> String {
  let rows : Array[String] = ["frame,x,y,z,delta_x,delta_y,delta_z"]
  for
    sample in sample_root_motion(
      document,
      max_samples=document.motion.frames.length(),
    ) {
    rows.push(
      "\{sample.frame_index},\{sample.root_position.to_csv()},\{sample.root_delta_from_first.to_csv()}",
    )
  }
  rows.join("\n")
}
