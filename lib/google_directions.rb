# encoding: utf-8
require 'cgi'
require 'net/http'
require 'open-uri'

class GoogleDirections

  attr_reader :status, :route, :leg, :json, :origin, :destination, :options

  @@base_url = 'http://maps.googleapis.com/maps/api/directions/json'

  @@default_options = {
    language: 'pt-BR',
    alternative: :false,
    mode: :driving,
    units: :metric
  }

  def initialize(origin, destination, opts=@@default_options)
    @origin = origin
    @destination = destination
    @options = opts.merge({:origin => @origin, :destination => @destination})

    @url = @@base_url + '?' + @options.to_query
    @json = open(@url).read.force_encoding("UTF-8")
    @doc = JSON.parse(@json)
    @status = @doc["status"]
    @route = @doc["routes"][0]
    @leg = @route["legs"][0]
  end

  def xml_call
    @url
  end

  # an example URL to be generated
  #http://maps.google.com/maps/api/directions/xml?origin=St.+Louis,+MO&destination=Nashville,+TN&sensor=false&key=ABQIAAAAINgf4OmAIbIdWblvypOUhxSQ8yY-fgrep0oj4uKpavE300Q6ExQlxB7SCyrAg2evsxwAsak4D0Liiv

  def overview_polyline
    @route["overview_polyline"]["points"]
  end

  def drive_time_in_minutes
    if @status != "OK"
      drive_time = 0
    else
      drive_time = @leg["duration"]["value"]
      convert_to_minutes(drive_time)
    end
  end

  # the distance.value field always contains a value expressed in meters.
  def distance
    return @distance if @distance
    unless @status == 'OK'
      @distance = 0
    else
      @distance = @leg["distance"]["value"]
    end
  end

  def distance_text
    return @distance_text if @distance_text
    unless @status == 'OK'
      @distance_text = "0 km"
    else
      @distance_text = @leg["distance"]["text"]
    end
  end

  def distance_in_miles
    if @status != "OK"
      distance_in_miles = 0
    else
      meters = distance
      distance_in_miles = (meters.to_f / 1610.22).round
      distance_in_miles
    end
  end

  def public_url
    "http://maps.google.com/maps?saddr=#{transcribe(@origin)}&daddr=#{transcribe(@destination)}&hl=#{@options[:language]}&ie=UTF8"
  end

  def steps
    if @status == 'OK'
      @leg["steps"].map{|i| i["html_instructions"]}
    else
      []
    end
  end

  private

    def convert_to_minutes(text)
      (text.to_f / 60).round
    end
end

class Hash

  def to_query
    collect do |k, v|
      "#{k}=#{CGI::escape(v.to_s)}"
    end * '&'
  end unless method_defined? :to_query

end
