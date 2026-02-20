const pdfParse = require('pdf-parse');
const fs = require('fs').promises;
const path = require('path');
const OpenAI = require('openai');

// Configuración
const openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });

/**
 * PROCESADOR DE PDFS PARA COTIZACIONES DE SEGUROS
 * 
 * Modelo usado: GPT-4o (OpenAI) - Mejor para extracción estructurada de documentos
 * Alternativa: Claude 3.5 Sonnet si OpenAI no está disponible
 */

class CotizacionProcessor {
  constructor() {
    this.promptSistema = `Eres un extractor experto de datos de cotizaciones de seguros colombianos.

Extrae la información en este JSON exacto:
{
  "aseguradora": "nombre exacto de la aseguradora",
  "ramo": "tipo de seguro (ej: Todo Riesgo Daños Materiales)",
  "prima_total": numero_sin_puntos_ni_comas,
  "prima_iva_incluido": numero_o_null,
  "valor_asegurado": numero_sin_puntos_ni_comas,
  "moneda": "COP" | "USD",
  "vigencia": {
    "desde": "YYYY-MM-DD",
    "hasta": "YYYY-MM-DD"
  },
  "coberturas": [
    {
      "nombre": "nombre exacto de la cobertura",
      "incluida": true | false,
      "sub_limite": numero_o_null,
      "deducible_porcentaje": numero_o_null,
      "deducible_minimo": numero_o_null,
      "observaciones": "string o null"
    }
  ],
  "exclusiones": ["array de exclusiones principales"],
  "condiciones_especiales": ["array de condiciones"],
  "clausulas_aplicadas": ["array de cláusulas mencionadas"]
}

REGLAS:
1. Si no encuentras un dato, usa null (NO inventes)
2. Los números deben ser enteros sin formato (45200000, no $45.200.000)
3. Para coberturas no incluidas explícitamente, usa "incluida": false
4. Captura TODAS las coberturas mencionadas en el documento
5. Si hay tablas, extrae fila por fila`;
  }

  /**
   * Extrae texto de un PDF
   * Modelo: pdf-parse (librería Node.js) - No usa IA, parsing nativo
   */
  async extraerTextoPDF(pdfPath) {
    try {
      const dataBuffer = await fs.readFile(pdfPath);
      const data = await pdfParse(dataBuffer);
      
      return {
        texto: data.text,
        numPaginas: data.numpages,
        info: data.info
      };
    } catch (error) {
      console.error('Error extrayendo PDF:', error);
      throw error;
    }
  }

  /**
   * Usa GPT-4o para estructurar los datos
   * Modelo: GPT-4o (OpenAI) - Mejor ratio calidad/costo para extracción documental
   * Alternativa: Claude 3.5 Sonnet (mejor para documentos muy largos)
   */
  async extraerDatosConLLM(texto) {
    try {
      const response = await openai.chat.completions.create({
        model: "gpt-4o",
        messages: [
          { role: "system", content: this.promptSistema },
          { role: "user", content: `Extrae los datos de esta cotización:\n\n${texto}` }
        ],
        temperature: 0.1, // Baja creatividad para extracción precisa
        response_format: { type: "json_object" }
      });

      const datosExtraidos = JSON.parse(response.choices[0].message.content);
      
      // Agregar metadata
      return {
        ...datosExtraidos,
        _metadata: {
          modelo_usado: "gpt-4o",
          tokens_usados: response.usage?.total_tokens || 0,
          fecha_extraccion: new Date().toISOString(),
          version_extractor: "1.0.0"
        }
      };
    } catch (error) {
      console.error('Error en LLM:', error);
      throw error;
    }
  }

  /**
   * Valida que los datos extraídos sean coherentes
   * Modelo: Reglas heurísticas (no IA) - Validación programática
   */
  validarDatos(datos) {
    const errores = [];
    const warnings = [];

    // Validaciones básicas
    if (!datos.aseguradora) errores.push("Falta nombre de aseguradora");
    if (!datos.prima_total || datos.prima_total <= 0) errores.push("Prima inválida");
    if (!datos.coberturas || datos.coberturas.length === 0) {
      warnings.push("No se detectaron coberturas");
    }

    // Validación de coherencia
    const coberturasIncluidas = datos.coberturas?.filter(c => c.incluida).length || 0;
    if (coberturasIncluidas === 0 && datos.coberturas?.length > 0) {
      warnings.push("Ninguna cobertura marcada como incluida - revisar");
    }

    return {
      valido: errores.length === 0,
      errores,
      warnings,
      requiere_revision_manual: errores.length > 0 || warnings.length > 2
    };
  }

