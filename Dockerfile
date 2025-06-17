# Stage 1: Build the mcp-proxy application (This part is unchanged)
FROM ghcr.io/astral-sh/uv:python3.12-alpine AS uv
WORKDIR /app
ENV UV_COMPILE_BYTECODE=1
ENV UV_LINK_MODE=copy
RUN --mount=type=cache,target=/root/.cache/uv \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    uv sync --frozen --no-install-project --no-dev --no-editable
ADD . /app
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --frozen --no-dev --no-editable

# Stage 2: Create the final, runnable image
FROM python:3.12-alpine

# --- MODIFICATION START ---
# Install the command-line tools that mcp-proxy will call.
# 'uv' is needed for `uvx mcp-server-fetch`.
# 'nodejs' and 'npm' are needed for `npx ...`.
RUN apk add --no-cache uv nodejs npm
# --- MODIFICATION END ---

# Copy the pre-built application from the builder stage
COPY --from=uv --chown=app:app /app/.venv /app/.venv

# Add the application's executables to the system PATH
ENV PATH="/app/.venv/bin:$PATH"

# Set the default command to run the proxy
ENTRYPOINT ["mcp-proxy"]
