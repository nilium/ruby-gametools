require 'opengl-core'
require 'opengl-core/aux'
require 'stb-image'

module GT ; end

class GT::Texture < Gl::Texture

  #
  # call-seq:
  #   new(file-path, mipmapped = false)
  #
  #
  def initialize(*argv)
    if argv.empty?
      super()
      return
    end

    case argv[0]
    when String
      super(Gl::GL_TEXTURE_2D)

      path, mipmaps = argv
      min_filter = mipmaps ? Gl::GL_LINEAR_MIPMAP_LINEAR : Gl::GL_LINEAR

      loaded = open(path, 'r') do |io|
        STBI.load_image(io) do |data, width, height, components|

          format = case components
                   when 1 then Gl::GL_RED
                   when 2 then Gl::GL_RG
                   when 3 then Gl::GL_RGB
                   when 4 then Gl::GL_RGBA
                   else raise "Invalid number of components"
                   end

          bind(min_filter: min_filter,
               mag_filter: Gl::GL_LINEAR,
               x_wrap: Gl::GL_REPEAT,
               y_wrap: Gl::GL_REPEAT)

          glTexImage2D(Gl::GL_TEXTURE_2D, 0, format, width, height, 0, format,
            Gl::GL_UNSIGNED_BYTE, data)

          true
        end
      end

      raise "Unable to load image at #{argv[0]}" unless loaded

    else
      super(*argv)
    end
  end

  def bind(target = nil,
           min_filter: nil,
           mag_filter: nil,
           x_wrap: nil,
           y_wrap: nil,
           z_wrap: nil)

    super(target ||= self.target)

    # Optionally change the texture's filter parameters
    Gl::glTexParameteri(target, Gl::GL_TEXTURE_MIN_FILTER, min_filter) if min_filter
    Gl::glTexParameteri(target, Gl::GL_TEXTURE_MAG_FILTER, mag_filter) if mag_filter

    # Optionally change the texture's wrapping parameters
    case target
    when Gl::GL_TEXTURE_1D, Gl::GL_PROXY_TEXTURE_1D
      Gl::glTexParameteri(target, Gl::GL_TEXTURE_WRAP_S, x_wrap) if x_wrap
    when Gl::GL_TEXTURE_3D, Gl::GL_PROXY_TEXTURE_3D
      Gl::glTexParameteri(target, Gl::GL_TEXTURE_WRAP_S, x_wrap) if x_wrap
      Gl::glTexParameteri(target, Gl::GL_TEXTURE_WRAP_T, y_wrap) if y_wrap
      Gl::glTexParameteri(target, Gl::GL_TEXTURE_WRAP_R, z_wrap) if z_wrap
    else # 2D, cubemap faces, and otherwise
      Gl::glTexParameteri(target, Gl::GL_TEXTURE_WRAP_S, x_wrap) if x_wrap
      Gl::glTexParameteri(target, Gl::GL_TEXTURE_WRAP_T, y_wrap) if y_wrap
    end

  end

end
