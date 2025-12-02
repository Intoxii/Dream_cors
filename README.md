# dream_cors

A CORS (Cross-Origin Resource Sharing) middleware for the [Dream](https://github.com/dream-framework/dream) web framework in Gleam.

## Installation

Add `dream_cors` to your `gleam.toml`:

```toml
[dependencies]
dream_cors = "~> 0.1.0"
```

Then run:

```sh
gleam deps download
```

## Usage

### Basic Example

```gleam
import dream
import dream/router.{router}
import dream/http/request.{Get, Post}
import dream_cors

pub fn main() {
  // Configure CORS middleware
  let cors = dream_cors.cors(
    allow_origins: ["http://localhost:3000"],
    allow_methods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allow_headers: ["Content-Type", "Authorization"],
    expose_headers: [],
    allow_credentials: True,
    max_age: 3600,
  )

  // Add CORS to your routes
  router
  |> router.route(Get, "/api/users", controllers.list_users, [cors])
  |> router.route(Post, "/api/users", controllers.create_user, [cors])
  |> dream.listen(port: 8000)
}
```

### Multiple Origins

```gleam
let cors = dream_cors.cors(
  allow_origins: [
    "http://localhost:3000",
    "https://myapp.com",
    "https://www.myapp.com",
  ],
  allow_methods: ["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"],
  allow_headers: ["Content-Type", "Authorization", "X-Custom-Header"],
  expose_headers: ["X-Total-Count", "X-Page-Number"],
  allow_credentials: True,
  max_age: 86400,  // 24 hours
)
```

### Apply to All API Routes

```gleam
pub fn setup_api_routes(cors) {
  router
  |> router.route(Get, "/api/users", controllers.list_users, [cors])
  |> router.route(Get, "/api/users/:id", controllers.get_user, [cors])
  |> router.route(Post, "/api/users", controllers.create_user, [cors])
  |> router.route(Put, "/api/users/:id", controllers.update_user, [cors])
  |> router.route(Delete, "/api/users/:id", controllers.delete_user, [cors])
}
```

## Configuration Options

| Parameter | Type | Description |
|-----------|------|-------------|
| `allow_origins` | `List(String)` | List of allowed origin domains (e.g., `["http://localhost:3000"]`) |
| `allow_methods` | `List(String)` | HTTP methods to allow (e.g., `["GET", "POST", "PUT", "DELETE", "OPTIONS"]`) |
| `allow_headers` | `List(String)` | Request headers that can be used (e.g., `["Content-Type", "Authorization"]`) |
| `expose_headers` | `List(String)` | Response headers that browsers can access (e.g., `["X-Total-Count"]`) |
| `allow_credentials` | `Bool` | Whether to allow credentials (cookies, authorization headers) |
| `max_age` | `Int` | How long (in seconds) preflight responses can be cached |

## How It Works

The middleware handles CORS in two ways:

1. **Preflight Requests (OPTIONS)**: When the browser sends an OPTIONS request, the middleware responds immediately with appropriate CORS headers and a 200 status.

2. **Actual Requests**: For all other HTTP methods (GET, POST, etc.), the middleware:
   - Passes the request to your controller
   - Adds the `Access-Control-Allow-Origin` header to the response
   - Returns the modified response

## Common Configurations

### Development (Allow localhost)

```gleam
let cors = dream_cors.cors(
  allow_origins: ["http://localhost:3000", "http://localhost:5173"],
  allow_methods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
  allow_headers: ["Content-Type"],
  expose_headers: [],
  allow_credentials: False,
  max_age: 3600,
)
```

### Production (Specific domains)

```gleam
let cors = dream_cors.cors(
  allow_origins: ["https://myapp.com", "https://www.myapp.com"],
  allow_methods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
  allow_headers: ["Content-Type", "Authorization"],
  expose_headers: ["X-RateLimit-Remaining"],
  allow_credentials: True,
  max_age: 86400,
)
```

### Public API (Allow all origins)

```gleam
let cors = dream_cors.cors(
  allow_origins: ["*"],
  allow_methods: ["GET", "OPTIONS"],
  allow_headers: ["Content-Type"],
  expose_headers: [],
  allow_credentials: False,
  max_age: 3600,
)
```

## CORS Headers

The middleware sets the following headers:

- `Access-Control-Allow-Origin`: Allowed origins (comma-separated)
- `Access-Control-Allow-Methods`: Allowed HTTP methods (comma-separated)
- `Access-Control-Allow-Headers`: Allowed request headers (comma-separated)
- `Access-Control-Expose-Headers`: Headers accessible to the browser (comma-separated)
- `Access-Control-Allow-Credentials`: Whether credentials are allowed (`True` or `False`)
- `Access-Control-Max-Age`: Preflight cache duration in seconds

## License

MIT

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Links

- [Dream Framework](https://github.com/dream-framework/dream)
- [Gleam Language](https://gleam.run)
- [CORS Documentation](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS)

