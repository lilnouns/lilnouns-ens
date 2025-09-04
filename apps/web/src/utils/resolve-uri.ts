export function resolveUriToHttp(uri: string): string {
  if (!uri) return ''
  if (uri.startsWith('ipfs://')) {
    const cidPath = uri.replace('ipfs://', '')
    // prefer Cloudflare gateway for speed
    return `https://cloudflare-ipfs.com/ipfs/${cidPath}`
  }
  return uri
}

export function parseDataUriToJson(uri: string): unknown {
  // supports data:application/json;utf8,... and ;base64,...
  const match = uri.match(/^data:application\/json(?:;charset=[^;,]+)?(;base64)?,(.*)$/i)
  if (!match) return undefined
  const isBase64 = !!match[1]
  const payload = match[2]
  const jsonStr = isBase64 ? atob(payload) : decodeURIComponent(payload)
  return JSON.parse(jsonStr)
}
