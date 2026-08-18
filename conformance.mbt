///|
pub(all) struct BvhSupportEntry {
  feature : String
  status : String
  notes : String
} derive(Eq, @debug.Debug)

///|
pub fn BvhSupportEntry::new(
  feature : String,
  status : String,
  notes : String,
) -> BvhSupportEntry {
  { feature, status, notes }
}

///|
pub(all) struct BvhRuntimeManifest {
  package_name : String
  version : String
  supported_format : String
  entries : Array[BvhSupportEntry]
} derive(Eq, @debug.Debug)

///|
pub fn bvh_runtime_manifest() -> BvhRuntimeManifest {
  {
    package_name: "zhangbowen2006/moonbvhkit",
    version: "0.1.0",
    supported_format: "ASCII BVH hierarchy and motion data",
    entries: [
      BvhSupportEntry::new(
        "HIERARCHY ROOT/JOINT/End Site", "supported", "nested skeleton tree with offsets",
      ),
      BvhSupportEntry::new(
        "CHANNELS", "supported", "standard position and rotation channels",
      ),
      BvhSupportEntry::new(
        "MOTION frames", "supported", "fixed-width Double frame arrays",
      ),
      BvhSupportEntry::new(
        "Validation report", "supported", "frame width, channel offsets, unknown channels",
      ),
      BvhSupportEntry::new(
        "Unity plan", "supported", "metadata manifest, not an Editor plugin",
      ),
      BvhSupportEntry::new(
        "Blender plan", "supported", "import guidance manifest, not a Python addon",
      ),
      BvhSupportEntry::new(
        "Binary BVH variants", "not-supported", "v1 stays focused on portable ASCII BVH",
      ),
    ],
  }
}

///|
pub fn manifest_to_text(manifest : BvhRuntimeManifest) -> String {
  let lines : Array[String] = [
    "\{manifest.package_name} \{manifest.version}",
    "format=\{manifest.supported_format}",
  ]
  for entry in manifest.entries {
    lines.push("- \{entry.feature}: \{entry.status}; \{entry.notes}")
  }
  lines.join("\n")
}

///|
pub fn manifest_to_json(manifest : BvhRuntimeManifest) -> String {
  let entries : Array[String] = []
  for entry in manifest.entries {
    let row =
      $|{"feature":\{json_string(entry.feature)},"status":\{json_string(entry.status)},"notes":\{json_string(entry.notes)}}
    entries.push(row)
  }
  let result =
    $|{"packageName":\{json_string(manifest.package_name)},"version":\{json_string(manifest.version)},"supportedFormat":\{json_string(manifest.supported_format)},"entries":[\{entries.join(",")}]}
  result
}
