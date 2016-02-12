module Streamable
  def -(other)
    Stream.new(other, self)
  end
end

Proc.include(Streamable)

class Stream
  include Streamable

  def initialize(own_function, arg_function)
    @own_function, @arg_function = own_function, arg_function
  end

  def call
    own_function.call.call(arg_function.call)
  end

  private
  attr_reader :own_function, :arg_function
end

class SerialStreamArray
  def initialize(array)
    @array = array
  end

  def -(other)
    self.class.new(
      array.map { |stream| Stream.new(other, stream) }
    )
  end

  def |(other)
    Stream.new(other, self)
  end

  def +(other)
    ConcurrentStreamArray.new(
      array.map { |stream| Stream.new(other, stream) }
    )
  end

  def call(*args)
    if args.empty?
      array.map(&:call)
    else
      args.flat_map { |arg|
        array.map { |function|
          function.call(arg)
        }
      }
    end
  end

  private
  attr_reader :array
end

class ConcurrentStreamArray
  def initialize(array)
    @array = array
  end

  def -(other)
    SerialStreamArray.new(
      array.map { |stream| Stream.new(other, stream) }
    )
  end

  def call(*args)
    [].tap do |results|
      if args.empty?
        array.map { |i|
          Thread.new do
            results << i.call
          end
        }.each(&:join)
      else
        args.flat_map { |arg|
          array.map do |function|
            Thread.new { results << function.call(arg) }
          end
        }.each(&:join)
      end
    end
  end

  private
  attr_reader :array
end

class Array
  def -@
    SerialStreamArray.new(self)
  end

  def +@
    ConcurrentStreamArray.new(self)
  end

  def call
    map(&:call)
  end
end
