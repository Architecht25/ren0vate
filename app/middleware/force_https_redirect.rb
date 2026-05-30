# Middleware to redirect plain HTTP requests to HTTPS.
# Needed because config.assume_ssl = true prevents ActionDispatch::SSL from
# detecting HTTP requests (it assumes all requests are already HTTPS).
# This middleware runs first and checks the X-Forwarded-Proto header set by Heroku.
class ForceHttpsRedirect
  def initialize(app)
    @app = app
  end

  def call(env)
    if env["HTTP_X_FORWARDED_PROTO"] == "http"
      host = env["HTTP_HOST"] || env["SERVER_NAME"]
      path = env["PATH_INFO"]
      qs   = env["QUERY_STRING"]
      location = "https://#{host}#{path}"
      location += "?#{qs}" if qs && !qs.empty?
      [ 301,
        { "Location" => location, "Content-Type" => "text/html", "Content-Length" => "0" },
        [] ]
    else
      @app.call(env)
    end
  end
end
