///|
fn profile_doc() -> @moonbvhkit.BvhDocument raise Error {
  let parsed = @moonbvhkit.parse_bvh(@moonbvhkit.fixture_walk_bvh())
  assert_true(parsed.ok)
  parsed.document
}

///|
test "default import profiles expose common asset gates" {
  let profiles = @moonbvhkit.default_import_profiles()
  assert_eq(profiles.length(), 4)
  assert_eq(profiles[0].kind.to_string(), "unity")
  assert_true(profiles[2].min_quality_score >= 90)
}

///|
test "profile lookup falls back to preview profile" {
  assert_eq(
    @moonbvhkit.import_profile_by_name("unity").kind.to_string(),
    "unity",
  )
  assert_eq(
    @moonbvhkit.import_profile_by_name("strict-ci").kind.to_string(),
    "strict-ci",
  )
  assert_eq(
    @moonbvhkit.import_profile_by_name("unknown").kind.to_string(),
    "preview",
  )
}

///|
test "valid fixture passes strict import profile" {
  let decision = @moonbvhkit.evaluate_import_profile(
    profile_doc(),
    @moonbvhkit.strict_ci_import_profile(),
  )
  assert_true(decision.ok())
  assert_eq(decision.action, "accept")
  assert_eq(decision.issue_count(), 0)
}

///|
test "profile decision blocks parse failures" {
  let decision = @moonbvhkit.evaluate_bvh_import_profile(
    @moonbvhkit.fixture_invalid_missing_motion(),
    @moonbvhkit.unity_import_profile(),
  )
  assert_true(!decision.accepted)
  assert_eq(decision.action, "block")
  assert_true(decision.error_count() > 0)
}

///|
test "unknown channel is blocked by production profile" {
  let parsed = @moonbvhkit.parse_bvh(@moonbvhkit.fixture_unknown_channel())
  assert_true(parsed.ok)
  let decision = @moonbvhkit.evaluate_import_profile(
    parsed.document,
    @moonbvhkit.unity_import_profile(),
  )
  assert_true(!decision.accepted)
  assert_true(decision.error_count() > 0)
}

///|
test "frame rate helper uses motion frame time" {
  let fps = @moonbvhkit.document_frame_rate(profile_doc())
  assert_true(fps > 29.9)
  assert_true(fps < 30.1)
}

///|
test "default profile matrix evaluates every profile" {
  let decisions = @moonbvhkit.evaluate_default_import_profiles(profile_doc())
  assert_eq(decisions.length(), 4)
  assert_true(decisions[0].accepted)
  assert_true(decisions[1].accepted)
}

///|
test "profile and decision exporters are stable" {
  let profile = @moonbvhkit.unity_import_profile()
  let profile_json = @moonbvhkit.import_profile_to_json(profile)
  assert_true(profile_json.find("\"kind\":\"unity\"") != None)
  let decision = @moonbvhkit.evaluate_import_profile(profile_doc(), profile)
  let decision_json = @moonbvhkit.import_decision_to_json(decision)
  assert_true(decision_json.find("\"accepted\":true") != None)
  assert_true(
    @moonbvhkit.import_decision_to_text(decision).find("profile=") != None,
  )
}

///|
test "profile CSV exporters include gate columns" {
  let profile_csv = @moonbvhkit.import_profiles_to_csv(
    @moonbvhkit.default_import_profiles(),
  )
  assert_true(profile_csv.find("min_quality_score") != None)
  let decision_csv = @moonbvhkit.import_decisions_to_csv(
    @moonbvhkit.evaluate_default_import_profiles(profile_doc()),
  )
  assert_true(decision_csv.find("profile,accepted,action") != None)
}
