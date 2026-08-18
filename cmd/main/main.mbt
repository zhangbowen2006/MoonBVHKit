///|
fn output_format(args : Array[String]) -> @moonbvhkit.BvhReportFormat {
  for arg in args {
    if arg == "--json" || arg == "-j" {
      break @moonbvhkit.ReportJson
    } else if arg == "--csv" {
      break @moonbvhkit.ReportCsv
    }
  } nobreak {
    @moonbvhkit.ReportText
  }
}

///|
fn has_arg(args : Array[String], wanted : String) -> Bool {
  for arg in args {
    if arg == wanted {
      break true
    }
  } nobreak {
    false
  }
}

///|
fn arg_value_after(
  args : Array[String],
  long_flag : String,
  short_flag : String,
  default : String,
) -> String {
  for i in 0..<args.length() {
    if (args[i] == long_flag || args[i] == short_flag) && i + 1 < args.length() {
      break args[i + 1]
    }
  } nobreak {
    default
  }
}

///|
fn int_arg_after(
  args : Array[String],
  long_flag : String,
  short_flag : String,
  default : Int,
) -> Int {
  let raw = arg_value_after(args, long_flag, short_flag, "\{default}")
  @string.parse_int(raw) catch {
    _ => default
  }
}

///|
fn resample_target(args : Array[String]) -> Int {
  let target = int_arg_after(args, "--resample", "-r", 8)
  if target < 1 {
    1
  } else {
    target
  }
}

///|
fn fixture_document() -> @moonbvhkit.BvhDocument {
  @moonbvhkit.parse_bvh_or_empty(@moonbvhkit.fixture_walk_bvh())
}

///|
fn decisions_to_json(
  decisions : Array[@moonbvhkit.BvhImportDecision],
) -> String {
  let rows : Array[String] = []
  for decision in decisions {
    rows.push(@moonbvhkit.import_decision_to_json(decision))
  }
  "[" + rows.join(",") + "]"
}

///|
fn decisions_to_text(
  decisions : Array[@moonbvhkit.BvhImportDecision],
) -> String {
  let rows : Array[String] = []
  for decision in decisions {
    rows.push(@moonbvhkit.import_decision_to_text(decision))
  }
  rows.join("\n\n")
}

///|
fn print_quality(args : Array[String]) -> Unit {
  let report = @moonbvhkit.quality_report(fixture_document())
  match output_format(args) {
    @moonbvhkit.ReportJson =>
      println(@moonbvhkit.quality_report_to_json(report))
    @moonbvhkit.ReportCsv => println(@moonbvhkit.quality_report_to_csv(report))
    @moonbvhkit.ReportText =>
      println(@moonbvhkit.quality_report_to_text(report))
  }
}

///|
fn print_profiles(args : Array[String]) -> Unit {
  let decisions = @moonbvhkit.evaluate_default_import_profiles(
    fixture_document(),
  )
  match output_format(args) {
    @moonbvhkit.ReportJson => println(decisions_to_json(decisions))
    @moonbvhkit.ReportCsv =>
      println(@moonbvhkit.import_decisions_to_csv(decisions))
    @moonbvhkit.ReportText => println(decisions_to_text(decisions))
  }
}

///|
fn print_profile(args : Array[String]) -> Unit {
  let profile = @moonbvhkit.import_profile_by_name(
    arg_value_after(args, "--profile", "-p", "unity"),
  )
  let decision = @moonbvhkit.evaluate_import_profile(
    fixture_document(),
    profile,
  )
  match output_format(args) {
    @moonbvhkit.ReportJson =>
      println(@moonbvhkit.import_decision_to_json(decision))
    @moonbvhkit.ReportCsv =>
      println(@moonbvhkit.import_decisions_to_csv([decision]))
    @moonbvhkit.ReportText =>
      println(@moonbvhkit.import_decision_to_text(decision))
  }
}

///|
fn print_bounds(args : Array[String]) -> Unit {
  let bounds = @moonbvhkit.root_motion_bounds(fixture_document())
  match output_format(args) {
    @moonbvhkit.ReportJson =>
      println(@moonbvhkit.root_motion_bounds_to_json(bounds))
    @moonbvhkit.ReportCsv =>
      println(@moonbvhkit.root_motion_bounds_to_csv(bounds))
    @moonbvhkit.ReportText =>
      println(
        (
          #|root motion bounds
          #|samples=\{bounds.sample_count}
          #|min=\{bounds.min_position.to_csv()}
          #|max=\{bounds.max_position.to_csv()}
          #|size=\{bounds.size.to_csv()}
        ),
      )
  }
}

