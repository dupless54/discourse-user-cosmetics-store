# frozen_string_literal: true

require "json"
require "net/http"
require "openssl"
require "timeout"
require "uri"

module ::DiscourseCosmeticsStore
  class PaymentHttp
    class Error < StandardError; end

    MAX_RESPONSE_BYTES = 1.megabyte
    ALLOWED_HOSTS = %w[
      api.stripe.com
      api-m.paypal.com
      api-m.sandbox.paypal.com
      www.paytr.com
      api.iyzipay.com
      sandbox-api.iyzipay.com
      api.shipy.dev
    ].freeze

    def self.json(method:, url:, headers: {}, body: nil)
      response = request(
        method: method,
        url: url,
        headers: { "Content-Type" => "application/json", "Accept" => "application/json" }.merge(headers),
        body: body.nil? ? nil : JSON.generate(body),
      )
      parse_json(response)
    end

    def self.form(method:, url:, headers: {}, form: {})
      encoded = URI.encode_www_form(form)
      response = request(
        method: method,
        url: url,
        headers: {
          "Content-Type" => "application/x-www-form-urlencoded",
          "Accept" => "application/json",
        }.merge(headers),
        body: encoded,
      )
      parse_json(response)
    end

    def self.request(method:, url:, headers:, body: nil)
      uri = URI.parse(url)
      unless uri.is_a?(URI::HTTPS) && ALLOWED_HOSTS.include?(uri.host) && uri.userinfo.blank?
        raise Error, "Ödeme sağlayıcısı hedefi güvenlik politikasına uygun değil"
      end

      klass = { get: Net::HTTP::Get, post: Net::HTTP::Post }.fetch(method.to_sym)
      request = klass.new(uri.request_uri)
      headers.each { |key, value| request[key] = value.to_s }
      request["User-Agent"] = "#{DiscourseCosmeticsStore::PLUGIN_NAME}/#{DiscourseCosmeticsStore::VERSION}"
      request.body = body if body

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      http.open_timeout = 5
      http.read_timeout = 10
      http.write_timeout = 5 if http.respond_to?(:write_timeout=)
      response = http.request(request)
      response_body = response.body.to_s
      raise Error, "Ödeme sağlayıcısı yanıtı çok büyük" if response_body.bytesize > MAX_RESPONSE_BYTES
      unless response.is_a?(Net::HTTPSuccess)
        raise Error, "Ödeme sağlayıcısı HTTP #{response.code} döndürdü"
      end

      response_body
    rescue JSON::ParserError, URI::InvalidURIError, Timeout::Error, SocketError,
           EOFError, IOError, Errno::ECONNREFUSED, Errno::ECONNRESET,
           Errno::EHOSTUNREACH, Errno::ENETUNREACH, Errno::ETIMEDOUT,
           OpenSSL::SSL::SSLError => error
      raise Error, "Ödeme sağlayıcısına güvenli bağlantı kurulamadı: #{error.class}"
    end

    def self.parse_json(raw)
      JSON.parse(raw)
    rescue JSON::ParserError
      raise Error, "Ödeme sağlayıcısı geçersiz yanıt verdi"
    end
  end
end
