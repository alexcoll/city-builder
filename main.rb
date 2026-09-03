#!/usr/bin/env ruby
# frozen_string_literal: true

system('bundle install') unless system('bundle check', out: File::NULL, err: File::NULL)

require_relative 'lib/tile'
require_relative 'lib/grid'
require_relative 'lib/economy'
require_relative 'lib/city_builder'
require_relative 'lib/window'

GameWindow.new.show
