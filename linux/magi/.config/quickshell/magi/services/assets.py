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
PACK_MANIFEST_LIMIT = 64 * 1024
PACK_ID = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")
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


def validate_svg(data, canonical=True):
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
    if canonical:
        try: canonical_box = [float(value) for value in viewbox] == [0.0, 0.0, 24.0, 24.0]
        except ValueError: canonical_box = False
        if not canonical_box:
            raise ValueError('UI icons require viewBox="0 0 24 24"')
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
    return data


def import_svg(value):
    path = local_path(value)
    return persist(validate_svg(path.read_bytes()), data_root() / "icons", "svg", "icon")


def pack_manifest(value):
    path = local_path(value)
    if path.stat().st_size > PACK_MANIFEST_LIMIT:
        raise ValueError("Icon-pack manifest exceeds 64 KiB")
    try: manifest = json.loads(path.read_text())
    except (UnicodeDecodeError, json.JSONDecodeError) as error:
        raise ValueError(f"Invalid icon-pack manifest: {error}")
    if not isinstance(manifest, dict) or manifest.get("formatVersion") != 1:
        raise ValueError("Unsupported icon-pack manifest version")
    pack_id = manifest.get("id")
    if not isinstance(pack_id, str) or not PACK_ID.fullmatch(pack_id) or pack_id == "magi-legacy":
        raise ValueError("Icon-pack ID must be lowercase kebab-case")
    label = manifest.get("displayName")
    if not isinstance(label, str) or not label.strip() or len(label) > 80:
        raise ValueError("Icon pack needs a display name")
    parent = manifest.get("parent", "magi-legacy")
    if not isinstance(parent, str) or not PACK_ID.fullmatch(parent) or parent == pack_id:
        raise ValueError("Invalid icon-pack parent")
    roles = manifest.get("roles")
    if not isinstance(roles, dict) or not roles or len(roles) > 256:
        raise ValueError("Icon pack needs 1–256 role mappings")
    checked = {}
    normalized_roles = {}
    for role, descriptor in roles.items():
        if not isinstance(role, str) or not PACK_ID.fullmatch(role):
            raise ValueError("Icon roles must be lowercase kebab-case")
        if isinstance(descriptor, str):
            filename, color_mode = descriptor, "semantic"
        elif isinstance(descriptor, dict):
            filename = descriptor.get("asset")
            color_mode = descriptor.get("colorMode", "semantic")
            if color_mode not in ("semantic", "fixed"):
                raise ValueError("Icon color mode must be semantic or fixed")
        else:
            raise ValueError("Icon role mappings must name an SVG asset")
        if not isinstance(filename, str) or not re.fullmatch(r"[a-z0-9]+(?:-[a-z0-9]+)*\.svg", filename):
            raise ValueError("Icon filenames must be lowercase kebab-case SVG names")
        asset = (path.parent / filename).resolve()
        if asset.parent != path.parent.resolve() or not asset.is_file():
            raise ValueError(f"Missing local pack asset: {filename}")
        checked[filename] = validate_svg(asset.read_bytes())
        normalized_roles[role] = {"asset": filename, "colorMode": color_mode}
    clean = {"formatVersion": 1, "id": pack_id, "displayName": label.strip(),
             "parent": parent, "roles": normalized_roles}
    for field in ("author", "description", "version"):
        value = manifest.get(field, "")
        if value is not None and (not isinstance(value, str) or len(value) > 240):
            raise ValueError(f"Invalid icon-pack {field}")
        if value: clean[field] = value
    return clean, checked


def import_pack(value):
    manifest, assets = pack_manifest(value)
    root = data_root() / "icon-packs"
    destination = root / manifest["id"]
    if destination.exists():
        raise ValueError("An icon pack with this ID is already installed")
    root.mkdir(parents=True, exist_ok=True, mode=0o700)
    temporary = Path(tempfile.mkdtemp(prefix=".pack-", dir=root))
    try:
        for filename, data in assets.items():
            (temporary / filename).write_bytes(data)
        (temporary / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
        os.rename(temporary, destination)
    finally:
        if temporary.exists(): shutil.rmtree(temporary)
    return {"assetId": "pack:" + manifest["id"], "url": (destination / "manifest.json").as_uri()}


def list_packs():
    packs = []
    root = data_root() / "icon-packs"
    if root.is_dir():
        for directory in sorted(root.iterdir()):
            try:
                manifest = json.loads((directory / "manifest.json").read_text())
                if directory.name != manifest["id"]: continue
                roles = {}
                for role, descriptor in manifest["roles"].items():
                    if isinstance(descriptor, str):
                        filename, color_mode = descriptor, "semantic"
                    elif isinstance(descriptor, dict):
                        filename = descriptor.get("asset", "")
                        color_mode = descriptor.get("colorMode", "semantic")
                    else: continue
                    if color_mode not in ("semantic", "fixed"):
                        continue
                    if (directory / filename).is_file():
                        roles[role] = {"kind": "managed-svg", "path": filename,
                                       "colorMode": color_mode}
                packs.append({"id": manifest["id"], "label": manifest["displayName"],
                    "author": manifest.get("author", ""), "description": manifest.get("description", ""),
                    "version": manifest.get("version", ""), "parent": manifest.get("parent", "magi-legacy"),
                    "baseUrl": directory.as_uri() + "/", "roles": roles, "modules": {}, "assets": {}})
            except (OSError, KeyError, json.JSONDecodeError):
                continue
    return {"packs": packs}


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
    if operation == "icon-pack": return import_pack(request["url"])
    if operation == "pack-list": return list_packs()
    if operation == "artwork": return cache_artwork(request["url"])
    raise ValueError("Unknown asset operation")


if __name__ == "__main__":
    try: result = {"ok": True, **perform(json.loads(sys.stdin.readline()))}
    except Exception as error: result = {"ok": False, "error": str(error)}
    print(json.dumps(result), flush=True)
