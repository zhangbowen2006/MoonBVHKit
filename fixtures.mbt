///|
pub fn fixture_walk_bvh() -> String {
  let text =
    #|HIERARCHY
    #|ROOT Hips
    #|{
    #|  OFFSET 0.0 0.0 0.0
    #|  CHANNELS 6 Xposition Yposition Zposition Zrotation Xrotation Yrotation
    #|  JOINT Spine
    #|  {
    #|    OFFSET 0.0 10.0 0.0
    #|    CHANNELS 3 Zrotation Xrotation Yrotation
    #|    JOINT Head
    #|    {
    #|      OFFSET 0.0 8.0 0.0
    #|      CHANNELS 3 Zrotation Xrotation Yrotation
    #|      End Site
    #|      {
    #|        OFFSET 0.0 4.0 0.0
    #|      }
    #|    }
    #|  }
    #|  JOINT LeftArm
    #|  {
    #|    OFFSET -4.0 8.0 0.0
    #|    CHANNELS 3 Zrotation Xrotation Yrotation
    #|    End Site
    #|    {
    #|      OFFSET -8.0 0.0 0.0
    #|    }
    #|  }
    #|}
    #|MOTION
    #|Frames: 4
    #|Frame Time: 0.0333333
    #|0.0 0.0 0.0 0.0 0.0 0.0 5.0 0.0 0.0 0.0 2.0 0.0 -5.0 0.0 0.0
    #|1.0 0.0 0.2 1.0 0.5 0.0 5.5 1.0 0.0 0.0 2.5 0.5 -5.5 0.0 0.0
    #|2.0 0.0 0.4 2.0 1.0 0.0 6.0 2.0 0.0 0.0 3.0 1.0 -6.0 0.0 0.0
    #|3.0 0.0 0.6 3.0 1.5 0.0 6.5 3.0 0.0 0.0 3.5 1.5 -6.5 0.0 0.0
  text
}

///|
pub fn fixture_static_pose_bvh() -> String {
  let text =
    #|HIERARCHY
    #|ROOT Root
    #|{
    #|  OFFSET 0 0 0
    #|  CHANNELS 6 Xposition Yposition Zposition Zrotation Xrotation Yrotation
    #|  JOINT Bone
    #|  {
    #|    OFFSET 0 1 0
    #|    CHANNELS 3 Zrotation Xrotation Yrotation
    #|    End Site
    #|    {
    #|      OFFSET 0 1 0
    #|    }
    #|  }
    #|}
    #|MOTION
    #|Frames: 2
    #|Frame Time: 0.0416667
    #|0 0 0 0 0 0 0 0 0
    #|0 0 0 0 0 0 0 0 0
  text
}

///|
pub fn fixture_invalid_missing_motion() -> String {
  let text =
    #|HIERARCHY
    #|ROOT Hips
    #|{
    #|  OFFSET 0 0 0
    #|  CHANNELS 6 Xposition Yposition Zposition Zrotation Xrotation Yrotation
    #|}
  text
}

///|
pub fn fixture_invalid_frame_width() -> String {
  let text =
    #|HIERARCHY
    #|ROOT Hips
    #|{
    #|  OFFSET 0 0 0
    #|  CHANNELS 6 Xposition Yposition Zposition Zrotation Xrotation Yrotation
    #|}
    #|MOTION
    #|Frames: 1
    #|Frame Time: 0.0333333
    #|0 0 0
  text
}

///|
pub fn fixture_unknown_channel() -> String {
  let text =
    #|HIERARCHY
    #|ROOT Hips
    #|{
    #|  OFFSET 0 0 0
    #|  CHANNELS 1 ScaleX
    #|}
    #|MOTION
    #|Frames: 1
    #|Frame Time: 0.0333333
    #|1
  text
}

///|
pub fn fixture_empty_bvh() -> String {
  "   \n\t"
}
