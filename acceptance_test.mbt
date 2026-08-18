///|
test "acceptance pipeline approves a valid clip" {
  let parsed = @moonbvhkit.parse_bvh(@moonbvhkit.fixture_walk_bvh())
  assert_true(parsed.ok)
  let document = parsed.document
  let validation = @moonbvhkit.validate_document(document)
  let quality = @moonbvhkit.quality_report(document)
  let decision = @moonbvhkit.evaluate_import_profile(
    document,
    @moonbvhkit.strict_ci_import_profile(),
  )
  assert_true(validation.ok())
  assert_true(quality.ok_for_import())
  assert_eq(quality.score, 100)
  assert_true(decision.ok())
  assert_eq(decision.action, "accept")
  assert_true(
    @moonbvhkit.document_to_json(document).find("\"format\":\"BVH\"") != None,
  )
}

///|
test "acceptance pipeline blocks malformed frame data" {
  let source = @moonbvhkit.fixture_invalid_frame_width()
  let parsed = @moonbvhkit.parse_bvh(source)
  let quality = @moonbvhkit.quality_report_from_bvh(source)
  let decision = @moonbvhkit.evaluate_bvh_import_profile(
    source,
    @moonbvhkit.unity_import_profile(),
  )
  assert_true(!parsed.ok)
  assert_true(parsed.error.kind == @moonbvhkit.ErrorFrameWidthMismatch)
  assert_true(quality.grade == @moonbvhkit.QualityBlocked)
  assert_eq(quality.recommended_action, "fix-before-import")
  assert_true(!decision.ok())
  assert_eq(decision.action, "block")
}

///|
test "acceptance pipeline exports engine-neutral integration plans" {
  let document = @moonbvhkit.parse_bvh_or_empty(@moonbvhkit.fixture_walk_bvh())
  let unity = @moonbvhkit.build_unity_clip_plan(document, clip_name="walk")
  let blender = @moonbvhkit.build_blender_import_plan(document)
  let profile_matrix = @moonbvhkit.evaluate_default_import_profiles(document)
  assert_eq(unity.clip_name, "walk")
  assert_eq(unity.joint_paths.length(), 4)
  assert_eq(blender.bone_count, 4)
  assert_eq(profile_matrix.length(), 4)
  assert_true(
    @moonbvhkit.unity_clip_plan_to_json(unity).find("\"clipName\":\"walk\"") !=
    None,
  )
  assert_true(
    @moonbvhkit.import_decisions_to_csv(profile_matrix).find(
      "profile,accepted,action",
    ) !=
    None,
  )
}
