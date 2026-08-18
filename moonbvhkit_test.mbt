///|
fn parsed_walk() -> @moonbvhkit.BvhDocument raise Error {
  let parsed = @moonbvhkit.parse_bvh(@moonbvhkit.fixture_walk_bvh())
  assert_true(parsed.ok)
  parsed.document
}

///|
test "tokenize keeps hierarchy keywords and positions" {
  let tokens = @moonbvhkit.tokenize_bvh(@moonbvhkit.fixture_walk_bvh())
  assert_true(tokens.ok)
  assert_eq(tokens.tokens[0].text, "HIERARCHY")
  assert_eq(tokens.tokens[1].text, "ROOT")
  assert_eq(tokens.tokens[2].text, "Hips")
  assert_eq(tokens.tokens[0].line, 1)
  assert_eq(tokens.tokens[1].line, 2)
}

///|
test "parse root metadata" {
  let doc = parsed_walk()
  assert_eq(doc.root.name, "Hips")
  assert_eq(doc.root.path, "Hips")
  assert_true(doc.root.is_root())
  assert_eq(doc.root.channel_count, 6)
  assert_eq(doc.motion.channel_count, 15)
  assert_eq(doc.motion.frame_count, 4)
}

///|
test "parse child hierarchy and end sites" {
  let doc = parsed_walk()
  assert_eq(doc.root.children.length(), 2)
  assert_eq(doc.root.children[0].name, "Spine")
  assert_eq(doc.root.children[0].children[0].name, "Head")
  assert_eq(doc.root.children[0].children[0].end_sites.length(), 1)
  assert_eq(doc.root.children[1].end_sites.length(), 1)
  assert_eq(doc.end_site_count(), 2)
}

///|
test "channels preserve motion order" {
  let doc = parsed_walk()
  let order = @moonbvhkit.channels_in_motion_order(doc)
  assert_eq(order.length(), 15)
  assert_eq(order[0], "Hips.Xposition")
  assert_eq(order[5], "Hips.Yrotation")
  assert_eq(order[6], "Hips/Spine.Zrotation")
}

///|
test "query joints by name and path" {
  let doc = parsed_walk()
  match @moonbvhkit.find_joint(doc, "Head") {
    Some(head) => {
      assert_eq(head.path, "Hips/Spine/Head")
      assert_eq(head.channel_start, 9)
    }
    None => fail("Head not found")
  }
  assert_true(@moonbvhkit.find_joint_by_path(doc, "Hips/LeftArm") != None)
  assert_true(!@moonbvhkit.has_joint(doc, "RightLeg"))
}

///|
test "frame values and root position are queryable" {
  let doc = parsed_walk()
  let root = @moonbvhkit.root_position_at(doc, 2)
  assert_eq(root.x, 2.0)
  assert_eq(root.z, 0.4)
  let spine_values = @moonbvhkit.frame_values_for_joint_name(doc, "Spine", 1)
  assert_eq(spine_values.length(), 3)
  assert_eq(spine_values[0], 5.5)
}

///|
test "stats summarize usable clip information" {
  let doc = parsed_walk()
  let stats = @moonbvhkit.analyze_bvh(doc)
  assert_eq(stats.joint_count, 4)
  assert_eq(stats.end_site_count, 2)
  assert_eq(stats.max_depth, 2)
  assert_eq(stats.channel_count, 15)
  assert_eq(stats.frame_count, 4)
  assert_true(stats.root_motion_distance > 3.0)
}

///|
test "validation succeeds with fixture and reports info" {
  let doc = parsed_walk()
  let report = @moonbvhkit.validate_document(doc)
  assert_true(report.ok())
  assert_eq(report.error_count, 0)
}

///|
test "invalid empty input fails" {
  let parsed = @moonbvhkit.parse_bvh(@moonbvhkit.fixture_empty_bvh())
  assert_true(!parsed.ok)
  assert_true(parsed.error.kind == @moonbvhkit.ErrorEmptyInput)
}

///|
test "invalid missing motion fails" {
  let parsed = @moonbvhkit.parse_bvh(
    @moonbvhkit.fixture_invalid_missing_motion(),
  )
  assert_true(!parsed.ok)
  assert_true(parsed.error.kind == @moonbvhkit.ErrorInvalidMotion)
}

