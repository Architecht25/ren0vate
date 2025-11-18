class PdfGenerationService
  def self.generate_from_html(html_content, filename: 'document.pdf')
    # Pour l'instant, on retourne le contenu HTML avec des styles print-friendly
    # Plus tard on pourra intégrer Puppeteer via un service externe ou une solution cloud
    
    # Styles CSS optimisés pour l'impression PDF
    printable_html = wrap_html_for_print(html_content)
    
    # Option 1: Retourner HTML optimisé pour impression navigateur
    { 
      content: printable_html, 
      content_type: 'text/html',
      headers: {
        'Content-Disposition' => "attachment; filename=\"#{filename}.html\"",
        'X-PDF-Generation' => 'browser-print'
      }
    }
  end

  private

  def self.wrap_html_for_print(content)
    <<~HTML
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <title>Ren0vate - Export PDF</title>
        <style>
          /* Reset et base */
          * { margin: 0; padding: 0; box-sizing: border-box; }
          
          body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            font-size: 12px;
            line-height: 1.4;
            color: #333;
            background: white;
            margin: 0;
            padding: 20px;
          }
          
          /* Styles d'impression */
          @media print {
            body { margin: 0; padding: 15px; }
            .no-print { display: none !important; }
            .page-break { page-break-before: always; }
            .page-break-after { page-break-after: always; }
          }
          
          /* Styles pour PDF */
          @page {
            size: A4;
            margin: 1.5cm;
          }
          
          /* Headers et titres */
          h1, h2, h3 {
            color: #2c5282;
            margin-bottom: 10px;
            page-break-after: avoid;
          }
          
          h1 { font-size: 24px; margin-bottom: 20px; }
          h2 { font-size: 18px; margin-bottom: 15px; }
          h3 { font-size: 16px; margin-bottom: 12px; }
          
          /* Tables */
          table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 15px;
            page-break-inside: avoid;
          }
          
          th, td {
            padding: 8px;
            border: 1px solid #ddd;
            text-align: left;
            vertical-align: top;
          }
          
          th {
            background-color: #f8f9fa;
            font-weight: 600;
            color: #2c5282;
          }
          
          /* Cards et sections */
          .card {
            border: 1px solid #e2e8f0;
            border-radius: 6px;
            margin-bottom: 15px;
            page-break-inside: avoid;
          }
          
          .card-header {
            background-color: #f8f9fa;
            padding: 10px 15px;
            border-bottom: 1px solid #e2e8f0;
            font-weight: 600;
            color: #2c5282;
          }
          
          .card-body {
            padding: 15px;
          }
          
          /* Utilities */
          .text-center { text-align: center; }
          .text-right { text-align: right; }
          .font-weight-bold { font-weight: 600; }
          .text-muted { color: #6c757d; }
          
          .mb-1 { margin-bottom: 0.25rem; }
          .mb-2 { margin-bottom: 0.5rem; }
          .mb-3 { margin-bottom: 1rem; }
          .mb-4 { margin-bottom: 1.5rem; }
          
          /* Logo et branding */
          .logo {
            max-height: 60px;
            margin-bottom: 20px;
          }
          
          .footer {
            position: fixed;
            bottom: 1cm;
            left: 1.5cm;
            right: 1.5cm;
            text-align: center;
            font-size: 10px;
            color: #6c757d;
            border-top: 1px solid #e2e8f0;
            padding-top: 10px;
          }
          
          /* Message d'instructions pour l'utilisateur */
          .print-instructions {
            background-color: #e3f2fd;
            border: 2px dashed #2196f3;
            padding: 15px;
            margin-bottom: 20px;
            border-radius: 6px;
            text-align: center;
          }
          
          @media print {
            .print-instructions { display: none; }
          }
        </style>
        
        <script>
          // Auto-prompt d'impression au chargement
          window.addEventListener('load', function() {
            setTimeout(function() {
              window.print();
            }, 500);
          });
        </script>
      </head>
      <body>
        <div class="print-instructions no-print">
          📄 <strong>Pour générer le PDF :</strong> Utilisez Ctrl+P (Cmd+P sur Mac) et sélectionnez "Enregistrer au format PDF"
        </div>
        
        #{content}
        
        <div class="footer">
          Document généré par Ren0vate - #{Time.current.strftime("%d/%m/%Y à %H:%M")} - ren0vate.be
        </div>
      </body>
      </html>
    HTML
  end
end