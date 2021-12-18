# frozen_string_literal: true

require_relative "random_name_generator/version"
require_relative "random_name_generator/syllable"

# RandomNameGenerator:
#
# Examples
#
#   rng = RandomNameGenerator::Generator.new(RandomNameGenerator::GOBLIN)
#   puts rng.compose(3)
#
# By default RandomNameGenerator uses the Fantasy syllable file and creates a name with between 2 and 5 syllables.
#
#   rng = RandomNameGenerator::Generator.new
#   puts rng.compose
#
# :reek:TooManyConstants
# :reek:TooManyInstanceVariables
# :reek:TooManyStatements
module RandomNameGenerator
  dirname = File.dirname(__FILE__)

  ELVEN = "#{dirname}/languages/elven.txt"
  FANTASY = "#{dirname}/languages/fantasy.txt"
  GOBLIN = "#{dirname}/languages/goblin.txt"
  ROMAN = "#{dirname}/languages/roman.txt"

  ELVEN_RU = "#{dirname}/languages/elven-ru.txt"
  FANTASY_RU = "#{dirname}/languages/fantasy-ru.txt"
  GOBLIN_RU = "#{dirname}/languages/goblin-ru.txt"
  ROMAN_RU = "#{dirname}/languages/roman-ru.txt"

  # Experimental
  CURSE = "#{dirname}/languages/experimental/curse.txt"

  # Static factory method that instantiates a RandomNameGenerator in a random language.
  def self.flip_mode
    langs = [RandomNameGenerator::FANTASY,
             RandomNameGenerator::ELVEN,
             RandomNameGenerator::GOBLIN,
             RandomNameGenerator::ROMAN]
    Generator.new(langs.sample)
  end

  # Static factory method that instantiates a RandomNameGenerator in a random
  # Cyrillic based language.
  def self.flip_mode_cyrillic
    langs = [RandomNameGenerator::FANTASY_RU,
             RandomNameGenerator::ELVEN_RU,
             RandomNameGenerator::GOBLIN_RU,
             RandomNameGenerator::ROMAN_RU]
    Generator.new(langs.sample)
  end

  def self.pick_number_of_syllables(random: Random.new)
    [2, 2, 2, 2, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 4, 4, 4, 5].sample(random: random)
  end

  # Static factory method for the Generator class.
  def self.new(language = RandomNameGenerator::FANTASY, random: Random.new)
    Generator.new(language, random: random)
  end

  # Generator
  #
  # Workhorse class that assembles names from dialect files.
  #
  class Generator
    attr_reader :language_path, :pre_syllables, :sur_syllables, :mid_syllables

    def initialize(language_path = RandomNameGenerator::FANTASY, random: Random.new)
      @pre = nil
      @language_path = language_path
      @rnd = random
      @pre_syllables = []
      @mid_syllables = []
      @sur_syllables = []

      refresh
    end

    # Returns the composed name as an array of Syllables.
    def compose_array(count = RandomNameGenerator.pick_number_of_syllables)
      @pre = pre_syllables.sample(random: @rnd)
      return @pre.to_s.capitalize if count < 2

      name = determine_middle_syllables(count - 2, @pre)
      name << determine_last_syllable(name.last)
      name
    end

    def compose(count = RandomNameGenerator.pick_number_of_syllables)
      compose_array(count).map(&:to_s).join.capitalize
    end

    def to_s
      "RandomNameGenerator::Generator (#{@language_path.split("/")[-1]})"
    end

    private

    def determine_middle_syllables(count, pre)
      determine_next_syllables(count, pre, @mid_syllables)
    end

    def determine_last_syllable(next_to_last_syllable)
      determine_next_syllable(next_to_last_syllable, @sur_syllables)
    end

    def determine_next_syllables(count, pre, syllables)
      name = Array(pre)
      return name if count < 1

      next_syllable = pre
      count.times do
        next_syllable = determine_next_syllable(next_syllable, syllables)
        name << next_syllable
      end
      name
    end

    def determine_next_syllable(this_syllable, sampler)
      next_syllable = ""
      loop do
        next_syllable = sampler.sample(random: @rnd)
        break unless this_syllable.incompatible?(next_syllable)
      end
      next_syllable
    end

    # Loops through the language file, and pushes each syllable into the correct array.
    def refresh
      lang_file = File.new(@language_path)
      lang_file.readlines.each do |line|
        push(RandomNameGenerator::Syllable.new(line)) unless line.empty?
      end
      lang_file.rewind
    end

    def push(syllable)
      if syllable.prefix?
        @pre_syllables.push(syllable)
      elsif syllable.suffix?
        @sur_syllables.push(syllable)
      else
        @mid_syllables.push(syllable)
      end
    end
  end
end
