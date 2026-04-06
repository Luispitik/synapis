---
name: instinct-status
description: Muestra todos los instincts aprendidos (proyecto + globales) con confidence scoring
command: true
---

# /instinct-status

## Qué hace

Muestra el estado de todos los instincts del sistema NorteIA Continuous Learning.

## Implementación

1. Detectar proyecto actual (git remote hash o path)
2. Leer instincts de `~/.claude/homunculus/projects/<hash>/instincts/personal/`
3. Leer instincts globales de `~/.claude/homunculus/instincts/personal/`
4. Mostrar tabla con: ID, trigger, confidence, domain, scope, marca

## Formato de salida

```
══════════════════════════════════════════════════
  INSTINCT STATUS — NorteIA Continuous Learning
  Proyecto: blackstone-pitch (a1b2c3d4e5f6)
══════════════════════════════════════════════════

PROJECT-SCOPED (4 instincts):
  ● html-interactivo-para-pitch    [pitch]     0.80  norteia
  ● blackstone-3-lineas-servicio   [contratos] 0.75  norteia
  ● roi-calculator-obligatorio     [pitch]     0.70  norteia
  ● diagnostico-8-areas            [lead]      0.65  norteia

GLOBAL (12 instincts):
  ● siempre-plan-director-ai-first [contratos] 0.95  norteia
  ● leer-skill-md-antes-ejecutar   [workflow]  0.90  —
  ● 5-entregables-por-modulo       [formacion] 0.90  norteia
  ● formato-correccion-obligatorio [workflow]  0.90  —
  ● castellano-por-defecto         [workflow]  0.95  —
  ● research-first-antes-generar   [formacion] 0.85  norteia
  ● marca-correcta-sin-preguntar   [workflow]  0.90  —
  ○ nueva-observacion-pendiente    [n8n]       0.35  —

  ● = confidence ≥ 0.5  ○ = tentativo (<0.5)

Dominios: contratos(3) formacion(2) pitch(3) workflow(4) lead(1) n8n(1)
Total: 16 instincts | 4 project | 12 global
══════════════════════════════════════════════════
```

## Lo que NO hacer
- No inventar instincts que no existan en los ficheros
- No mostrar observaciones crudas, solo instincts procesados
- No modificar ficheros — este comando es solo lectura
