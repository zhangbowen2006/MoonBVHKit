///|
fn main {
  let parsed = @moonbvhkit.parse_bvh(@moonbvhkit.fixture_walk_bvh())
  if !parsed.ok {
    println("parse failed: \{parsed.error.code()}")
  } else {
    let doc = parsed.document
    let stats = @moonbvhkit.analyze_bvh(doc)
    let validation = @moonbvhkit.validate_document(doc)
    println("MoonBVHKit basic example")
    println("summary=\{@moonbvhkit.bvh_summary_line(doc)}")
    println("validation=\{@moonbvhkit.validation_summary(validation)}")
    println("joints=\{stats.joint_count}")
    println("channels=\{stats.channel_count}")
    println("duration_seconds=\{stats.duration_seconds}")
    println("root_delta=\{@moonbvhkit.root_motion_delta(doc).to_csv()}")
  }
}