///|
fn print_resampled(args : Array[String]) -> Unit {
  let target = resample_target(args)
  let document = @moonbvhkit.resample_document_nearest(
    fixture_document(),
    target,
  )
  match output_format(args) {
    @moonbvhkit.ReportJson => println(@moonbvhkit.document_to_json(document))
    @moonbvhkit.ReportCsv => println(@moonbvhkit.root_motion_csv(document))
    @moonbvhkit.ReportText =>
      println(
        "resampled_frames=\{target}\n\{@moonbvhkit.bvh_summary_line(document)}",
      )
  }
}

///|
fn fixture_batch_report(
  args : Array[String],
) -> @moonbvhkit.BvhBatchImportReport {
  let profile = @moonbvhkit.import_profile_by_name(
    arg_value_after(args, "--profile", "-p", "strict-ci"),
  )
  @moonbvhkit.evaluate_bvh_batch(
    [
      @moonbvhkit.BvhNamedAsset::new("walk", @moonbvhkit.fixture_walk_bvh()),
      @moonbvhkit.BvhNamedAsset::new(
        "static-pose",
        @moonbvhkit.fixture_static_pose_bvh(),
      ),
      @moonbvhkit.BvhNamedAsset::new(
        "broken-frame-width",
        @moonbvhkit.fixture_invalid_frame_width(),
      ),
    ],
    profile,
  )
}

///|
fn batch_report_to_text(report : @moonbvhkit.BvhBatchImportReport) -> String {
  let rows : Array[String] = [
    "profile=\{report.profile_name}",
    "assets=\{report.asset_count}",
    "accepted=\{report.accepted_count}",
    "blocked=\{report.blocked_count}",
  ]
  for asset in report.assets {
    rows.push(
      "- \{asset.asset_name}: \{asset.decision.action} (score=\{asset.decision.quality.score})",
    )
  }
  rows.join("\n")
}

///|
fn print_batch(args : Array[String]) -> Unit {
  let report = fixture_batch_report(args)
  match output_format(args) {
    @moonbvhkit.ReportJson =>
      println(@moonbvhkit.batch_import_report_to_json(report))
    @moonbvhkit.ReportCsv =>
      println(@moonbvhkit.batch_import_report_to_csv(report))
    @moonbvhkit.ReportText => println(batch_report_to_text(report))
  }
}

///|
fn print_junit() -> Unit {
  println(
    @moonbvhkit.quality_report_to_junit_xml(
      @moonbvhkit.quality_report(fixture_document()),
      suite_name="moonbvhkit-cli-fixture",
    ),
  )
}

///|
fn print_help() -> Unit {
  println(
    (
      #|MoonBVHKit CLI
      #|
      #|Usage:
      #|  moon run cmd/main
      #|  moon run cmd/main -- --json
      #|  moon run cmd/main -- --csv
      #|  moon run cmd/main -- --quality [--json|--csv]
      #|  moon run cmd/main -- --profile unity [--json|--csv]
      #|  moon run cmd/main -- --profiles [--json|--csv]
      #|  moon run cmd/main -- --bounds [--json|--csv]
      #|  moon run cmd/main -- --resample 12 [--json|--csv]
      #|  moon run cmd/main -- --batch [--profile strict-ci] [--json|--csv]
      #|  moon run cmd/main -- --junit
      #|
      #|Profiles: unity, blender, strict-ci, preview
      #|
    ),
  )
}

///|
fn main {
  let args = @env.args()
  if has_arg(args, "--help") || has_arg(args, "-h") {
    print_help()
  } else if has_arg(args, "--junit") {
    print_junit()
  } else if has_arg(args, "--bounds") {
    print_bounds(args)
  } else if has_arg(args, "--resample") || has_arg(args, "-r") {
    print_resampled(args)
  } else if has_arg(args, "--batch") {
    print_batch(args)
  } else if has_arg(args, "--quality") {
    print_quality(args)
  } else if has_arg(args, "--profiles") {
    print_profiles(args)
  } else if has_arg(args, "--profile") || has_arg(args, "-p") {
    print_profile(args)
  } else {
    println(@moonbvhkit.bvh_fixture_report(format=output_format(args)))
  }
}
