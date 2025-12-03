import dream/http/header.{get_header, set_header}
import dream/http/request.{type Request, Options}
import dream/http/response.{Response, Text}
import dream/router.{type Middleware, Middleware}
import gleam/int
import gleam/list
import gleam/option.{None, Some}
import gleam/string

// --- Public Type and Function Definitions ---

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
        // --- Preflight Request Handling ---
        let allowed_origin = get_allowed_origin(req, config)

        let base_headers =
          []
          |> set_header(
            "Access-Control-Allow-Methods",
            string.join(config.allow_methods, ", "),
          )
          |> set_header(
            "Access-Control-Allow-Headers",
            string.join(config.allow_headers, ", "),
          )
          |> set_header("Access-Control-Max-Age", int.to_string(config.max_age))

        let headers = case allowed_origin {
          "" -> base_headers
          origin ->
            base_headers
            |> set_header("Access-Control-Allow-Origin", origin)
            |> case config.allow_credentials {
              True -> set_header(_, "Access-Control-Allow-Credentials", "true")
              False -> fn(h) { h }
            }
        }

        Response(
          status: 204,
          body: Text(""),
          headers: headers,
          cookies: [],
          content_type: None,
        )
      }
      _ -> {
        // --- Actual Request Handling ---
        let response = next(req, ctx, services)
        let allowed_origin = get_allowed_origin(req, config)

        let updated_headers = case allowed_origin {
          "" -> response.headers
          origin ->
            response.headers
            |> set_header("Access-Control-Allow-Origin", origin)
            |> case config.allow_credentials {
              True -> set_header(_, "Access-Control-Allow-Credentials", "true")
              False -> fn(h) { h }
            }
            |> set_header(
              "Access-Control-Expose-Headers",
              string.join(config.expose_headers, ", "),
            )
        }

        Response(..response, headers: updated_headers)
      }
    }
  })
}

// --- Private Helper Functions ---

// Determines the correct value for the Access-Control-Allow-Origin header.
// Returns "" if no origin is allowed, or the determined origin string.
fn get_allowed_origin(req: Request, config: CorsConfig) -> String {
  // Get the 'Origin' header from the request
  let origin = get_header(req.headers, "Origin")

  case origin {
    // 1. Origin header is present
    Some(o) -> {
      let is_origin_allowed = list.contains(config.allow_origins, o)
      let is_wildcard_allowed = list.contains(config.allow_origins, "*")

      case is_origin_allowed, is_wildcard_allowed, config.allow_credentials {
        // A. Specific origin is allowed, use it.
        True, _, _ -> o

        // B. Wildcard is allowed AND credentials are not allowed, use wildcard.
        False, True, False -> "*"

        // C. Wildcard is allowed BUT credentials are required, use the specific origin.
        // (This handles cases where the allowed list contains `*` and credentials are true)
        False, True, True -> o

        // D. Origin not allowed, return nothing.
        _, _, _ -> ""
      }
    }
    // 2. Origin header is NOT present (e.g., same-origin request, but middleware still runs)
    None -> {
      // If the wildcard is configured, return it for non-CORS requests
      // This is generally safe if the framework handles same-origin checks internally
      case list.contains(config.allow_origins, "*") {
        True -> "*"
        False -> ""
      }
    }
  }
}