///|
test "invalid frame width fails during parse" {
  let parsed = @moonbvhkit.parse_bvh(@moonbvhkit.fixture_invalid_frame_width())
  assert_true(!parsed.ok)
  assert_true(parsed.error.kind == @moonbvhkit.ErrorFrameWidthMismatch)
}

///|
test "unknown channels become validation errors" {
  let parsed = @moonbvhkit.parse_bvh(@moonbvhkit.fixture_unknown_channel())
  assert_true(parsed.ok)
  let report = @moonbvhkit.validate_document(parsed.document)
  assert_true(!report.ok())
  assert_eq(report.error_count, 1)
  assert_true(@moonbvhkit.contains_unknown_channels(parsed.document.root))
}

///|
test "channel ranges find animated data" {
  let doc = parsed_walk()
  let ranges = @moonbvhkit.channel_ranges(doc)
  assert_eq(ranges.length(), 15)
  match @moonbvhkit.widest_channel_range(doc) {
    Some(range) => assert_true(range.span >= 1.5)
    None => fail("missing range")
  }
}

///|
test "static channel detector works" {
  let doc = parsed_walk()
  let still_channels = @moonbvhkit.detect_static_channels(doc)
  assert_true(still_channels.length() > 0)
}

///|
test "exporters return stable machine-readable snippets" {
  let doc = parsed_walk()
  let json = @moonbvhkit.document_to_json(doc)
  assert_true(json.find("\"format\":\"BVH\"") != None)
  let csv = @moonbvhkit.joint_table_csv(doc)
  assert_true(csv.find("Hips/Spine/Head") != None)
}

///|
test "unity and blender plans expose integration metadata" {
  let doc = parsed_walk()
  let unity = @moonbvhkit.build_unity_clip_plan(doc, clip_name="walk")
  assert_eq(unity.clip_name, "walk")
  assert_eq(unity.joint_paths.length(), 4)
  assert_true(unity.frame_rate > 29.0)
  let blender = @moonbvhkit.build_blender_import_plan(doc)
  assert_eq(blender.bone_count, 4)
  assert_eq(blender.leaf_count, 2)
}

///|
test "report supports text json and csv" {
  let text = @moonbvhkit.bvh_fixture_report()
  assert_true(text.find("MoonBVHKit report") != None)
  let json = @moonbvhkit.bvh_fixture_report(format=@moonbvhkit.ReportJson)
  assert_true(json.find("\"ok\":true") != None)
  let csv = @moonbvhkit.bvh_fixture_report(format=@moonbvhkit.ReportCsv)
  assert_true(csv.find("metric,value") != None)
}

///|
test "static pose validates with static root info" {
  let parsed = @moonbvhkit.parse_bvh(@moonbvhkit.fixture_static_pose_bvh())
  assert_true(parsed.ok)
  let report = @moonbvhkit.validate_document(parsed.document)
  assert_true(report.ok())
  assert_eq(report.info_count, 1)
  assert_eq(@moonbvhkit.root_motion_distance(parsed.document), 0.0)
}

///|
test "motion duration comes from frames and frame time" {
  let parsed = @moonbvhkit.parse_bvh(@moonbvhkit.fixture_static_pose_bvh())
  assert_true(parsed.ok)
  assert_eq(parsed.document.motion.duration_seconds(), 0.0833334)
  assert_eq(parsed.document.duration_seconds(), 0.0833334)
}

///|
test "channel index by path returns expected offsets" {
  let doc = parsed_walk()
  assert_eq(
    @moonbvhkit.channel_index_for_path(
      doc,
      "Hips/Spine/Head",
      @moonbvhkit.ChannelXRotation,
    ),
    10,
  )
  assert_eq(
    @moonbvhkit.channel_index_for_path(
      doc,
      "Hips/Spine/Head",
      @moonbvhkit.ChannelXPosition,
    ),
    -1,
  )
}

