#!/usr/bin/env python3
"""Validate and persist user-selected MAGI assets.

One JSON request is accepted on stdin. Assets are content-addressed and copied
atomically into XDG-managed storage; settings retain only the managed asset ID.
"""
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import sys
import tempfile
import urllib.parse
import urllib.request
import xml.etree.ElementTree as ET

SVG_LIMIT = 256 * 1024
IMAGE_LIMIT = 5 * 1024 * 1024
ART_LIMIT = 4 * 1024 * 1024
ART_CACHE_LIMIT = 32 * 1024 * 1024
ART_CACHE_FILES = 64
SVG_TAGS = {"svg", "g", "path", "rect", "circle", "ellipse", "line", "polyline",
            "polygon", "defs", "linearGradient", "radialGradient", "stop",
            "clipPath", "mask", "title", "desc"}


def data_root():
    return Path(os.environ.get("XDG_DATA_HOME", Path.home() / ".local/share")) / "magi"


def cache_root():
    return Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache")) / "magi"


def local_path(value):
    parsed = urllib.parse.urlparse(value)
    if parsed.scheme not in ("", "file"):
        raise ValueError("Only local files can be imported")
    if parsed.netloc not in ("", "localhost"):
        raise ValueError("Remote file URLs are not supported")
    path = Path(urllib.request.url2pathname(parsed.path) if parsed.scheme else value).expanduser()
    if not path.is_file():
        raise ValueError("Selected asset is not a regular file")
    return path.resolve()


def image_extension(data):
    if data.startswith(b"\x89PNG\r\n\x1a\n"): return "png"
    if data.startswith(b"\xff\xd8\xff"): return "jpg"
    if data.startswith(b"RIFF") and data[8:12] == b"WEBP": return "webp"
    raise ValueError("Only PNG, JPEG and WebP images are supported")


def persist(data, directory, extension, prefix):
    digest = hashlib.sha256(data).hexdigest()
    directory.mkdir(parents=True, exist_ok=True, mode=0o700)
    destination = directory / f"{digest}.{extension}"
    if not destination.exists():
        fd, temporary = tempfile.mkstemp(prefix=".import-", dir=directory)
        try:
            with os.fdopen(fd, "wb") as output:
                os.fchmod(output.fileno(), 0o600)
                output.write(data)
                output.flush()
                os.fsync(output.fileno())
            os.replace(temporary, destination)
        finally:
            if os.path.exists(temporary): os.unlink(temporary)
    return {"assetId": f"{prefix}:{digest}.{extension}", "url": destination.as_uri()}


def import_image(value):
    path = local_path(value)
    data = path.read_bytes()
    if len(data) > IMAGE_LIMIT: raise ValueError("Avatar exceeds the 5 MiB limit")
    return persist(data, data_root() / "avatars", image_extension(data), "avatar")


def numeric_dimension(value):
    if value is None: return None
    match = re.fullmatch(r"\s*([0-9]+(?:\.[0-9]+)?)\s*(?:px)?\s*", value)
    return float(match.group(1)) if match else None


def import_svg(value):
    path = local_path(value)
    data = path.read_bytes()
    if len(data) > SVG_LIMIT: raise ValueError("SVG exceeds the 256 KiB limit")
    lowered = data.lower()
    if b"<!entity" in lowered:
        raise ValueError("SVG entities are not supported")
    # Common design tools emit the standard SVG 1.1 doctype despite the file
    # being self-contained. Strip that exact inert prolog before parsing while
    # continuing to reject internal subsets and arbitrary external DTDs.
    safe_doctype = re.compile(
        br'<!DOCTYPE\s+svg\s+PUBLIC\s+"-//W3C//DTD SVG 1\.1//EN"\s+'
        br'"http://www\.w3\.org/Graphics/SVG/1\.1/DTD/svg11\.dtd"\s*>', re.I)
    data = safe_doctype.sub(b"", data)
    if b"<!doctype" in data.lower():
        raise ValueError("Only the standard SVG 1.1 document type is supported")
    try: root = ET.fromstring(data)
    except ET.ParseError as error: raise ValueError(f"Invalid SVG: {error}")
    if root.tag.split("}")[-1] != "svg": raise ValueError("Asset root must be SVG")
    width, height = numeric_dimension(root.get("width")), numeric_dimension(root.get("height"))
    viewbox = root.get("viewBox", "").replace(",", " ").split()
    if len(viewbox) == 4:
        try: width, height = width or float(viewbox[2]), height or float(viewbox[3])
        except ValueError: raise ValueError("Invalid SVG viewBox")
    if not width or not height or width <= 0 or height <= 0 or width > 4096 or height > 4096:
        raise ValueError("SVG needs positive dimensions no larger than 4096×4096")
    elements = list(root.iter())
    if len(elements) > 512: raise ValueError("SVG contains too many elements")
    for element in elements:
        tag = element.tag.split("}")[-1]
        if tag not in SVG_TAGS: raise ValueError(f"Unsupported SVG element: {tag}")
        for name, value in element.attrib.items():
            local = name.split("}")[-1].lower()
            low_value = value.strip().lower()
            if local.startswith("on"): raise ValueError("SVG event handlers are not supported")
            if local in ("href", "xlink:href") and not low_value.startswith("#"):
                raise ValueError("External SVG references are not supported")
            for target in re.findall(r"url\((.*?)\)", low_value):
                if not target.strip(" '\"").startswith("#"):
                    raise ValueError("External SVG resources are not supported")
    return persist(data, data_root() / "icons", "svg", "icon")


def cache_artwork(value):
    parsed = urllib.parse.urlparse(value)
    if parsed.scheme in ("", "file"):
        data = local_path(value).read_bytes()
    elif parsed.scheme in ("http", "https"):
        request = urllib.request.Request(value, headers={"User-Agent": "MAGI/1"})
        with urllib.request.urlopen(request, timeout=5) as response:
            length = response.headers.get("Content-Length")
            if length and int(length) > ART_LIMIT: raise ValueError("Artwork exceeds the 4 MiB limit")
            data = response.read(ART_LIMIT + 1)
    else: raise ValueError("Unsupported artwork URL")
    if len(data) > ART_LIMIT: raise ValueError("Artwork exceeds the 4 MiB limit")
    directory = cache_root() / "artwork"
    result = persist(data, directory, image_extension(data), "artwork")
    Path(urllib.parse.urlparse(result["url"]).path).touch()
    files = sorted((item for item in directory.iterdir() if item.is_file()),
                   key=lambda item: item.stat().st_mtime, reverse=True)
    total = 0
    for index, item in enumerate(files):
        total += item.stat().st_size
        if index >= ART_CACHE_FILES or total > ART_CACHE_LIMIT:
            item.unlink(missing_ok=True)
    return result


def perform(request):
    operation = request.get("op")
    if operation == "avatar": return import_image(request["url"])
    if operation == "icon": return import_svg(request["url"])
    if operation == "artwork": return cache_artwork(request["url"])
    raise ValueError("Unknown asset operation")


if __name__ == "__main__":
    try: result = {"ok": True, **perform(json.loads(sys.stdin.readline()))}
    except Exception as error: result = {"ok": False, "error": str(error)}
    print(json.dumps(result), flush=True)
