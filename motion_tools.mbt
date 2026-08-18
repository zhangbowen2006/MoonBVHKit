///|
pub(all) struct BvhFrameWindow {
  start_frame : Int
  end_frame : Int
  frame_count : Int
  duration_seconds : Double
} derive(Eq, @debug.Debug)

///|
pub fn BvhFrameWindow::new(
  start_frame : Int,
  end_frame : Int,
  frame_time : Double,
) -> BvhFrameWindow {
  let count = if end_frame > start_frame { end_frame - start_frame } else { 0 }
  {
    start_frame,
    end_frame,
    frame_count: count,
    duration_seconds: count.to_double() * frame_time,
  }
}

///|
pub fn clamp_frame_index(document : BvhDocument, frame_index : Int) -> Int {
  if document.motion.frames.length() == 0 {
    0
  } else if frame_index < 0 {
    0
  } else if frame_index >= document.motion.frames.length() {
    document.motion.frames.length() - 1
  } else {
    frame_index
  }
}

///|
pub fn frame_at(document : BvhDocument, frame_index : Int) -> Array[Double] {
  if document.motion.frames.length() == 0 {
    []
  } else {
    document.motion.frames[clamp_frame_index(document, frame_index)].copy()
  }
}

///|
pub fn nearest_frame_index_at_time(
  document : BvhDocument,
  seconds : Double,
) -> Int {
  if document.motion.frame_time <= 0.0 || document.motion.frames.length() == 0 {
    0
  } else {
    let raw = (seconds / document.motion.frame_time).round().to_int()
    clamp_frame_index(document, raw)
  }
}

///|
pub fn frame_at_time(document : BvhDocument, seconds : Double) -> Array[Double] {
  frame_at(document, nearest_frame_index_at_time(document, seconds))
}

///|
pub fn frame_window(
  document : BvhDocument,
  start_frame : Int,
  end_frame : Int,
) -> BvhFrameWindow {
  let start = clamp_frame_index(document, start_frame)
  let raw_end = if end_frame < start {
    start
  } else if end_frame > document.motion.frames.length() {
    document.motion.frames.length()
  } else {
    end_frame
  }
  BvhFrameWindow::new(start, raw_end, document.motion.frame_time)
}

///|
pub fn slice_motion(
  motion : BvhMotion,
  start_frame : Int,
  end_frame : Int,
) -> BvhMotion {
  if motion.frames.length() == 0 {
    BvhMotion::empty()
  } else {
    let start = if start_frame < 0 { 0 } else { start_frame }
    let end = if end_frame < start {
      start
    } else if end_frame > motion.frames.length() {
      motion.frames.length()
    } else {
      end_frame
    }
    let frames : Array[Array[Double]] = []
    for i in start..<end {
      frames.push(motion.frames[i].copy())
    }
    {
      frame_count: frames.length(),
      frame_time: motion.frame_time,
      channel_count: motion.channel_count,
      frames,
    }
  }
}

///|
pub fn slice_document(
  document : BvhDocument,
  start_frame : Int,
  end_frame : Int,
) -> BvhDocument {
  {
    root: document.root,
    motion: slice_motion(document.motion, start_frame, end_frame),
    source_length: document.source_length,
    token_count: document.token_count,
  }
}

///|
pub fn first_frame(document : BvhDocument) -> Array[Double] {
  frame_at(document, 0)
}

///|
pub fn last_frame(document : BvhDocument) -> Array[Double] {
  frame_at(document, document.motion.frames.length() - 1)
}

///|
pub fn loop_closure_error(document : BvhDocument) -> Double {
  if document.motion.frames.length() <= 1 {
    0.0
  } else {
    root_position_at(document, document.motion.frames.length() - 1)
    .sub(root_position_at(document, 0))
    .magnitude()
  }
}

///|
pub(all) struct BvhSpeedSample {
  frame_index : Int
  seconds : Double
  distance_from_previous : Double
  speed_units_per_second : Double
} derive(Eq, @debug.Debug)

///|
pub fn BvhSpeedSample::new(
  frame_index : Int,
  seconds : Double,
  distance_from_previous : Double,
  speed_units_per_second : Double,
) -> BvhSpeedSample {
  { frame_index, seconds, distance_from_previous, speed_units_per_second }
}

///|
pub fn root_speed_samples(document : BvhDocument) -> Array[BvhSpeedSample] {
  let out : Array[BvhSpeedSample] = []
  if document.motion.frames.length() <= 1 || document.motion.frame_time <= 0.0 {
    return out
  }
  for i in 1..<document.motion.frames.length() {
    let distance = root_position_at(document, i)
      .sub(root_position_at(document, i - 1))
      .magnitude()
    out.push(
      BvhSpeedSample::new(
        i,
        i.to_double() * document.motion.frame_time,
        distance,
        distance / document.motion.frame_time,
      ),
    )
  }
  out
}

