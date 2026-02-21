# 🔬 Research: Synthesia API + Integración OpenClaw/N8N

**Fecha:** 21 Febrero 2026  
**Investigador:** Kowalski 2.0 🐧  
**Status:** Prioridad Alta

---

## 📋 RESUMEN EJECUTIVO

| Aspecto | Detalle |
|---------|---------|
| **Proveedor** | Synthesia.io |
| **Tipo** | API REST + SDKs |
| **Precio** | $22-30/mes (Starter) → $67-89/mes (Enterprise) |
| **Ventaja vs HeyGen** | Sandbox gratuito para testing, mejor documentación |
| **Integración N8N** | ✅ Viable via HTTP Request Node |
| **Integración OpenClaw** | ✅ Viable via exec() + curl o SDK Node.js |

---

## 🎯 ¿Por qué Synthesia vs HeyGen?

| Feature | Synthesia | HeyGen |
|---------|-----------|--------|
| **Testing gratuito** | ✅ Sandbox con créditos | ❌ Solo trial 14 días |
| **Documentación API** | ✅ Excelente | ⚠️ Regular |
| **Latencia** | ~30-60s por video | ~40-90s por video |
| **Avatares** | 230+ | 100+ |
| **Idiomas** | 130+ | 50+ |
| **Personalización voz** | ✅ SSML avanzado | ⚠️ Básico |
| **Webhook callbacks** | ✅ Sí | ✅ Sí |

**Veredicto:** Synthesia es mejor para prototipar y testear sin compromiso.

---

## 🔑 API ENDPOINTS CLAVE

### Base URL
```
https://api.synthesia.io/v2
```

### Autenticación
```http
Authorization: ${API_KEY}
Content-Type: application/json
```

### 1. Crear Video (POST /videos)
```http
POST https://api.synthesia.io/v2/videos
Authorization: <your_api_key>
Content-Type: application/json

{
  "test": true,  // <-- Modo sandbox (no consume créditos)
  "input": [
    {
      "scriptText": "Hola JuanPa, soy tu avatar de Synthesia",
      "avatar": "anna_costume1_cameraA",
      "background": "green_screen",
      "voice": "es-ES-ElviraNeural"
    }
  ]
}
```

**Respuesta:**
```json
{
  "id": "c8a8dfb5-9a38-4c20-b41e-1234567890ab",
  "status": "in_progress",
  "download": null,
  "createdAt": "2026-02-21T02:00:00.000Z",
  "lastUpdatedAt": "2026-02-21T02:00:00.000Z"
}
```

### 2. Consultar Estado (GET /videos/{id})
```http
GET https://api.synthesia.io/v2/videos/{video_id}
Authorization: <your_api_key>
```

**Respuesta cuando está listo:**
```json
{
  "id": "c8a8dfb5-9a38-4c20-b41e-1234567890ab",
  "status": "complete",
  "download": "https://cdn.synthesia.io/.../video.mp4",
  "createdAt": "2026-02-21T02:00:00.000Z",
  "duration": 4.56
}
```

### 3. Listar Avatares (GET /avatars)
```http
GET https://api.synthesia.io/v2/avatars?limit=100
Authorization: <your_api_key>
```

### 4. Listar Voces (GET /voices)
```http
GET https://api.synthesia.io/v2/voices
Authorization: <your_api_key>
```

**Voces en Español destacadas:**
- `es-ES-ElviraNeural` - Femenina, español de España
- `es-MX-DaliaNeural` - Femenina, español de México
- `es-ES-AlvaroNeural` - Masculina, español de España
- `es-MX-JorgeNeural` - Masculina, español de México

---

## 🔧 INTEGRACIÓN CON N8N

### Opción A: HTTP Request Node (Nativo)

```json
{
  "nodes": [
    {
      "parameters": {
        "method": "POST",
        "url": "https://api.synthesia.io/v2/videos",
        "sendHeaders": true,
        "headerParameters": {
          "parameters": [
            {
              "name": "Authorization",
              "value": "={{ $env.SYNTHESIA_API_KEY }}"
            },
            {
              "name": "Content-Type",
              "value": "application/json"
            }
          ]
        },
        "sendBody": true,
        "contentType": "json",
        "bodyParameters": {
          "test": "={{ $json.modo_test }}",
          "input": [
            {
              "scriptText": "={{ $json.script }}",
              "avatar": "={{ $json.avatar || 'anna_costume1_cameraA' }}",
              "voice": "={{ $json.voice || 'es-ES-ElviraNeural' }}",
              "background": "={{ $json.background || 'green_screen' }}"
            }
          ]
        }
      },
      "name": "Synthesia Create Video",
      "type": "n8n-nodes-base.httpRequest",
      "typeVersion": 4.1
    }
  ]
}
```

### Opción B: Custom N8N Node (Avanzado)

Instalar community node:
```bash
npm install n8n-nodes-synthesia
```

O usar HTTP request como arriba (recomendado).

---

## 🔧 INTEGRACIÓN CON OPENCLAW

### Opción A: Exec + cURL (Rápido)

```javascript
// En OpenClaw, dentro de una función:
const SYNTESIA_API_KEY = process.env.SYNTHESIA_API_KEY;

const response = await exec({
  command: `curl -X POST https://api.synthesia.io/v2/videos \\
    -H "Authorization: ${SYNTESIA_API_KEY}" \\
    -H "Content-Type: application/json" \\
    -d '{
      "test": true,
      "input": [{
        "scriptText": "Hola desde OpenClaw",
        "avatar": "anna_costume1_cameraA",
        "voice": "es-ES-ElviraNeural"
      }]
    }'`
});

