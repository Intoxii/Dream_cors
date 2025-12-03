# dream_cors

A secure, spec-compliant CORS (Cross-Origin Resource Sharing) middleware for the [Dream](https://github.com/dream-framework/dream) web framework in Gleam.

## Features

- ✅ **Secure origin validation** - Matches request origin against allowed list
- ✅ **Proper preflight handling** - Responds to OPTIONS requests correctly
- ✅ **Wildcard support** - Handles `*` with proper credential restrictions
- ✅ **Credential-aware** - Prevents wildcard + credentials security issues
- ✅ **Configurable** - Full control over origins, methods, headers, and more
- ✅ **Spec-compliant** - Follows CORS specification correctly

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
| `allow_origins` | `List(String)` | List of allowed origin domains (e.g., `["http://localhost:3000"]`) or `["*"]` for all |
| `allow_methods` | `List(String)` | HTTP methods to allow (e.g., `["GET", "POST", "PUT", "DELETE", "OPTIONS"]`) |
| `allow_headers` | `List(String)` | Request headers that can be used (e.g., `["Content-Type", "Authorization"]`) |
| `expose_headers` | `List(String)` | Response headers that browsers can access (e.g., `["X-Total-Count"]`) |
| `allow_credentials` | `Bool` | Whether to allow credentials (cookies, authorization headers) |
| `max_age` | `Int` | How long (in seconds) preflight responses can be cached |

## How It Works

The middleware intelligently handles CORS in two ways:

### 1. Preflight Requests (OPTIONS)

When the browser sends an OPTIONS request:
- Validates the request's `Origin` header against allowed origins
- Returns `204 No Content` with appropriate CORS headers
- Only sets `Access-Control-Allow-Origin` if origin is allowed

### 2. Actual Requests (GET, POST, etc.)

For all other HTTP methods:
- Passes the request to your controller
- Validates the origin
- Adds CORS headers to the response (only if origin is allowed)
- Returns the modified response

### Origin Matching Logic

The middleware implements secure origin matching:

1. **Specific origin match**: If the request origin is in your allowed list, that specific origin is returned
2. **Wildcard without credentials**: If `"*"` is in allowed origins and credentials are disabled, returns `"*"`
3. **Wildcard with credentials**: If `"*"` is in allowed origins but credentials are enabled, returns the specific request origin (prevents security issue)
4. **No match**: If origin is not allowed, CORS headers are not added

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
  allow_credentials: False,  // Must be False with wildcard
  max_age: 3600,
)
```

## Security Considerations

### Wildcard (`*`) and Credentials

**Important**: The CORS specification does not allow `Access-Control-Allow-Origin: *` when credentials are enabled. This middleware handles this automatically:

- If you configure `allow_origins: ["*"]` with `allow_credentials: True`, the middleware will return the specific request origin instead of `*`
- For maximum security with credentials, explicitly list allowed origins instead of using `*`

### Origin Validation

The middleware validates every request's `Origin` header against your configured list:
- Only matching origins receive CORS headers
- Non-matching origins are denied (no CORS headers added)
- This prevents unauthorized domains from accessing your API

## CORS Headers

The middleware sets the following headers based on your configuration:

**For Preflight (OPTIONS) Requests:**
- `Access-Control-Allow-Origin`: The matching origin or `*`
- `Access-Control-Allow-Methods`: Allowed HTTP methods
- `Access-Control-Allow-Headers`: Allowed request headers
- `Access-Control-Allow-Credentials`: `true` (if configured)
- `Access-Control-Max-Age`: Cache duration for preflight

**For Actual Requests:**
- `Access-Control-Allow-Origin`: The matching origin or `*`
- `Access-Control-Allow-Credentials`: `true` (if configured)
- `Access-Control-Expose-Headers`: Headers accessible to browser

## Troubleshooting

### CORS headers not appearing

- Check that the request's `Origin` header matches one of your `allow_origins`
- Verify the origin includes the protocol (e.g., `http://` or `https://`)
- Check browser console for CORS errors

### Credentials not working

- Ensure `allow_credentials: True` is set
- Don't use `"*"` in `allow_origins` with credentials
- Make sure your frontend sends credentials (e.g., `credentials: 'include'` in fetch)

### Preflight requests failing

- Ensure `"OPTIONS"` is included in `allow_methods`
- Check that all custom headers are listed in `allow_headers`
- Verify the origin is in your `allow_origins` list

## License

MIT

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Links

- [Repository](https://github.com/Intoxii/Dream_cors)
- [Dream Framework](https://github.com/dream-framework/dream)
- [Gleam Language](https://gleam.run)
- [MDN CORS Documentation](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS)
