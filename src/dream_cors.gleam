import dream/http/header.{set_header}
import dream/http/request.{type Request, Options}
import dream/http/response.{Response, Text}
import dream/router.{type Middleware, Middleware}
import gleam/bool
import gleam/int
import gleam/option
import gleam/string

pub type CorsConfig {
  CorsConfig(
    allow_origins: List(String),
    allow_methods: List(String),
    allow_headers: List(String),
    expose_headers: List(String),
    allow_credentials: Bool,
    max_age: Int,
  )
}

pub fn cors(
  allow_origins: List(String),
  allow_methods: List(String),
  allow_headers: List(String),
  expose_headers: List(String),
  allow_credentials: Bool,
  max_age: Int,
) -> Middleware(context, services) {
  let config =
    CorsConfig(
      allow_origins: allow_origins,
      allow_methods: allow_methods,
      allow_headers: allow_headers,
      expose_headers: expose_headers,
      allow_credentials: allow_credentials,
      max_age: max_age,
    )
  Middleware(fn(req: Request, ctx, services, next) {
    case req.method {
      Options -> {
        let headers =
          []
          |> set_header(
            "Access-Control-Allow-Origin",
            string.join(config.allow_origins, ", "),
          )
          |> set_header(
            "Access-Control-Allow-Methods",
            string.join(config.allow_methods, ", "),
          )
          |> set_header(
            "Access-Control-Allow-Headers",
            string.join(config.allow_headers, ", "),
          )
          |> set_header(
            "Access-Control-Expose-Headers",
            string.join(config.expose_headers, ", "),
          )
          |> set_header(
            "Access-Control-Allow-Credentials",
            bool.to_string(config.allow_credentials),
          )
          |> set_header("Access-Control-Max-Age", int.to_string(config.max_age))

        Response(
          status: 200,
          body: Text(""),
          headers: headers,
          cookies: [],
          content_type: option.None,
        )
      }
      _ -> {
        let response = next(req, ctx, services)
        let update_headers =
          response.headers
          |> set_header(
            "Access-Control-Allow-Origin",
            string.join(config.allow_origins, ", "),
          )
        Response(..response, headers: update_headers)
      }
    }
  })
}