const videoData = JSON.parse(response.stdout);
```

### Opción B: Node.js SDK (Mejor)

```javascript
// Instalar: npm install synthesia

const { SynthesiaClient } = require('synthesia');

const client = new SynthesiaClient({
  apiKey: process.env.SYNTHESIA_API_KEY
});

// Crear video
const video = await client.videos.create({
  test: true, // Modo sandbox
  input: [{
    scriptText: 'Hola JuanPa, este es un video generado desde OpenClaw',
    avatar: 'anna_costume1_cameraA',
    voice: 'es-ES-ElviraNeural',
    background: 'green_screen'
  }]
});

console.log('Video ID:', video.id);
console.log('Status:', video.status);

// Esperar y descargar (polling)
const finalVideo = await client.videos.wait(video.id);
console.log('Download URL:', finalVideo.download);
```

### Opción C: Python SDK (Si usas Python en OpenClaw)

```python
# pip install synthesia

from synthesia import SynthesiaClient

client = SynthesiaClient(api_key=os.environ['SYNTHESIA_API_KEY'])

video = client.videos.create(
    test=True,
    input=[{
        "scriptText": "Hola desde Python en OpenClaw",
        "avatar": "anna_costume1_cameraA",
        "voice": "es-ES-ElviraNeural"
    }]
)

print(f"Video creado: {video.id}")
```

---

## 💰 PLANES Y PRECIOS (Feb 2026)

| Plan | Precio | Videos/mes | Características |
|------|--------|------------|-----------------|
| **Free/Trial** | $0 | 10-20 test | Solo sandbox, con watermark |
| **Starter** | $22/mes | ~30 | Sin watermark, 1080p |
| **Creator** | $67/mes | ~100 | API access, custom avatars |
| **Enterprise** | Custom | Ilimitado | SSO, SLA, soporte prioridad |

**Recomendación para Aztec Lab:** Empezar con Creator ($67/mes) para tener API key dedicada.

---

## 🚀 WORKFLOW COMPLETO: N8N + Synthesia

### Paso 1: Trigger (Webhook o Schedule)
```
Recibe: { "script": "texto a convertir", "avatar": "nombre", "notify_email": "user@mail.com" }
```

### Paso 2: HTTP Request → Synthesia Create
- POST a /videos
- Guardar video_id

### Paso 3: Wait (30-60s)
- Delay node de 60 segundos

### Paso 4: HTTP Request → Synthesia Get Status
- GET /videos/{id}
- Verificar status == "complete"

### Paso 5: If/Else
- Si complete → continuar
- Si error → notificar

### Paso 6: Download Video
- HTTP Request GET al download URL
- Guardar en S3/MinIO

### Paso 7: Send Email
- Notificar al usuario con link del video

---

## 📊 COMPARATIVA: Synthesia vs Alternativas

| Criterio | Synthesia | HeyGen | D-ID | Colossyan |
|----------|-----------|--------|------|-----------|
| **Precio entrada** | 💰💰 | 💰💰💰 | 💰 | 💰💰 |
| **Calidad avatar** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ |
| **Latencia** | ⚡⚡⚡ | ⚡⚡ | ⚡⚡⚡⚡ | ⚡⚡ |
| **API madura** | ✅✅✅ | ✅✅ | ✅ | ✅✅ |
| **Español nativo** | ✅✅✅ | ✅✅ | ✅ | ✅✅ |
| **Test gratuito** | ✅✅✅ | ✅ | ✅ | ✅ |

**Ganador:** Synthesia para proyectos serios y escalables.

---

## ⚠️ LIMITACIONES Y CONSIDERACIONES

1. **Rate Limits:**
   - 10 requests/minuto en Starter
   - 100 requests/minuto en Enterprise

2. **Tamaño máximo script:**
   - ~1000 caracteres por escena
   - Máximo 10 escenas por video

3. **Formatos de salida:**
   - MP4 (H.264)
   - Resolución: 720p, 1080p, 4K (Enterprise)

4. **Webhooks:**
   - Synthesia puede llamar webhook cuando video esté listo
   - Evita polling constante

---

## 🔗 RECURSOS ÚTILES

- **Docs:** https://docs.synthesia.io/
- **API Reference:** https://docs.synthesia.io/reference
- **Pricing:** https://www.synthesia.io/pricing
- **Avatares:** https://www.synthesia.io/features/avatars

---

## ✅ CHECKLIST DE IMPLEMENTACIÓN

- [ ] Crear cuenta en Synthesia.io
- [ ] Obtener API Key (modo test)
- [ ] Probar primer video con curl
- [ ] Implementar en N8N (HTTP Request)
- [ ] Implementar en OpenClaw (SDK Node.js)
- [ ] Configurar webhook callback
- [ ] Integrar con storage (S3/MinIO)
- [ ] Setup notificaciones (Email/WhatsApp)
- [ ] Testing con usuarios beta
- [ ] Upgrade a plan Creator si funciona

---

**Investigación completada:** 2:15 AM 🌙
**Próximo paso:** Implementación del workflow N8N + pruebas