  /**
   * Procesa un PDF completo end-to-end
   */
  async procesarCotizacion(pdfPath, metadata = {}) {
    console.log(`🔄 Procesando: ${path.basename(pdfPath)}`);
    
    try {
      // Paso 1: Extraer texto
      console.log('📄 Extrayendo texto del PDF...');
      const { texto, numPaginas } = await this.extraerTextoPDF(pdfPath);
      
      // Paso 2: Procesar con LLM
      console.log('🤖 Enviando a GPT-4o para extracción...');
      const datosExtraidos = await this.extraerDatosConLLM(texto);
      
      // Paso 3: Validar
      console.log('✅ Validando datos extraídos...');
      const validacion = this.validarDatos(datosExtraidos);
      
      // Resultado final
      const resultado = {
        exito: validacion.valido,
        datos: {
          ...datosExtraidos,
          ...metadata
        },
        validacion,
        estadisticas: {
          paginas_procesadas: numPaginas,
          caracteres_texto: texto.length,
          coberturas_detectadas: datosExtraidos.coberturas?.length || 0
        }
      };

      if (validacion.valido) {
        console.log('✨ Procesamiento exitoso');
      } else {
        console.warn('⚠️ Revisión manual requerida:', validacion.errores);
      }

      return resultado;

    } catch (error) {
      console.error('❌ Error en procesamiento:', error);
      return {
        exito: false,
        error: error.message,
        datos: null
      };
    }
  }

  /**
   * Procesa múltiples PDFs para un mismo cliente (comparativo)
   */
  async procesarComparativo(cliente, ramo, archivosPDF) {
    console.log(`🏗️ Construyendo comparativo para ${cliente} - ${ramo}`);
    
    const resultados = [];
    
    for (const pdfPath of archivosPDF) {
      const aseguradora = path.basename(pdfPath, '.pdf');
      const resultado = await this.procesarCotizacion(pdfPath, {
        cliente,
        ramo,
        aseguradora
      });
      
      if (resultado.exito) {
        resultados.push(resultado.datos);
      }
    }

    // Generar comparativo estructurado
    return this.generarComparativoJSON(resultados);
  }

  /**
   * Genera estructura comparativa homologando coberturas
   * Nota: Esto es una versión básica, la homologación avanzada usa embeddings
   */
  generarComparativoJSON(cotizaciones) {
    // Extraer todas las coberturas únicas
    const todasCoberturas = new Set();
    cotizaciones.forEach(cot => {
      cot.coberturas?.forEach(cob => {
        todasCoberturas.add(cob.nombre);
      });
    });

    // Construir matriz comparativa
    const matriz = Array.from(todasCoberturas).map(nombreCobertura => {
      const fila = {
        cobertura: nombreCobertura,
        comparacion: {}
      };

      cotizaciones.forEach(cot => {
        const cobertura = cot.coberturas?.find(c => 
          c.nombre.toLowerCase() === nombreCobertura.toLowerCase()
        );
        
        fila.comparacion[cot.aseguradora] = cobertura || {
          incluida: false,
          observaciones: "No incluida"
        };
      });

      return fila;
    });

    return {
      cliente: cotizaciones[0]?.cliente,
      ramo: cotizaciones[0]?.ramo,
      fecha_comparativo: new Date().toISOString(),
      resumen: {
        total_cotizaciones: cotizaciones.length,
        aseguradoras: cotizaciones.map(c => c.aseguradora),
        rango_primas: {
          min: Math.min(...cotizaciones.map(c => c.prima_total)),
          max: Math.max(...cotizaciones.map(c => c.prima_total))
        }
      },
      cotizaciones,
      matriz_comparativa: matriz
    };
  }
}

// Exportar para uso en N8N o scripts
module.exports = CotizacionProcessor;

// Ejemplo de uso standalone
async function main() {
  const processor = new CotizacionProcessor();
  
  // Ejemplo: Procesar un solo PDF
  // const resultado = await processor.procesarCotizacion('./cotizacion-sura.pdf');
  // console.log(JSON.stringify(resultado, null, 2));
  
  // Ejemplo: Procesar comparativo completo
  // const comparativo = await processor.procesarComparativo(
  //   'Constructora Bogotá',
  //   'Todo Riesgo Daños Materiales',
  //   ['./sura.pdf', './allianz.pdf', './liberty.pdf']
  // );
  // console.log(JSON.stringify(comparativo, null, 2));
}

if (require.main === module) {
  main().catch(console.error);
}