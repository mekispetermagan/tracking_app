import zipfile
import os
import shutil

def fill_template(template_xml, output_xml, template_data):
    with open(template_xml) as file:
        content = file.read()

    for key in template_data:
        if key in content: print(key, "found.")
        content = content.replace(key, template_data[key])

    with open(output_xml, "w") as file:
        file.write(content)

def create_docx(doc_dir, output_docx):
    with zipfile.ZipFile(output_docx, 'w') as zip_ref:
        for folder, subfolders, files in os.walk(doc_dir):
            for file in files:
                file_path = os.path.join(folder, file)
                arcname = os.path.relpath(file_path, doc_dir)
                zip_ref.write(file_path, arcname)

def create_invoice(template_data, id):
    print(template_data)
    base_path = os.path.dirname(os.path.abspath(__file__))
    doc_dir = os.path.join(base_path, "invoice_extracted")
    template_xml = os.path.join(base_path, "document.xml")
    output_xml = os.path.join(doc_dir, "word/document.xml")
    output_docx = os.path.join(
        base_path,
        f"invoices/invoice_{id}_{template_data['{{number}}']}.docx"
        )
    signature_original = os.path.join(base_path, f"signatures/signature_{id}.png")
    signature_result = os.path.join(doc_dir, "word/media/image1.png")

    shutil.copyfile(signature_original, signature_result)

    fill_template(template_xml, output_xml, template_data)
    create_docx(doc_dir, output_docx)
    return output_docx
