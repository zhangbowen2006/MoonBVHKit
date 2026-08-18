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
