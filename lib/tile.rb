# frozen_string_literal: true

module Tile
  EMPTY = :empty
  ROAD = :road
  RESIDENTIAL = :residential
  COMMERCIAL = :commercial
  INDUSTRIAL = :industrial
  POLICE = :police
  FIRE = :fire
  HOSPITAL = :hospital
  PARK = :park

  ALL = [EMPTY, ROAD, RESIDENTIAL, COMMERCIAL, INDUSTRIAL, POLICE, FIRE, HOSPITAL, PARK].freeze

  ZONES = [RESIDENTIAL, COMMERCIAL, INDUSTRIAL].freeze
  SERVICES = [POLICE, FIRE, HOSPITAL, PARK].freeze

  def self.zonable?(type)
    ZONES.include?(type)
  end

  def self.service?(type)
    SERVICES.include?(type)
  end
end
