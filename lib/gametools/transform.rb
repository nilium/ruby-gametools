require 'snow-math'
require 'gametools/cache'

module GT ; end

class GT::Transform

  def initialize
    @transform       = Snow::Mat4.new
    @transform_dirty = false
    @translation     = Snow::Vec3.new(0, 0, 0)
    @scale           = Snow::Vec3.new(1, 1, 1)
    @rotation        = Snow::Mat3.new
  end

  def transform
    if @transform_dirty
      tform = Mat4::translation(@translation, @transform)
      tform.scale(*@scale, tform)
      tform.multiply_mat4(@rotation.to_mat4, tform)
    end
    @transform
  end

  def to_p
    self.transform.to_p
  end

  # Applies movement relative to the transform's rotation
  def move(movement)
    @translation.add!(@rotation.rotate_vec3(movement))
    @transform_dirty = true
    self
  end

  # Applies translation
  def translate(translation)
    @translation.add!(translation)
    @transform_dirty = true
    self
  end

  # Applies scaling
  def scale_by(scaling)
    @scale.multiply!(scaling)
    @transform_dirty = true
    self
  end

  # Applies a rotation
  def rotate(rotation)
    case rotation
    when ::Snow::Mat3 then @rotation.multiply_mat3!(rotation)
    when ::Snow::Quat then @rotation.multiply_mat3!(rotation.to_mat3)
    when ::Snow::Vec3, Array
      @rotation =
        ::Snow::Mat3.angle_axis(self.yaw + rotation[1], ::Snow::Vec3::POS_Y) *
        ::Snow::Mat3.angle_axis(self.pitch + rotation[0], ::Snow::Vec3::POS_X) *
        ::Snow::Mat3.angle_axis(self.roll + rotation[2], ::Snow::Vec3::POS_Z)
    else raise TypeError, "Invalid type of rotation"
    end
    @transform_dirty = true
    self
  end

  # Sets current translation to the Vec3 translation
  def translation=(translation)
    @translation.set(translation)
    @transform_dirty = true
    translation
  end

  def translation(out = nil)
    @translation.copy(out)
  end

  # Sets current scale to the Vec3 scaling
  def scale=(scaling)
    @scale.set(scaling)
    @transform_dirty = true
    scaling
  end

  # Returns a Vec3
  def scale(out = nil)
    @scale.copy(out)
  end

  def rotation=(rotation)
    case rotation
    when ::Snow::Mat3, ::Snow::Quat
      @rotation.set(rotation)
    when ::Snow::Vec3, Array
      rotation_y  = Snow::Mat3.angle_axis(rotation[1], Snow::Vec3::POS_Y) # yaw
      rotation_x  = Snow::Mat3.angle_axis(rotation[0], Snow::Vec3::POS_X) # pitch
      rotation_yx = rotation_y.multiply_quat(rotation_x, rotation_x) # yaw * pitch
      rotation_z  = Snow::Mat3.angle_axis(rotation[2], Snow::Vec3::POS_Z, rotation_y) # roll
      @rotation   = result.multiply_quat(rotation_z, @rotation) # (yaw * pitch) * roll
    else raise TypeError, "Invalid type of rotation"
    end
    @transform_dirty = true
    rotation
  end

  # Returns a Quat
  def rotation(out = nil)
    @rotation.copy(out)
  end

  def pitch
    @rotation.pitch
  end

  def yaw
    @rotation.yaw
  end

  def roll
    @rotation.roll
  end

  def pitch=(new_pitch)
    self.rotation = Snow::Vec3[new_pitch, self.yaw, self.roll]
    new_pitch
  end

  def yaw=(new_yaw)
    self.rotation = Snow::Vec3[self.pitch, new_yaw, self.roll]
    new_yaw
  end

  def roll=(new_roll)
    self.rotation = Snow::Vec3[self.pitch, self.yaw, new_roll]
    new_roll
  end

end