///|
test "root motion samples include first and last frames" {
  let doc = parsed_walk()
  let samples = @moonbvhkit.sample_root_motion(doc, max_samples=2)
  assert_true(samples.length() >= 2)
  assert_eq(samples[0].frame_index, 0)
  assert_eq(samples[samples.length() - 1].frame_index, 3)
  assert_eq(samples[samples.length() - 1].root_delta_from_first.x, 3.0)
}

///|
test "joint names and paths are collected depth first" {
  let doc = parsed_walk()
  let names = @moonbvhkit.joint_names(doc)
  let paths = @moonbvhkit.joint_paths(doc)
  assert_eq(names.join("|"), "Hips|Spine|Head|LeftArm")
  assert_eq(paths[2], "Hips/Spine/Head")
}

///|
test "frame query returns empty arrays for invalid requests" {
  let doc = parsed_walk()
  assert_eq(
    @moonbvhkit.frame_values_for_joint_name(doc, "Missing", 0).length(),
    0,
  )
  assert_eq(
    @moonbvhkit.frame_values_for_joint_name(doc, "Spine", -1).length(),
    0,
  )
  assert_eq(
    @moonbvhkit.frame_values_for_joint_name(doc, "Spine", 99).length(),
    0,
  )
}

///|
test "root position out of bounds is zero" {
  let doc = parsed_walk()
  let pos = @moonbvhkit.root_position_at(doc, 99)
  assert_eq(pos.x, 0.0)
  assert_eq(pos.y, 0.0)
  assert_eq(pos.z, 0.0)
}

///|
test "validation summary distinguishes ok and failed reports" {
  let ok_report = @moonbvhkit.validate_bvh(@moonbvhkit.fixture_walk_bvh())
  assert_true(@moonbvhkit.validation_summary(ok_report).find("ok:") != None)
  let failed_report = @moonbvhkit.validate_bvh(
    @moonbvhkit.fixture_invalid_frame_width(),
  )
  assert_true(
    @moonbvhkit.validation_summary(failed_report).find("failed:") != None,
  )
}

///|
test "manifest JSON and text include package metadata" {
  let manifest = @moonbvhkit.bvh_runtime_manifest()
  assert_true(@moonbvhkit.manifest_to_text(manifest).find("ASCII BVH") != None)
  assert_true(
    @moonbvhkit.manifest_to_json(manifest).find("\"packageName\"") != None,
  )
}

///|
test "adapter JSON exporters include plan fields" {
  let doc = parsed_walk()
  let unity = @moonbvhkit.unity_clip_plan_to_json(
    @moonbvhkit.build_unity_clip_plan(doc),
  )
  assert_true(unity.find("\"clipName\"") != None)
  let blender = @moonbvhkit.blender_import_plan_to_json(
    @moonbvhkit.build_blender_import_plan(doc),
  )
  assert_true(blender.find("\"armatureName\"") != None)
}

///|
test "range CSV and root motion CSV expose headers" {
  let doc = parsed_walk()
  assert_true(
    @moonbvhkit.channel_range_csv(doc).find("path,channel,index") != None,
  )
  assert_true(@moonbvhkit.root_motion_csv(doc).find("frame,x,y,z") != None)
}

///|
test "document JSON escapes plain strings and includes root" {
  let doc = parsed_walk()
  let json = @moonbvhkit.document_to_json(doc)
  assert_true(json.find("\"root\"") != None)
  assert_true(json.find("\"Hips\"") != None)
}

///|
test "parse_or_empty hides parser errors for smoke callers" {
  let empty = @moonbvhkit.parse_bvh_or_empty(
    @moonbvhkit.fixture_invalid_missing_motion(),
  )
  assert_eq(empty.root.name, "")
  let doc = @moonbvhkit.parse_bvh_or_empty(
    @moonbvhkit.fixture_static_pose_bvh(),
  )
  assert_eq(doc.root.name, "Root")
}

///|
test "token dump is readable" {
  let tokenized = @moonbvhkit.tokenize_bvh("HIERARCHY ROOT A { OFFSET 0 0 0 }")
  assert_true(tokenized.ok)
  assert_true(
    @moonbvhkit.bvh_tokens_to_text(tokenized.tokens).find("HIERARCHY@1:1") !=
    None,
  )
}
