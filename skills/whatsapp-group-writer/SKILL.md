# Skill: WhatsApp Group Writer

Write contextual, engaging messages for WhatsApp groups with proper formatting, mentions, and group dynamics awareness.

## When to Use

Use this skill when you need to:
- Post updates in professional/business WhatsApp groups
- Share announcements with proper formatting
- Respond to messages in group context
- Create polls or calls-to-action in groups
- Manage community interactions at scale

## What It Does

1. Formats messages for WhatsApp (markdown, emojis, line breaks)
2. Handles @mentions for specific participants
3. Adapts tone to group context (professional vs casual)
4. Creates engaging polls and questions
5. Manages reply threads and context
6. Optimizes for mobile readability

## Prerequisites

- WhatsApp Business API access or WhatsApp Web integration
- Understanding of group participant roles
- Knowledge of group norms and etiquette

## Usage Examples

### Basic: Announcement Post

```javascript
// Post an announcement in a business group
const message = await whatsappGroup.write({
  type: 'announcement',
  title: 'Nueva Funcionalidad Disponible',
  content: 'Hemos lanzado la integración con Synthesia para videos automáticos.',
  action: 'Prueba la demo aquí: [link]',
  urgency: 'normal', // low, normal, high
  groupContext: 'clientes-aztec-lab'
});

// Send via WhatsApp tool
await message.send({ target: 'clientes-aztec-lab' });
```

### Advanced: Interactive Update with Mentions

```javascript
// Update with specific mentions for action items
const update = await whatsappGroup.write({
  type: 'update',
  title: '🚀 Sprint Review - Semana 3',
  sections: [
    {
      title: '✅ Completado',
      items: ['Dashboard de comparativos', 'API de Synthesia']
    },
    {
      title: '🔄 En Progreso',
      items: ['LinkedIn automation', 'GitHub skills']
    },
    {
      title: '📋 Pendiente',
      items: ['Testing con usuarios'],
      assignee: '@juanpa'
    }
  ],
  mentions: ['juanpa', 'martin'],
  cta: 'Reunión mañana 10am para revisar'
});
```

### Poll/Message for Engagement

```javascript
// Create an engaging question/poll
const poll = await whatsappGroup.write({
  type: 'poll',
  question: '¿Qué feature quieren ver primero?',
  options: [
    '🎥 Videos automáticos con Synthesia',
    '📊 Dashboard de analytics',
    '🤖 Nuevo agente de IA',
    '🔌 Integración con Zapier'
  ],
  allowMultiple: false,
  context: 'Estamos priorizando el roadmap Q1'
});
```

## Message Types

| Type | Use Case | Format |
|------|----------|--------|
| `announcement` | Important updates | Bold header + bullet points |
| `update` | Progress reports | Sections with emojis |
| `question` | Engagement/feedback | Single question + context |
| `poll` | Decision making | Numbered options |
| `reminder` | Follow-ups | Urgency indicator + action |
| `welcome` | New member greeting | Friendly + resources |
| `goodbye` | Departure message | Gracious + contact info |

## Formatting Guide

### WhatsApp Markdown

```
*bold text*           → Bold
_italic text_        → Italic
~strikethrough~      → Strikethrough
```monospace```      → Code block
```

### Best Practices

✅ **DO:**
- Use emojis as bullet points (• → ✅)
- Keep paragraphs to 2-3 lines max
- Use line breaks for readability
- Mention people with @name when relevant
- Include clear CTAs

❌ **DON'T:**
- Send walls of text
- Overuse caps lock
- Spam with too many messages
- Use @all unless truly urgent
- Send sensitive info in groups

## Group Context Awareness

The skill adapts based on group type:

### Professional/Business Groups
- Formal but approachable tone
- Structured updates with clear headers
- Action items with owners
- Professional emojis (📊 ✅ 🎯)

### Client/Customer Groups
- Service-oriented language
- Quick value propositions
- Easy CTAs
- Friendly but respectful

### Internal Team Groups
- Casual, friendly tone
- Inside jokes acceptable
- Quick updates
- Emoji-heavy acceptable

