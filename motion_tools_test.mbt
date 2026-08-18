///|
fn motion_doc() -> @moonbvhkit.BvhDocument raise Error {
  let parsed = @moonbvhkit.parse_bvh(@moonbvhkit.fixture_walk_bvh())
  assert_true(parsed.ok)
  parsed.document
}

///|
test "frame index clamp handles out-of-range values" {
  let doc = motion_doc()
  assert_eq(@moonbvhkit.clamp_frame_index(doc, -10), 0)
  assert_eq(@moonbvhkit.clamp_frame_index(doc, 99), 3)
  assert_eq(@moonbvhkit.clamp_frame_index(doc, 2), 2)
}

///|
test "frame_at returns copied frame values" {
  let doc = motion_doc()
  let frame = @moonbvhkit.frame_at(doc, 1)
  assert_eq(frame.length(), 15)
  assert_eq(frame[0], 1.0)
  frame[0] = 99.0
  assert_eq(@moonbvhkit.frame_at(doc, 1)[0], 1.0)
}

///|
test "nearest frame by time uses frame time" {
  let doc = motion_doc()
  assert_eq(@moonbvhkit.nearest_frame_index_at_time(doc, 0.0), 0)
  assert_eq(@moonbvhkit.nearest_frame_index_at_time(doc, 0.07), 2)
  assert_eq(@moonbvhkit.frame_at_time(doc, 0.07)[0], 2.0)
}

///|
test "frame window describes clipped ranges" {
  let doc = motion_doc()
  let window = @moonbvhkit.frame_window(doc, 1, 3)
  assert_eq(window.start_frame, 1)
  assert_eq(window.end_frame, 3)
  assert_eq(window.frame_count, 2)
}

///|
test "slice motion and document preserve hierarchy" {
  let doc = motion_doc()
  let sliced = @moonbvhkit.slice_document(doc, 1, 3)
  assert_eq(sliced.root.name, "Hips")
  assert_eq(sliced.motion.frame_count, 2)
  assert_eq(sliced.motion.frames[0][0], 1.0)
}

///|
test "nearest resampling preserves first last and duration" {
  let source = motion_doc()
  let sampled = @moonbvhkit.resample_document_nearest(source, 2)
  assert_eq(sampled.root.name, "Hips")
  assert_eq(sampled.motion.frame_count, 2)
  assert_eq(sampled.motion.frames[0][0], 0.0)
  assert_eq(sampled.motion.frames[1][0], 3.0)
  assert_eq(sampled.duration_seconds(), source.duration_seconds())
}

///|
test "nearest resampling selects deterministic middle frames" {
  let sampled = @moonbvhkit.resample_document_nearest(motion_doc(), 3)
  assert_eq(sampled.motion.frames[0][0], 0.0)
  assert_eq(sampled.motion.frames[1][0], 2.0)
  assert_eq(sampled.motion.frames[2][0], 3.0)
}

///|
test "nearest resampling rejects non-positive target counts" {
  let sampled = @moonbvhkit.resample_document_nearest(motion_doc(), 0)
  assert_eq(sampled.motion.frame_count, 0)
  assert_eq(sampled.motion.frames.length(), 0)
}

///|
test "nearest resampling copies frame storage" {
  let source = motion_doc()
  let sampled = @moonbvhkit.resample_document_nearest(source, 2)
  sampled.motion.frames[0][0] = 99.0
  assert_eq(source.motion.frames[0][0], 0.0)
}

///|
test "first last and loop closure use root position" {
  let doc = motion_doc()
  assert_eq(@moonbvhkit.first_frame(doc)[0], 0.0)
  assert_eq(@moonbvhkit.last_frame(doc)[0], 3.0)
  assert_true(@moonbvhkit.loop_closure_error(doc) > 3.0)
}

///|
test "root motion bounds capture the full translation range" {
  let bounds = @moonbvhkit.root_motion_bounds(motion_doc())
  assert_eq(bounds.sample_count, 4)
  assert_eq(bounds.min_position.x, 0.0)
  assert_eq(bounds.max_position.x, 3.0)
  assert_eq(bounds.max_position.z, 0.6)
  assert_eq(bounds.size.x, 3.0)
  assert_eq(bounds.size.z, 0.6)
}

///|
test "root motion bounds handle empty documents" {
  let bounds = @moonbvhkit.root_motion_bounds(@moonbvhkit.BvhDocument::empty())
  assert_eq(bounds.sample_count, 0)
  assert_eq(bounds.size.x, 0.0)
  assert_eq(bounds.size.y, 0.0)
  assert_eq(bounds.size.z, 0.0)
}

///|
test "root motion bounds export JSON and CSV" {
  let bounds = @moonbvhkit.root_motion_bounds(motion_doc())
  let json = @moonbvhkit.root_motion_bounds_to_json(bounds)
  let csv = @moonbvhkit.root_motion_bounds_to_csv(bounds)
  assert_true(json.find("\"sampleCount\":4") != None)
  assert_true(json.find("\"size\":") != None)
  assert_true(csv.find("metric,x,y,z") != None)
  assert_true(csv.find("size,3") != None)
}

///|
test "root speed samples compute per-frame movement" {
  let doc = motion_doc()
  let samples = @moonbvhkit.root_speed_samples(doc)
  assert_eq(samples.length(), 3)
  assert_true(samples[0].distance_from_previous > 1.0)
  assert_true(@moonbvhkit.average_root_speed(doc) > 30.0)
  assert_true(@moonbvhkit.max_root_speed(doc) > 30.0)
}

///|
test "root teleport detector uses distance threshold" {
  let doc = motion_doc()
  assert_eq(@moonbvhkit.detect_root_teleports(doc, 10.0).length(), 0)
  assert_true(@moonbvhkit.detect_root_teleports(doc, 0.1).length() > 0)
}

///|
test "root origin normalization shifts first root to zero" {
  let doc = motion_doc()
  let normalized = @moonbvhkit.normalize_root_origin(doc)
  let first = @moonbvhkit.root_position_at(normalized, 0)
  let last = @moonbvhkit.root_position_at(normalized, 3)
  assert_eq(first.x, 0.0)
  assert_eq(first.z, 0.0)
  assert_eq(last.x, 3.0)
}

///|
test "channel means summarize motion columns" {
  let doc = motion_doc()
  let means = @moonbvhkit.motion_channel_means(doc)
  assert_eq(means.length(), 15)
  assert_eq(means[0].name, "Hips.Xposition")
  assert_eq(means[0].mean, 1.5)
}

///|
test "speed samples CSV exposes frame speed header" {
  let csv = @moonbvhkit.speed_samples_to_csv(
    @moonbvhkit.root_speed_samples(motion_doc()),
  )
  assert_true(csv.find("speed_units_per_second") != None)
}
