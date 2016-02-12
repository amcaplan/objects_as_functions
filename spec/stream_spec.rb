require './stream'
require 'net/http'

class Doubler
  def call(other)
    other * 2
  end
end

class Flattener
  def call(other)
    other.flatten
  end
end

class GooglePinger
  def call(other)
    Net::HTTP.get(URI("http://www.google.co.il/search?q=#{other}"))
  end
end

describe 'a stream with an input and a receiver' do
  let(:stream) {
    -> { 4 } --> { Doubler.new }
  }

  it 'passes through the input' do
    expect(stream.call).to eq(8)
  end
end

describe 'a stream with an input and 2 serial receivers' do
  let(:stream) {
    -> { 4 } --> { Doubler.new } --> { Doubler.new }
  }

  it 'passes through the input' do
    expect(stream.call).to eq(16)
  end
end

describe 'a stream with an input and 3 serial receivers' do
  let(:stream) {
    -> { 4 } --> { Doubler.new } --> { Doubler.new } --> { Doubler.new }
  }

  it 'passes through the input' do
    expect(stream.call).to eq(32)
  end
end

describe 'a stream with 2 inputs and a receiver' do
  let(:stream) {
    -[
      -> { 4 },
      -> { 8 }
    ] --> { Doubler.new }
  }

  it 'passes through the input' do
    expect(stream.call).to eq([8, 16])
  end
end

describe 'a stream with 2 inputs and 3 receivers' do
  let(:stream) {
    -[
      -> { 4 },
      -> { 8 }
    ] --> { Doubler.new } --> { Doubler.new } --> { Doubler.new }
  }

  it 'passes through the input' do
    expect(stream.call).to eq([32, 64])
  end
end

describe 'a stream with 2 inputs and 2 arrayed receivers' do
  let(:stream) {
    -[
      -> { 4 },
      -> { 8 }
    ] --> {
      -[
        Doubler.new,
        Doubler.new
      ]
    }
  }

  it 'passes through the input' do
    expect(stream.call).to eq([[8, 8], [16, 16]])
  end
end

describe 'a stream with 2 inputs and 2 arrayed receivers, joined back together' do
  let(:stream) {
    -[
      -> { 4 },
      -> { 8 }
    ] --> {
      -[
        Doubler.new,
        Doubler.new
      ]
    } |-> {
      Flattener.new
    }
  }

  it 'passes through the input' do
    expect(stream.call).to eq([8, 8, 16, 16])
  end
end

describe 'a concurrent stream with 2 inputs and 2 arrayed receivers' do
  let(:stream) {
    -[
      -> { 4 },
      -> { 8 }
    ] +-> {
      -[
        Doubler.new,
        Doubler.new
      ]
    }
  }

  it 'passes through the input' do
    expect(stream.call.sort).to eq([[8, 8], [16, 16]])
  end
end

describe 'a concurrent stream with 2 inputs and 2 arrayed receivers, joined back together' do
  let(:stream) {
    +[
      -> { 4 },
      -> { 8 }
    ] --> {
      +[
        Doubler.new,
        Doubler.new
      ]
    } |-> {
      Flattener.new
    }
  }

  it 'passes through the input' do
    expect(stream.call).to eq([8, 8, 16, 16])
  end
end

describe 'a concurrent stream with 2 inputs and 2 arrayed receivers, joined back together' do
  let(:stream) {
    +[
      -> { 'food' },
      -> { 'baseball' }
    ] --> {
      +[
        GooglePinger.new,
        GooglePinger.new
      ]
    } |-> {
      Flattener.new
    }
  }

  it 'passes through the input' do
    stream.call.map { |i|
      p i =~ /baseball/
      p i =~ /food/
    }
  end
end
