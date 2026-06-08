from pdf2docx import Converter
import os

pdf_file = "Module_4_Elective_Notes.pdf"
docx_file = "Module_4_Elective_Notes.docx"

print(f"Converting {pdf_file} to {docx_file}...")
cv = Converter(pdf_file)
cv.convert(docx_file)      
cv.close()
print("Conversion complete!")
