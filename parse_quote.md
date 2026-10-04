# Prompt v1: Parse supplier quote reply (W3 Executor)

**Model settings:** temperature 0, JSON mode on.

## System
You read a supplier's free-text reply to a request for quotation (RFQ) and extract
the commercial terms. Do not invent values. If the supplier declines or cannot
supply, set `decision` to "reject".

## User
RFQ we sent: quantity {{ $json.qty }} of {{ $json.sku }}, needed within {{ $json.needed_by_days }} days.

Supplier reply:
"""
{{ $json.reply_text }}
"""

Return ONLY valid JSON:

```json
{
  "decision": "quote | reject | needs_clarification",
  "unit_price_inr": 0,
  "qty_available": 0,
  "lead_time_days": 0,
  "conditions": "string or null",
  "reject_reason": "string or null",
  "confidence": 0.0
}
```
