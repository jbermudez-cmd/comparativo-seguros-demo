---
name: claude-mission-control
description: Run long-form coding execution with Claude Code using a Mission Control workflow (PRD-driven, story queue, tmux persistent session, cron-based heartbeat cycle, and dashboard sync).
---

# Claude Mission Control

## Cuándo usar este skill

**SIEMPRE** que haya un desarrollo serio o robusto. No usar subagentes para código — usar Claude Code via tmux.

## Workflow completo

### Fase 1: Preparación
1. Crear PRD (`plans/PRD-<proyecto>.md`) — objetivo, contexto, stack, features, criterios de éxito
2. Descomponer en User Stories (`mission-control/stories.yaml`) — outcome-driven, con acceptance criteria medibles, priorizadas P0-P3
3. Registrar proyecto en `mission-control/projects.yaml`

### Fase 2: Ejecución (Claude Code en tmux)
4. Crear sesión tmux: `tmux new-session -s claude-mc`
5. Lanzar Claude Code con prompt estructurado (referencia al PRD + UN story + acceptance criteria + comando de validación)
6. Claude Code trabaja solo

### Fase 3: Ciclo de crons
7. Cada 1-5 min, revisar tmux (`tmux capture-pane -t claude-mc -p -S -50`):
   - Pide aprobación → responder Y/N
   - Hace pregunta → responder con contexto del PRD
   - Error → diagnosticar, dar instrucción correctiva
   - Terminó story → validar build, commit, siguiente story
   - Sigue trabajando → no hacer nada
   - Colgado >10 min → kill + relanzar con scope más chico

8. Reportar al humano solo cuando es relevante (story done, blocker, decisión requerida)

### Fase 4: Cierre
9. No quedan stories → desactivar crons, notificar, deploy, marcar completed

## Story format (obligatorio)

- id, project_id, type, title, user_story, status, priority, estimate
- acceptance: lista de criterios medibles
- scope: in (archivos) y out (exclusiones)
- owner: claude-code

## Prompt template para Claude Code

"Lee plans/PRD-<proyecto>.md para contexto. Implementa story <ID>: [user_story]. Scope IN: [...]. Scope OUT: [...]. Acceptance: [...]. Valida con: [comando]. Al terminar lista archivos modificados y resultado del build."

## Manejo de fallos

- Build falla → dar error a CC, pedir fix
- Hang/signal 9 → kill, dividir story en 2, relanzar
- Bloqueado por decisión de negocio → marcar BLOCKED, notificar humano
- CC no entiende → reformular con más contexto
- Mismo error 3+ veces → BLOCKED, escalar

## Cron Setup Template

```yaml
schedule: every {INTERVAL_MS}ms
prompt: |
  Revisa tmux session {SESSION_NAME}.
  Proyecto: {PROJECT_ID}
  Story actual: {CURRENT_STORY_ID}
  Comando de validación: {BUILD_CMD}
  Si CC pide input → responde según PRD.
  Si terminó → valida build, commit, pasa al siguiente story.
  Si está trabajando → HEARTBEAT_OK.
```

Cambiar 4 variables y listo. Cadencia depende del proyecto:
- Frontend con hot reload → cada 1 min
- Backend pesado con builds largos → cada 5 min

## Regla de oro

Tu agente = PM/Orquestador. Claude Code = Developer.
El agente NO escribe código. Descompone, promptea, desbloquea, valida, reporta.