### Community/Interest Groups
- Engaging, conversational
- Questions to spark discussion
- Resource sharing
- Inclusive language

## Template Examples

### Weekly Update Template

```
*📊 Weekly Update - [Semana X]*

*✅ Hecho:*
• Item 1
• Item 2

*🔄 En progreso:*
• Item 3 @[owner]

*📅 Próxima semana:*
• Lanzamiento de [feature]
• Reunión de planning

¿Dudas? 👇
```

### Launch Announcement Template

```
🚀 *¡Nuevo lanzamiento!*

*[Nombre del Producto/Feature]*

*[Breve descripción del valor]*

*✨ Características:*
• Feature 1
• Feature 2
• Feature 3

*🔗 Acceso:* [link]

*💬 Soporte:* Escribe a @soporte

¡Esperamos tu feedback! 🙌
```

### Urgent Alert Template

```
⚠️ *IMPORTANTE*

[Mensaje claro y conciso]

*Acción requerida:*
[Qué deben hacer]

*Antes de:* [fecha/hora]

*Dudas:* @contacto
```

## Integration Examples

### With N8N Workflow

```json
{
  "nodes": [
    {
      "name": "Format WhatsApp Message",
      "type": "code",
      "parameters": {
        "jsCode": "return whatsappGroup.write({ type: 'update', title: 'Nuevo Lead', content: input.leadInfo });"
      }
    },
    {
      "name": "Send to WhatsApp",
      "type": "whatsapp-send",
      "parameters": {
        "group": "ventas-team",
        "message": "={{ $json.formatted }}"
      }
    }
  ]
}
```

### With OpenClaw Session

```javascript
// Automated response in group context
const groupMessage = await whatsappGroup.write({
  type: 'reply',
  replyTo: messageId,
  content: 'Recibido, lo reviso y te confirmo en 30 minutos',
  context: previousMessages
});

await message.send({
  target: groupId,
  content: groupMessage
});
```

## Common Patterns

### 1. Daily Standup Format

```
*📅 Daily - [Nombre]*

*Ayer:*
• Tarea 1 ✅
• Tarea 2 🔄

*Hoy:*
• Tarea 3
• Tarea 4

*Bloqueos:*
• Ninguno / [descripción]
```

### 2. Client Onboarding Welcome

```
👋 *¡Bienvenido/a [Nombre]!*

Estás en el grupo exclusivo de [Programa/Servicio].

*📚 Recursos:*
• Guía de inicio: [link]
• Calendario: [link]
• Soporte: @admin

*📅 Próximos pasos:*
1. Revisar materiales
2. Completar perfil
3. Unirte a la llamada de bienvenida

¿Preguntas? Estamos aquí para ayudar 🙌
```

### 3. Event Reminder

```
⏰ *Recordatorio: [Nombre del Evento]*

*📅 Fecha:* [Fecha]
*🕐 Hora:* [Hora]
*🔗 Link:* [URL]

*📝 Agenda:*
• Punto 1
• Punto 2

*Nos vemos allí!* 👋
```

## Troubleshooting

**Messages appear as plain text**
- WhatsApp doesn't support all markdown
- Use *bold* and _italic_ only
- Code blocks with ``` work on mobile

**Mentions not working**
- Ensure contact is saved in phone
- Use exact name as saved: @Juan Pablo
- Some WhatsApp versions handle mentions differently

**Formatting looks different on desktop vs mobile**
- Mobile supports more formatting
- Test messages on both platforms
- Use line breaks liberally for mobile

## Security & Privacy

⚠️ **Never share in WhatsApp groups:**
- Passwords or credentials
- Financial information
- Personal data of third parties
- Confidential business strategies

✅ **Safe to share:**
- Public links
- General updates
- Meeting times
- Public resources

## References

- WhatsApp Business API: https://business.whatsapp.com/products/business-platform
- WhatsApp Markdown: https://faq.whatsapp.com/general/chats/how-to-format-your-messages
- Group Etiquette: https://blog.whatsapp.com/communities/new-group-features