
var __defProp = Object.defineProperty;
var __name = (target, value) => __defProp(target, "name", { value, configurable: true });

// src/index.js
var corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type"
};
function json(data, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json"
    }
  });
}
__name(json, "json");
async function readApiResponse(response) {
  const text = await response.text();
  if (!text) {
    return { raw_response: "Empty response from API" };
  }
  try {
    return JSON.parse(text);
  } catch {
    return {
      raw_response: text,
      parse_error: "API returned invalid JSON"
    };
  }
}
__name(readApiResponse, "readApiResponse");
// Replicate auth: sanitize the stored secret at runtime. A trailing newline
// (e.g. from `echo token | wrangler secret put`) or surrounding quotes makes
// Replicate reject the request with a header-level 400 + empty body. Trimming
// and stripping wrapping quotes fixes that without ever exposing the value.
function replicateToken(env) {
  const raw = env.REPLICATE_API_TOKEN || "";
  return raw.trim().replace(/^["']+/, "").replace(/["']+$/, "").trim();
}
__name(replicateToken, "replicateToken");
function replicateHeaders(env, extra) {
  return {
    "Authorization": `Bearer ${replicateToken(env)}`,
    ...extra
  };
}
__name(replicateHeaders, "replicateHeaders");
// Descriptive diagnostics for a failed Replicate call — never hides the
// upstream error, never exposes the token itself.
function replicateErrorDetails(response, result) {
  return {
    http_status: response.status,
    status_text: response.statusText,
    request_id: response.headers.get("x-request-id"),
    cf_ray: response.headers.get("cf-ray"),
    content_type: response.headers.get("content-type"),
    details: result
  };
}
__name(replicateErrorDetails, "replicateErrorDetails");
var index_default = {
  async fetch(request, env) {
    const url = new URL(request.url);
    if (request.method === "OPTIONS") {
      return new Response(null, {
        headers: corsHeaders
      });
    }
    if (url.pathname === "/" && request.method === "GET") {
      return json({
        success: true,
        message: "Vyro AI API is running!",
        endpoints: [
          "/generate-image",
          "/generate-video",
          "/video-status?id=PREDICTION_ID"
        ]
      });
    }
    if (url.pathname === "/generate-image" && request.method === "POST") {
      try {
        const body = await request.json();
        const prompt = body.prompt;
        if (typeof prompt !== "string" || !prompt.trim()) {
          return json({
            success: false,
            error: "Please provide an image prompt."
          }, 400);
        }
        if (prompt.length > 2048) {
          return json({
            success: false,
            error: "Prompt is too long. Maximum 2048 characters."
          }, 400);
        }
        if (!env.AI) {
          return json({
            success: false,
            error: "Cloudflare AI binding is missing."
          }, 500);
        }
        const result = await env.AI.run(
          "@cf/black-forest-labs/flux-1-schnell",
          {
            prompt: prompt.trim(),
            steps: 4
          }
        );
        if (!result || !result.image) {
          return json({
            success: false,
            error: "Image generation returned no image."
          }, 502);
        }
        const binary = Uint8Array.from(
          atob(result.image),
          (char) => char.charCodeAt(0)
        );
        const imageBlob = new Blob([binary], {
          type: "image/png"
        });
        const formData = new FormData();
        formData.append(
          "file",
          imageBlob,
          "vyro-ai-generated.png"
        );
        const uploadResponse = await fetch(
          "https://api.pixelvault.dev/v1/images",
          {
            method: "POST",
            body: formData
          }
        );
        const uploadResult = await readApiResponse(
          uploadResponse
        );
        if (!uploadResponse.ok || !uploadResult.data?.url) {
          return json({
            success: false,
            error: "Image generated but PixelVault upload failed.",
            upload_status: uploadResponse.status,
            details: uploadResult
          }, 502);
        }
        return json({
          success: true,
          message: "Image generated and uploaded successfully!",
          image_url: uploadResult.data.url,
          temporary: uploadResult.data.temporary,
          expires_in: uploadResult.data.expires_in,
          mime_type: uploadResult.data.mime_type
        });
      } catch (error) {
        return json({
          success: false,
          error: "Image generation or upload failed.",
          details: error.message
        }, 500);
      }
    }
    if (url.pathname === "/generate-video" && request.method === "POST") {
      try {
        const body = await request.json();
        const prompt = body.prompt;
        if (typeof prompt !== "string" || !prompt.trim()) {
          return json({
            success: false,
            error: "Please provide a video prompt."
          }, 400);
        }
        if (prompt.length > 2e3) {
          return json({
            success: false,
            error: "Prompt is too long."
          }, 400);
        }
        if (!env.REPLICATE_API_TOKEN) {
          return json({
            success: false,
            error: "Replicate API token is missing."
          }, 500);
        }
        const response = await fetch(
          "https://api.replicate.com/v1/models/xai/grok-imagine-video/predictions",
          {
            method: "POST",
            headers: replicateHeaders(env, {
              "Content-Type": "application/json"
            }),
            body: JSON.stringify({
              input: {
                prompt: prompt.trim(),
                duration: 5,
                resolution: "480p",
                aspect_ratio: "16:9"
              }
            })
          }
        );
        const result = await readApiResponse(response);
        if (!response.ok) {
          return json({
            success: false,
            error: "Replicate video request failed.",
            ...replicateErrorDetails(response, result)
          }, 502);
        }
        if (!result.id) {
          return json({
            success: false,
            error: "Replicate did not return a prediction ID.",
            details: result
          }, 502);
        }
        return json({
          success: true,
          message: "Video generation started.",
          prediction_id: result.id,
          status: result.status,
          output: result.output,
          status_url: `/video-status?id=${result.id}`
        }, 202);
      } catch (error) {
        return json({
          success: false,
          error: "Video generation failed.",
          details: error.message
        }, 500);
      }
    }
    if (url.pathname === "/video-status" && request.method === "GET") {
      try {
        const id = url.searchParams.get("id");
        if (!id || !/^[a-zA-Z0-9_-]+$/.test(id)) {
          return json({
            success: false,
            error: "Valid prediction ID is required."
          }, 400);
        }
        if (!env.REPLICATE_API_TOKEN) {
          return json({
            success: false,
            error: "Replicate API token is missing."
          }, 500);
        }
        const response = await fetch(
          `https://api.replicate.com/v1/predictions/${id}`,
          {
            method: "GET",
            headers: replicateHeaders(env)
          }
        );
        const result = await readApiResponse(response);
        if (!response.ok) {
          return json({
            success: false,
            error: "Could not check video status.",
            ...replicateErrorDetails(response, result)
          }, 502);
        }
        return json({
          success: true,
          id: result.id,
          status: result.status,
          output: result.output,
          error: result.error,
          logs: result.logs
        });
      } catch (error) {
        return json({
          success: false,
          error: "Video status check failed.",
          details: error.message
        }, 500);
      }
    }
    if (url.pathname === "/replicate-check" && request.method === "GET") {
      try {
        if (!env.REPLICATE_API_TOKEN) {
          return json({
            success: false,
            message: "Replicate token missing in Cloudflare."
          }, 500);
        }
        const response = await fetch(
          "https://api.replicate.com/v1/account",
          {
            method: "GET",
            headers: replicateHeaders(env)
          }
        );
        const result = await readApiResponse(response);
        return json({
          success: response.ok,
          http_status: response.status,
          status_text: response.statusText,
          content_type: response.headers.get("content-type"),
          request_id: response.headers.get("x-request-id"),
          account: response.ok ? result : null,
          error: response.ok ? null : result
        });
      } catch (error) {
        return json({
          success: false,
          error: error.message
        }, 500);
      }
    }
  }
};
export {
  index_default as default
};
//# sourceMappingURL=index.js.map
