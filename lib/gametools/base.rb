require 'glfw3'

module GT ; end

#
# Class representation of a base game's initialization and main loop. Includes
# overridable methods to handle game / frame logic and rendition, including:
#
# [init]            Called on initialization. By default, sets up GLFW event
#                   callbacks. Any subclass implementation should call its
#                   superclass implementation to ensure callbacks are set up.
#
# [terminate]       Called once the loop ends. By default, this is not
#                   implemented.
#
# [event]           Called when an event is received with named parameters. By
#                   default, this method is not implemented.
#
#                   A typical implementation might look like this, if one wanted
#                   to cover most named arguments:
#
#                     def event(sender, kind,
#                               x: nil, y: nil, # window_position, window_size, cursor_position,
#                                               # framebuffer_size, scroll
#                               focused: nil,   # window_focus
#                               iconified: nil, # window_iconify
#                               entered: nil,   # cursor_enter
#                               action: nil,    # mouse, key
#                               button: nil,    # mouse, key
#                               scancode: nil,  # key
#                               mods: nil,      # mouse, key
#                               char: nil,      # char
#                               **args)
#                       # ...
#                     end
#
#                   Though, in reality, it is sufficient to only provide the
#                   sender and kind arguments and collect any remaining named
#                   arguments in a Hash.
#
# [pre_frame]       Logic handled before frame updates happen. By default, this
#                   method is unimplemented. It is called after event polling.
#
# [fixed_frame]     Frame logic -- run in a fixed-step loop. Unimplemented by
#                   default.
#
# [pre_rendition]   Anything that must occur before rendition. Similarly, there
#                   is also post_rendition for anything that must happen after
#                   rendition. By default, this is unimplemented.
#
# [rendition]       Rendition. Unimplemented by default.
#
# [post_rendition]  Anything that must occur after rendition. Unimplemented by
#                   default.
#
# Except for the event method, none of these functions takes any arguments.
#
#
# === Event Kinds
#
# The event method is always provided with the sender and kind of event being
# sent, in addition to any number of named arguments in any order. As a result,
# it's a good idea to define those named arguments you would like and accept
# any additional arguments via a Hash.
#
# The events provided by a Glfw window and their arguments are as follows:
#
# [:refresh]          Sent when a window is going to be redrawn. Has no
#                     arguments. Sender is the window whose contents are going
#                     to be redrawn.
#
# [:window_close]     Sent when the user attempts to close a window. Has no
#                     arguments. Sender is the window the user attempted to
#                     close.
#
# [:window_position]  Sent when a window is moved. Has x and y named arguments.
#                     Sender is the moved window.
#
# [:window_size]      Sent when a window is resized. Has x and y named
#                     arguments. Sender is the resized window.
#
# [:framebuffer_size] Sent when a window's framebuffer is resized. Has x and y
#                     named arguments. Sender is the window whose
#                     framebuffer was resized.
#
# [:window_iconify]   Sent when a window is iconified (e.g., minimized). Has a
#                     named argument, iconify, that is a boolean value for
#                     whether the window was iconified (if false, the window
#                     was de-iconified or restored or whatever term you like).
#                     Sender is the iconified window.
#
# [:window_focus]     Sent when a window's focus is changed. Has a named
#                     argument, focused, for whether the window lost (false) or
#                     gained (true) focus. Sender is the focused window.
#
# [:cursor_position]  Called when the cursor's position changes. Has x and y
#                     named argument. Sender is the currently focused window.
#
# [:cursor_enter]     Sent when a cursor enters a window. Has a named argument,
#                     entered, for whether the cursor entered (true)
#                     or left (false) the window. Sender is the window the
#                     cursor entered or left.
#
# [:mouse]            Sent when a mouse button is pressed or released in a
#                     window. Has named arguments button, action, and mods.
#                     action is either of Glfw::PRESSED or Glfw::RELEASED.
#                     mods is an or'd combination of Glfw modifier key flags.
#                     Sender is the window the mouse button was pressed in.
#
# [:scroll]           Sent for mouse wheel scrolling in a window. Has x and y
#                     named arguments for the scrolling deltas. Sender is the
#                     window the mouse scrolling occurred in.
#
# [:key]              Sent when a keyboard key is pressed, released, or when a
#                     key is repeated. Has button, scancode, action, and mods
#                     named arguments. action is one of Glfw::PRESSED,
#                     Glfw::REPEAT, or Glfw::RELEASED for when a key is pressed,
#                     repeated, or released. scancode is the actual scancode of
#                     the key, whereas button is the button that corresponds to
#                     a Glfw keyboard button constant. mods is an or'd
#                     combination of Glfw modifier key flags. Sender is the
#                     window the keyboard events happened in, typically the
#                     focused window.
#
# [:char]             Sent when a keyboard key is pressed. Has a named argument,
#                     char, which is the integer character for the key pressed.
#                     The value of this depends on the OS. The sender is the
#                     window the event happened in, typically the focused
#                     window.
#
# === Frames Per Second & Rendition
#
# The default frames_per_second is 60, though can be changed by setting any
# other value appropriate for the game (depending on the game, it may not be
# necessary to run at 60 FPS).
#
# frames_per_second refers to the logic updates, not rendition, which is done
# as often as possible depending on the GLFW swap interval. Nothing in the loop
# works to limit rendition.
#
class GT::Base

  # The main window assigned to the loop. Must be set before calling #run.
  # Additional windows can be hooked up to receive events by passing them to
  # the #hook_window method.
  attr_accessor :window

  # Whether the loop is running. To exit the loop, set this to false -- this is
  # the only way to exit the loop.
  attr_accessor :running
  # The frames per second of the loop. This can only be modified when the loop
  # isn't running.
  attr_accessor :frames_per_second
  # Read-only attribute for getting the frame hertz for the loop's frames per
  # second. This is simply 1000.0 / frames_per_second.
  attr_reader :frame_hertz
  # Gets the current simulation time. This increments in frame_hertz steps and
  # is used for the fixed-step frameloop.
  attr_reader :simulation_time
  # The current frame time. This is the beginning time for the current frameloop
  # and does not change during the frameloop. It is not typically very useful.
  # If you need a frame time to use, it's better to call Glfw::time and subtract
  # the base_time from it.
  attr_reader :frame_time
  # The base time of the game loop. This is set when #run is called and is used
  # as the base time for the game loop. To determine an accurate time in
  # relation to either the simulation_time or frame_time, take the difference
  # of Glfw::time and base_time. For example:
  #
  #   current_time = Glfw.time - gameloop.base_time
  #
  attr_reader :base_time


  #
  # Allocates a new GameLoop object. Must be given a Glfw window before #run
  # can be called.
  #
  def initialize
    self.frames_per_second    = 60.0
    @__running = self.running = false
    @simulation_time          = 0.0
    @frame_time               = 0.0
  end

  #
  # call-seq:
  #     frames_per_second = new_fps => new_fps
  #
  # Sets the loop's frames per second and updates the frame_hertz for the loop.
  #
  def frames_per_second=(new_fps)
    raise "Cannot change FPS while running" if @__running
    @fps = new_fps
    @frame_hertz = 1000.0 / @fps.to_f
    new_fps
  end

  #
  # Called before the loop is run to initialize anything. By default, this calls
  # hook_window with the loop's window. Subclasses should call the superclass
  # method if implementing it as well.
  #
  def init
    raise "No window provided" unless @window
    hook_window @window
  end

  #
  # Hooks a window up to the GameLoop so that the window's events will be sent
  # to the GameLoop via event(..) if implemented.
  #
  def hook_window(window)
    loop_self = self
    window.refresh_callback = ->(window) {
      if loop_self.respond_to? :event
        forward = event window, :refresh
      end
    }
    window.close_callback = ->(window) {
      if loop_self.respond_to? :event
        forward = event window, :window_close
      end
    }

    window.position_callback = ->(window, x, y) {
      if loop_self.respond_to? :event
        forward = event window, :window_position, x: x, y: y
      end
    }

    window.size_callback = ->(window, x, y) {
      if loop_self.respond_to? :event
        forward = event window, :window_size, x: x, y: y
      end
    }

    window.framebuffer_size_callback = ->(window, x, y) {
      if loop_self.respond_to? :event
        forward = event window, :framebuffer_size, x: x, y: y
      end
    }

    window.iconify_callback = ->(window, iconified) {
      if loop_self.respond_to? :event
        forward = event window, :window_iconify, iconified: iconified
      end
    }

    window.focus_callback = ->(window, focused) {
      if loop_self.respond_to? :event
        forward = event window, :window_focus, focused: focused
      end
    }

    window.cursor_position_callback = ->(window, x, y) {
      if loop_self.respond_to? :event
        forward = event window, :cursor_position, x: x, y: y
      end
    }

    window.cursor_enter_callback = ->(window, entered) {
      if loop_self.respond_to? :event
        forward = event window, :cursor_enter, entered: entered
      end
    }

    window.mouse_button_callback = ->(window, button, action, mods) {
      if loop_self.respond_to? :event
        forward = event window, :mouse, button: button, action: action, mods: mods
      end
    }

    window.scroll_callback = ->(window, x, y) {
      if loop_self.respond_to? :event
        forward = event window, :scroll, x: x, y: y
      end
    }

    window.key_callback = ->(window, button, scancode, action, mods) {
      if loop_self.respond_to? :event
        event window, :key, button: button, scancode: scancode, action: action,
                            mods: mods
      end
    }

    window.char_callback = ->(window, char) {
      if loop_self.respond_to? :event
        forward = event window, :char, char: char
      end
    }
  end

  #
  # Runs the frameloop. Requires a window be assigned to the loop before this
  # will work, otherwise an exception will be raised.
  #
  def run
    init

    @simulation_time = 0.0
    self.running     = true
    @base_time       = ::Glfw::time
    hertz            = @frame_hertz

    @window.make_context_current

    while (@__running = self.running)

      @actual_time = ::Glfw::time - base_time

      # Pre-logic loop and poll for events
      ::Glfw::poll_events
      pre_frame if respond_to? :pre_frame

      # Logic loop
      until @simulation_time > @actual_time
        fixed_frame if respond_to? :fixed_frame
        @simulation_time += @frame_hertz
      end

      # Rendition
      pre_rendition if respond_to? :pre_rendition
      rendition if respond_to? :rendition
      post_rendition if respond_to? :post_rendition
    end

    terminate if respond_to? :terminate
  end

end # class Base