///|
pub fn average_root_speed(document : BvhDocument) -> Double {
  let samples = root_speed_samples(document)
  if samples.length() == 0 {
    0.0
  } else {
    let total = for sample in samples; sum = 0.0 {
      continue sum + sample.speed_units_per_second
    } nobreak {
      sum
    }
    total / samples.length().to_double()
  }
}

///|
pub fn max_root_speed(document : BvhDocument) -> Double {
  let samples = root_speed_samples(document)
  if samples.length() == 0 {
    0.0
  } else {
    for sample in samples; speed = samples[0].speed_units_per_second {
      continue max_double(speed, sample.speed_units_per_second)
    } nobreak {
      speed
    }
  }
}

///|
pub(all) struct BvhRootTeleport {
  frame_index : Int
  distance : Double
  threshold : Double
} derive(Eq, @debug.Debug)

///|
pub fn BvhRootTeleport::new(
  frame_index : Int,
  distance : Double,
  threshold : Double,
) -> BvhRootTeleport {
  { frame_index, distance, threshold }
}

///|
pub fn detect_root_teleports(
  document : BvhDocument,
  threshold : Double,
) -> Array[BvhRootTeleport] {
  let out : Array[BvhRootTeleport] = []
  if threshold <= 0.0 {
    return out
  }
  for sample in root_speed_samples(document) {
    if sample.distance_from_previous > threshold {
      out.push(
        BvhRootTeleport::new(
          sample.frame_index,
          sample.distance_from_previous,
          threshold,
        ),
      )
    }
  }
  out
}

///|
fn copy_frame_with_root_offset(
  frame : Array[Double],
  x_index : Int,
  y_index : Int,
  z_index : Int,
  first : BvhVec3,
) -> Array[Double] {
  let out = frame.copy()
  if x_index >= 0 && x_index < out.length() {
    out[x_index] = out[x_index] - first.x
  }
  if y_index >= 0 && y_index < out.length() {
    out[y_index] = out[y_index] - first.y
  }
  if z_index >= 0 && z_index < out.length() {
    out[z_index] = out[z_index] - first.z
  }
  out
}

///|
pub fn normalize_root_origin(document : BvhDocument) -> BvhDocument {
  if document.motion.frames.length() == 0 {
    document
  } else {
    let first = root_position_at(document, 0)
    let x_index = channel_index_for_path(
      document,
      document.root.path,
      ChannelXPosition,
    )
    let y_index = channel_index_for_path(
      document,
      document.root.path,
      ChannelYPosition,
    )
    let z_index = channel_index_for_path(
      document,
      document.root.path,
      ChannelZPosition,
    )
    let frames : Array[Array[Double]] = []
    for frame in document.motion.frames {
      frames.push(
        copy_frame_with_root_offset(frame, x_index, y_index, z_index, first),
      )
    }
    {
      root: document.root,
      motion: {
        frame_count: document.motion.frame_count,
        frame_time: document.motion.frame_time,
        channel_count: document.motion.channel_count,
        frames,
      },
      source_length: document.source_length,
      token_count: document.token_count,
    }
  }
}

///|
pub(all) struct BvhChannelMean {
  index : Int
  name : String
  mean : Double
  sample_count : Int
} derive(Eq, @debug.Debug)

///|
pub fn BvhChannelMean::new(
  index : Int,
  name : String,
  mean : Double,
  sample_count : Int,
) -> BvhChannelMean {
  { index, name, mean, sample_count }
}

///|
pub fn motion_channel_means(document : BvhDocument) -> Array[BvhChannelMean] {
  let out : Array[BvhChannelMean] = []
  let names = channels_in_motion_order(document)
  if document.motion.channel_count == 0 || document.motion.frames.length() == 0 {
    return out
  }
  for index in 0..<document.motion.channel_count {
    let sum = for frame in document.motion.frames; acc = 0.0 {
      if index < frame.length() {
        continue acc + frame[index]
      } else {
        continue acc
      }
    } nobreak {
      acc
    }
    let name = if index < names.length() {
      names[index]
    } else {
      "channel-\{index}"
    }
    out.push(
      BvhChannelMean::new(
        index,
        name,
        sum / document.motion.frames.length().to_double(),
        document.motion.frames.length(),
      ),
    )
  }
  out
}

///|
pub fn speed_samples_to_csv(samples : Array[BvhSpeedSample]) -> String {
  let rows : Array[String] = [
    "frame,seconds,distance_from_previous,speed_units_per_second",
  ]
  for sample in samples {
    rows.push(
      "\{sample.frame_index},\{sample.seconds},\{sample.distance_from_previous},\{sample.speed_units_per_second}",
    )
  }
  rows.join("\n")
}
