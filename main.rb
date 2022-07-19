#!/usr/bin/env ruby -wKU

# Filter class to filter data
class Filter

  #coefficients, set based on the cutoff frequency, the range of frequencies to be preserved.
  COEFFICIENTS_LOW_0_HZ = {
    alpha: [1, -1.979133761292768, 0.979521463540373],
    beta:  [0.000086384997973502, 0.000172769995947004, 0.000086384997973502]
  }
  COEFFICIENTS_LOW_5_HZ = {
    alpha: [1, -1.80898117793047, 0.827224480562408],
    beta:  [0.095465967120306, -0.172688631608676, 0.095465967120306]
  }
  COEFFICIENTS_HIGH_1_HZ = {
    alpha: [1, -1.905384612118461, 0.910092542787947],
    beta:  [0.953986986993339, -1.907503180919730, 0.953986986993339]
  }

  #low-pass filter signals near 0 Hz
  def self.low_0_hz(data)
    filter(data, COEFFICIENTS_LOW_0_HZ)
  end

  #low-pass filter signals near 5 Hz
  def self.low_5_hz(data)
    filter(data, COEFFICIENTS_LOW_5_HZ)
  end

  def self.high_1_hz(data)
    filter(data, COEFFICIENTS_HIGH_1_HZ)
  end

private

  def self.filter(data, coefficients)
    filtered_data = [0,0]
    (2..data.length-1).each do |i|
      filtered_data << coefficients[:alpha][0] *
                      (data[i]*coefficients[:beta][0] +
                       data[i-1]*coefficients[:beta][1] +
                       data[i-2]*coefficients[:beta][2] -
                       filtered_data[i-1]*coefficients[:alpha][1] -
                       filtered_data[i-2]*coefficients[:alpha][2])
    end
    filtered_data
  end

end

# Input parser
class Parser

  attr_reader :parsed_data

  def self.run(data)
    parser = Parser.new(data)
    parser.parse
    parser
  end

  def initialize(data)
    @data = data
  end

  def parse
    @parsed_data = @data.to_s.split(';').map{ |x| x.split('|') }.map{ |x| x.map{ |x| x.split(',').map(&:to_f) } }

    unless @parsed_data.map { |x| x.map(&:length).uniq }.uniq == [[3]]
      raise 'Invalid Input Format. Ensure data is properly formatted.'
    end

    if @parsed_data.first.count == 1
      filtered_accl = @parsed_data.map(&:flatten).transpose.map do |total_accl|
        grav = Filter.low_0_hz(total_accl)
        user = total_accl.zip(grav).map { |a, b| a - b }
        [user, grav]
      end

      @parsed_data = @parsed_data.length.times.map do |i|
        user = filtered_accl.map(&:first).map{ |elem| elem[i]}
        grav = filtered_accl.map(&:last).map{ |elem| elem[i]}
        [user, grav]
      end
    end
  end

end


#process the data
class Processor
  attr_reader :dot_prod_data, :filtered_data

  def self.run(data)
    processor = Processor.new(data)
    processor.dot_prod
    processor.filter
    processor
  end

  def initialize(data)
    @data = data
  end

  def dot_prod
    @dot_prod_data = @data.map do |x|
      x[0][0] * x[1][0] + x[0][1] * x[1][1] + x[0][2] * x[1][2]
    end
  end

  def filter
    @filtered_data = Filter.low_5_hz(@dot_prod_data)
    @filtered_data = Filter.high_1_hz(@filtered_data)
  end

end


#User Functionality
class User

  GENDER = ['male', 'female', 'other']
  MULTIPLIERS = {'female' => 0.413, 'male' => 0.415, 'other' => 0.414}
  AVERAGES    = {'female' => 70.0,  'male' => 78.0, 'other' => 74.0}

  attr_reader :gender, :height, :stride

  def initialize(gender = nil, height = nil, stride = nil)
    @gender = gender.to_s.downcase unless gender.to_s.empty?
    @height = Float(height) unless height.to_s.empty?
    @stride = Float(stride) unless stride.to_s.empty?

    raise 'Invalid gender' if @gender && !GENDER.include?(@gender)
    raise 'Invalid height' if @height && (@height <= 0)
    raise 'Invalid stride' if @stride && (@stride <= 0)

    @stride || = calculate_stride

  end

private

  def calculate_stride
    if gender && height
      MULTIPLIERS[@gender]*height

    elsif height
      height * (MULTIPLIERS.values.reduce(:+) / MULTIPLIERS.size)

    elsif gender
      AVERAGES[gender]

    else
      AVERAGES.values.reduce(:+) / AVERAGES.size
    end
  end

end


#Record Actual Data To verify Efficiency
class Trial

  attr_reader :name, :rate, :steps

  def initialize(name, rate = nil, steps = nil)

    @name = name.to_s.delete(' ')
    @rate = Integer(rate.to_s) unless rate.to_s.empty?
    @steps = Integer(steps.to_s) unless steps.to_s.empty?

    raise 'Invalid Name' if @name.empty?
    raise 'Invalid Rate' if @rate && (@rate <= 0)
    raise 'Invalid Steps' if @steps && (@steps < 0)

  end

end


#Analyze the collected data and give results
class Analyzer

  THRESHOLD = 0.9 #Avoid low peaks

  attr_reader :steps, :delta, :distance, :time

  def self.run(data, user, trial)
    analyzer = Analyzer.new(data, user, trial)
    analyzer.measure_steps
    analyzer.measure_delta
    analyzer.measure_distance
    analyzer.measure_time
    analyzer
  end

  def initialize(data, user, trial)
    @data = data
    @user = user
    @trial = trial
  end

  def measure_steps
    @steps = 0
    count_step = true
    @data.each_with_index do |data, i|
      if(data >= THRESHOLD) && (@data[i-1] < THRESHOLD)
        next unless count_step

        @steps += 1
        count_step = false
      end
      count_step = true if (data < 0) && (@data[i-1] >= 0)
    end
  end

  def measure_delta
    @delta = @steps - @trial.steps if @trial.steps
  end

  def measure_time
    @time = @data.count/@trial.rate if @trial.rate
  end

  def measure_distance
    @distance = @user.stride * @steps
  end

end


#Pipeline all the classes(Parser, Processor, Analyzer) together
class Pipeline

  attr_reader :data, :user, :trial, :parser, :processor, :analyzer

  def self.run(data, user, trial)
    pipeline = Pipeline.new(data, user, trial)
    pipeline.feed
    pipeline
  end

  def initialize(data, user, trial)
    @data = data
    @user = user
    @trial = trial
  end

  def feed
    @parser = Parser.run(@data)
    @processor = Processor.run(@parser.parsed_data)
    @analyzer = Analyzer.run(@processor.filtered_data, @user, @trial)
  end

end


#Manage Data Retrieval
class Upload

end