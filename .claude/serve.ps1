$root = (Resolve-Path "$PSScriptRoot\..").Path
$prefix = "http://localhost:5173/"
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add($prefix)
$listener.Start()
Write-Host "Serving $root at $prefix"
$mime = @{
  ".html"="text/html; charset=utf-8"; ".js"="application/javascript"; ".css"="text/css";
  ".png"="image/png"; ".jpg"="image/jpeg"; ".jpeg"="image/jpeg"; ".gif"="image/gif";
  ".svg"="image/svg+xml"; ".webp"="image/webp"; ".ico"="image/x-icon"; ".json"="application/json";
  ".woff"="font/woff"; ".woff2"="font/woff2"
}
while ($listener.IsListening) {
  try {
    $ctx = $listener.GetContext()
    $req = $ctx.Request; $res = $ctx.Response
    $path = [Uri]::UnescapeDataString($req.Url.AbsolutePath.TrimStart('/'))
    if ([string]::IsNullOrEmpty($path)) { $path = "index.html" }
    $file = Join-Path $root $path
    if ((Test-Path $file) -and -not (Get-Item $file).PSIsContainer) {
      $ext = [IO.Path]::GetExtension($file).ToLower()
      $res.ContentType = if ($mime.ContainsKey($ext)) { $mime[$ext] } else { "application/octet-stream" }
      $bytes = [IO.File]::ReadAllBytes($file)
      $res.ContentLength64 = $bytes.Length
      $res.OutputStream.Write($bytes, 0, $bytes.Length)
    } else {
      $res.StatusCode = 404
      $b = [Text.Encoding]::UTF8.GetBytes("404")
      $res.OutputStream.Write($b,0,$b.Length)
    }
    $res.OutputStream.Close()
  } catch { Write-Host "err: $_" }
}
