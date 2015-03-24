require 'debugger'              # optional, may be helpful
require 'open-uri'              # allows open('http://...') to return body
require 'cgi'                   # for escaping URIs
require 'nokogiri'              # XML parser
require 'active_model'          # for validations

class OracleOfBacon

  class InvalidError < RuntimeError ; end
  class NetworkError < RuntimeError ; end
  class InvalidKeyError < RuntimeError ; end
  extend ActiveModel::Naming

  attr_accessor :from, :to
  attr_reader :api_key, :response, :uri
  attr_reader   :errors
  
  include ActiveModel::Validations
  validates_presence_of :from
  validates_presence_of :to
  validates_presence_of :api_key
  validate :from_does_not_equal_to

  def from_does_not_equal_to
    # validates_each :from, :to do |record, attr, value|
      # record.errors.add attr, "From cannot be the same as To" if @from == @to
    # end  
    errors.add(:from, "From cannot be the same as To") if @from == @to
  end

  def initialize(options={})
    @from = options[:from] || "Kevin Bacon"
    @to = options[:to] || "Kevin Bacon"
    @api_key = options[:api_key] || "38b99ce9ec87"
    @errors = ActiveModel::Errors.new(self)
  end

  def find_connections
    make_uri_from_arguments
    begin
      xml = URI.parse(uri).read
    rescue Timeout::Error, Errno::EINVAL, Errno::ECONNRESET, EOFError,
      Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError,
      Net::ProtocolError => e
      # convert all of these into a generic OracleOfBacon::NetworkError,
      #  but keep the original error message
      raise OracleOfBacon::NetworkError
    end
    OracleOfBacon::Response.new(xml)
  end

  def make_uri_from_arguments
    # example: "oracleofbacon.org/cgi-bin/xml?p=my_key&a=Kevin+Bacon&b=Laurence+Olivier"
    params = {}
    params["p"] = @api_key
    params["a"] = @from
    params["b"] = @to

    query = URI.encode_www_form(params)
    host = 'oracleofbacon.org'
    path = '/cgi-bin/xml'

    @uri = URI::HTTP.build([nil, host, nil, path, query, nil]).to_s
  end
      
  class Response
    attr_reader :type, :data
    # create a Response object from a string of XML markup.
    def initialize(xml)
      @doc = Nokogiri::XML(xml)
      parse_response
    end

    private

    def parse_response
      # @doc
      if ! @doc.xpath('/error').empty?
        parse_error_response
      elsif ! @doc.xpath('/link').empty?
        parse_graph_response
      elsif ! @doc.xpath('/spellcheck').empty?
        parse_spellcheck_response  
      else
        parse_unknown_response       
        @type = :unknown
        @data = 'unknown response type'
      end
    end
    
    def parse_error_response
      @type = :error
      @data = 'Unauthorized access'
    end

    def parse_graph_response
      @type = :graph
      actor_arr = @doc.xpath('//actor').map{|x| x.text}
      movie_arr = @doc.xpath('//movie').map {|x| x.text}
      @data = actor_arr.zip(movie_arr).flatten.compact
    end

    def parse_spellcheck_response
      @type = :spellcheck
      match_arr = @doc.xpath('//match').map{|x| x.text}
      @data = match_arr.flatten.compact
    end

    def parse_unknown_response
      @type = :unknown
      @data = 'unknown response'
    end
  end
end

# oob = OracleOfBacon.new(api_key: "Ian Mckellan")
# p oob.api_key
# oob.find_connections
# p oob.uri

# p oob

