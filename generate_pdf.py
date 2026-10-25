from fpdf import FPDF
import markdown
import re

with open("README.md", "r") as f:
    md_content = f.read()

# Convert markdown to HTML first
html = markdown.markdown(md_content, extensions=["tables", "fenced_code", "codehilite"])

# Simple HTML to text conversion for PDF
def html_to_text(html):
    # Remove tags, keep content
    html = re.sub(r'<code>(.*?)</code>', r'\1', html, flags=re.DOTALL)
    html = re.sub(r'<pre>(.*?)</pre>', r'\1', html, flags=re.DOTALL)
    html = re.sub(r'<h1>(.*?)</h1>', r'\1\n', html, flags=re.DOTALL)
    html = re.sub(r'<h2>(.*?)</h2>', r'\1\n', html, flags=re.DOTALL)
    html = re.sub(r'<h3>(.*?)</h3>', r'\1\n', html, flags=re.DOTALL)
    html = re.sub(r'<strong>(.*?)</strong>', r'\1', html, flags=re.DOTALL)
    html = re.sub(r'<em>(.*?)</em>', r'\1', html, flags=re.DOTALL)
    html = re.sub(r'<li>(.*?)</li>', r'- \1\n', html, flags=re.DOTALL)
    html = re.sub(r'<p>(.*?)</p>', r'\1\n\n', html, flags=re.DOTALL)
    html = re.sub(r'<br\s*/?>', '\n', html, flags=re.DOTALL)
    html = re.sub(r'<[^>]+>', '', html)
    html = re.sub(r'\n{3,}', '\n\n', html)
    return html

text = html_to_text(html)

# Create PDF
pdf = FPDF()
pdf.set_auto_page_break(auto=True, margin=15)
pdf.add_page()
pdf.set_font("Courier", size=10)
pdf.multi_cell(0, 5, text)
pdf.output("evilginx-production-guide.pdf")
print("PDF created: evilginx-production-guide.pdf")