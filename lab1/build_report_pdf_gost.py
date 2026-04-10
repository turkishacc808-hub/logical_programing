#!/usr/bin/env python3
"""Build REPORT.pdf from REPORT.md using GOST-like layout."""

from __future__ import annotations

import io
import re
import subprocess
from pathlib import Path

import markdown
from pypdf import PdfReader, PdfWriter
from reportlab.pdfgen import canvas

ROOT = Path(__file__).resolve().parent
MD_PATH = ROOT / "REPORT.md"
HTML_PATH = ROOT / "REPORT.html"
RAW_PDF_PATH = ROOT / "REPORT_raw.pdf"
PDF_PATH = ROOT / "REPORT.pdf"

CHROME = Path("/Applications/Google Chrome.app/Contents/MacOS/Google Chrome")


def build_html() -> None:
    md_text = MD_PATH.read_text(encoding="utf-8")
    body = markdown.markdown(md_text, extensions=["fenced_code", "tables"])

    # Prevent paragraph indentation for standalone images.
    body = re.sub(r"<p>(\s*<img[^>]+>\s*)</p>", r'<div class="img-block">\1</div>', body)

    html = f"""<!doctype html>
<html lang="ru">
<head>
<meta charset="utf-8" />
<title>Отчет ЛР1</title>
<style>
@page {{
  size: A4;
  margin: 20mm 15mm 20mm 30mm;
}}
body {{
  font-family: "Times New Roman", serif;
  font-size: 13pt;
  line-height: 1.38;
  text-align: justify;
  margin: 0;
  padding: 0;
}}
h1, h2, h3 {{
  font-weight: normal;
  text-align: left;
  margin-top: 12pt;
  margin-bottom: 6pt;
  text-indent: 0;
}}
h1 {{
  text-align: center;
  font-size: 15pt;
  margin-top: 0;
}}
h2 {{ font-size: 13pt; }}
h3 {{ font-size: 13pt; }}
p {{
  margin: 0 0 6pt 0;
  text-indent: 1.25cm;
}}
ul, ol {{
  margin: 0 0 6pt 0;
  padding-left: 1.25cm;
}}
li {{
  margin: 0 0 3pt 0;
}}
table {{
  width: 100%;
  border-collapse: collapse;
  margin: 4pt 0 8pt 0;
  page-break-inside: avoid;
}}
td {{
  width: 50%;
  vertical-align: top;
  padding: 4pt;
}}
table img {{
  width: 88%;
  margin: 4pt auto;
  display: block;
}}
.tree-figure {{
  margin: 6pt 0 8pt 0;
  text-indent: 0;
}}
.tree-image {{
  width: 68%;
  margin: 0 auto;
  display: block;
}}
code, pre {{
  font-family: "Courier New", monospace;
  font-size: 10pt;
}}
pre {{
  text-indent: 0;
  margin: 4pt 0 8pt 0;
  padding: 6pt;
  border: 1px solid #ccc;
  white-space: pre-wrap;
}}
.img-block {{
  margin: 6pt 0 10pt 0;
  text-indent: 0;
  page-break-inside: avoid;
}}
img {{
  width: 100%;
  height: auto;
  border: 1px solid #888;
  image-rendering: auto;
}}
</style>
</head>
<body>
{body}
</body>
</html>
"""
    HTML_PATH.write_text(html, encoding="utf-8")


def print_html_to_pdf() -> None:
    file_url = HTML_PATH.resolve().as_uri()
    cmd = [
        str(CHROME),
        "--headless",
        "--headless=new",
        "--disable-gpu",
        "--allow-file-access-from-files",
        "--no-pdf-header-footer",
        "--print-to-pdf-no-header",
        f"--print-to-pdf={RAW_PDF_PATH}",
        file_url,
    ]
    subprocess.run(cmd, check=True, capture_output=True, text=True)


def add_page_numbers() -> int:
    reader = PdfReader(str(RAW_PDF_PATH))
    writer = PdfWriter()

    for idx, page in enumerate(reader.pages, start=1):
        if idx >= 2:
            width = float(page.mediabox.width)
            height = float(page.mediabox.height)
            packet = io.BytesIO()
            c = canvas.Canvas(packet, pagesize=(width, height))
            c.setFont("Times-Roman", 12)
            c.drawCentredString(width / 2, 20, str(idx))
            c.save()
            packet.seek(0)
            overlay = PdfReader(packet).pages[0]
            page.merge_page(overlay)
        writer.add_page(page)

    with PDF_PATH.open("wb") as f:
        writer.write(f)

    return len(reader.pages)


def main() -> None:
    build_html()
    print_html_to_pdf()
    pages = add_page_numbers()
    print(f"Built: {PDF_PATH}")
    print(f"Pages: {pages}")


if __name__ == "__main__":
    main()
