#!/usr/bin/env ruby
# frozen_string_literal: true

system('bundle install') unless system('bundle check', out: File::NULL, err: File::NULL)

require_relative 'lib/tile'
require_relative 'lib/grid'
require_relative 'lib/economy'
require_relative 'lib/city_builder'
require_relative 'lib/window'

new_game = ARGV.include?('--new')
game = if new_game
         CityBuilder.new(60, 40)
       else
         CityBuilder.load_from || CityBuilder.new(60, 40)
       end

GameWindow.new(game).show
