///|
pub(all) struct BvhUnityClipPlan {
  clip_name : String
  frame_rate : Double
  duration_seconds : Double
  root_joint : String
  joint_paths : Array[String]
  root_motion_delta : BvhVec3
  warnings : Array[String]
} derive(Eq, @debug.Debug)

///|
pub fn build_unity_clip_plan(
  document : BvhDocument,
  clip_name? : String = "clip",
) -> BvhUnityClipPlan {
  let warnings : Array[String] = []
  let frame_rate = if document.motion.frame_time > 0.0 {
    1.0 / document.motion.frame_time
  } else {
    0.0
  }
  if contains_unknown_channels(document.root) {
    warnings.push("unknown BVH channels should be remapped before import")
  }
  if document.root.position_channel_count() == 0 {
    warnings.push(
      "root has no position channels; root motion delta will be zero",
    )
  }
  {
    clip_name,
    frame_rate,
    duration_seconds: document.duration_seconds(),
    root_joint: document.root.name,
    joint_paths: joint_paths(document),
    root_motion_delta: root_motion_delta(document),
    warnings,
  }
}

///|
pub(all) struct BvhBlenderImportPlan {
  armature_name : String
  bone_count : Int
  leaf_count : Int
  frame_start : Int
  frame_end : Int
  fps : Double
  preserve_root_motion : Bool
  axis_notes : Array[String]
} derive(Eq, @debug.Debug)

///|
pub fn build_blender_import_plan(
  document : BvhDocument,
  armature_name? : String = "Armature",
) -> BvhBlenderImportPlan {
  let notes : Array[String] = [
    "BVH offsets are preserved in file units", "rotation channel order is kept per joint",
    "package does not bake coordinate-system conversion",
  ]
  {
    armature_name,
    bone_count: document.joint_count(),
    leaf_count: document.end_site_count(),
    frame_start: 1,
    frame_end: document.motion.frame_count,
    fps: if document.motion.frame_time > 0.0 {
      1.0 / document.motion.frame_time
    } else {
      0.0
    },
    preserve_root_motion: document.root.position_channel_count() > 0,
    axis_notes: notes,
  }
}

///|
pub fn unity_clip_plan_to_json(plan : BvhUnityClipPlan) -> String {
  let paths : Array[String] = []
  for path in plan.joint_paths {
    paths.push(json_string(path))
  }
  let warnings : Array[String] = []
  for warning in plan.warnings {
    warnings.push(json_string(warning))
  }
  let result =
    $|{"clipName":\{json_string(plan.clip_name)},"frameRate":\{plan.frame_rate},"durationSeconds":\{plan.duration_seconds},"rootJoint":\{json_string(plan.root_joint)},"jointPaths":[\{paths.join(",")}],"rootMotionDelta":\{vec3_to_json(plan.root_motion_delta)},"warnings":[\{warnings.join(",")}]}
  result
}

///|
pub fn blender_import_plan_to_json(plan : BvhBlenderImportPlan) -> String {
  let notes : Array[String] = []
  for note in plan.axis_notes {
    notes.push(json_string(note))
  }
  let result =
    $|{"armatureName":\{json_string(plan.armature_name)},"boneCount":\{plan.bone_count},"leafCount":\{plan.leaf_count},"frameStart":\{plan.frame_start},"frameEnd":\{plan.frame_end},"fps":\{plan.fps},"preserveRootMotion":\{plan.preserve_root_motion},"axisNotes":[\{notes.join(",")}]}
  result
}
