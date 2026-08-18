///|
fn skeleton_doc() -> @moonbvhkit.BvhDocument raise Error {
  let parsed = @moonbvhkit.parse_bvh(@moonbvhkit.fixture_walk_bvh())
  assert_true(parsed.ok)
  parsed.document
}

///|
test "skeleton bones preserve parent and offset metadata" {
  let bones = @moonbvhkit.skeleton_bones(skeleton_doc())
  assert_eq(bones.length(), 4)
  assert_eq(bones[0].path, "Hips")
  assert_eq(bones[1].parent_path, "Hips")
  assert_eq(bones[2].name, "Head")
  assert_true(bones[2].offset_length > 7.9)
}

///|
test "leaf and end-site path helpers expose import leaves" {
  let doc = skeleton_doc()
  let leaves = @moonbvhkit.leaf_joint_paths(doc)
  let ends = @moonbvhkit.end_site_paths(doc)
  assert_eq(leaves.join("|"), "Hips/Spine/Head|Hips/LeftArm")
  assert_eq(ends.length(), 2)
  assert_true(ends[0].find("EndSite") != None)
}

///|
test "skeleton summary produces stable signature" {
  let summary = @moonbvhkit.summarize_skeleton(skeleton_doc())
  assert_eq(summary.root_name, "Hips")
  assert_eq(summary.bone_count, 4)
  assert_eq(summary.leaf_count, 2)
  assert_true(summary.signature.find("Hips/Spine/Head") != None)
}

///|
test "skeleton comparison reports identical fixture as compatible" {
  let doc = skeleton_doc()
  let diff = @moonbvhkit.compare_skeletons(doc, doc)
  assert_true(diff.compatible)
  assert_eq(diff.issue_count(), 0)
  assert_eq(diff.matched_paths.length(), 4)
}

///|
test "skeleton comparison catches missing and extra paths" {
  let reference = skeleton_doc()
  let candidate = @moonbvhkit.parse_bvh_or_empty(
    @moonbvhkit.fixture_static_pose_bvh(),
  )
  let diff = @moonbvhkit.compare_skeletons(reference, candidate)
  assert_true(!diff.compatible)
  assert_true(diff.missing_paths.length() > 0)
  assert_true(diff.extra_paths.length() > 0)
}

///|
test "retarget map matches same-named bones" {
  let doc = skeleton_doc()
  let entries = @moonbvhkit.build_name_based_retarget_map(doc, doc)
  assert_eq(entries.length(), 4)
  assert_true(entries[0].channel_compatible)
}

///|
test "skeleton exporters expose useful machine formats" {
  let doc = skeleton_doc()
  let summary_json = @moonbvhkit.skeleton_summary_to_json(
    @moonbvhkit.summarize_skeleton(doc),
  )
  assert_true(summary_json.find("\"boneCount\":4") != None)
  let diff_json = @moonbvhkit.skeleton_diff_to_json(
    @moonbvhkit.compare_skeletons(doc, doc),
  )
  assert_true(diff_json.find("\"compatible\":true") != None)
  let csv = @moonbvhkit.skeleton_bones_csv(doc)
  assert_true(csv.find("path,parent_path,name") != None)
}

///|
test "retarget CSV includes compatibility columns" {
  let doc = skeleton_doc()
  let csv = @moonbvhkit.retarget_map_to_csv(
    @moonbvhkit.build_name_based_retarget_map(doc, doc),
  )
  assert_true(csv.find("channel_compatible") != None)
  assert_true(csv.find("channels match") != None)
}
