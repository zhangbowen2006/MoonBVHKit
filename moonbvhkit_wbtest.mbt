///|
test "brace tokenizer classifies braces" {
  assert_true(token_kind_for_brace(123) == TokenOpenBrace)
  assert_true(token_kind_for_brace(125) == TokenCloseBrace)
  assert_eq(token_text_for_brace(123), "{")
  assert_eq(token_text_for_brace(125), "}")
}

///|
test "channel helper methods classify standard BVH channels" {
  assert_true(BvhChannel::from_string("Xposition").is_position())
  assert_true(BvhChannel::from_string("Yrotation").is_rotation())
  assert_eq(BvhChannel::from_string("Zrotation").axis(), "z")
  assert_true(!BvhChannel::from_string("ScaleX").is_known())
}

///|
test "vec3 helpers compute deltas" {
  let a = BvhVec3::new(3.0, 0.0, 4.0)
  assert_eq(a.magnitude(), 5.0)
  let b = a.sub(BvhVec3::new(1.0, 1.0, 1.0))
  assert_eq(b.x, 2.0)
  assert_eq(b.y, -1.0)
  assert_eq(b.z, 3.0)
}

///|
test "manifest includes scoped non plugin stance" {
  let manifest = bvh_runtime_manifest()
  assert_eq(manifest.package_name, "zhangbowen2006/moonbvhkit")
  assert_true(manifest_to_text(manifest).find("not a Python addon") != None)
}
