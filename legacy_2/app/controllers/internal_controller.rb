# app/controllers/internal_controller.rb
require "net/http"
require "uri"

class InternalController < ApplicationController
  def hwpx_ping
    base = ENV.fetch("HWPX_BASE_URL", "http://hwpx-server.railway.internal:8080")
    uri  = URI("#{base}/healthz")

    res = Net::HTTP.get_response(uri)

    render json: {
      ok: res.code.to_i == 200,
      status: res.code.to_i,
      body: res.body
    }
  rescue => e
    render json: { ok: false, error: e.message }, status: 500
  end
end
