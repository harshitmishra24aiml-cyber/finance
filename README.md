# ReRoute: Autonomous Supply-Disruption Desk

> Track: **PS22, AI Automation with n8n**
> Status: idea and design phase (Round 2). Workflow skeletons are included; the full build happens during the hackathon.

When a supplier emails "your shipment is late", ReRoute reads the unstructured notice, works out which customer orders will break and when, negotiates with alternate suppliers in parallel, re-plans if one declines, notifies affected customers, and keeps watching until stock actually covers the orders. Humans approve only spend above a set limit.

![ReRoute n8n canvas (mockup)](docs/screenshots/n8n-canvas-mockup.png)

---

## The problem

Small manufacturers and distributors lose revenue to stockouts because supplier-delay news arrives as a buried email and the response is slow, manual, and scattered across tools.

**Today (about 2 to 4 hours per incident):**
1. Read the supplier email and work out what it actually means
2. Open the inventory sheet and calculate the stockout date
3. Open the orders sheet and find which orders are affected
4. Search for alternate suppliers and email each for a quote
5. Wait, chase, compare replies by hand
6. Get a manager's approval
7. Email each affected customer

## The solution

ReRoute turns that into a closed-loop autonomous workflow:

```
Unstructured email
  → AI extracts facts (SKU, delay, reason, partial offer)
  → AI agent calls tools: inventory, orders, alternates, stockout calculator
  → AI chooses a strategy (wait / expedite / alternate source / split / notify)
  → n8n sends parallel RFQs, waits for replies, parses free-text quotes
  → compare cost versus stockout penalty, approve above limit via Telegram
  → confirm PO, notify at-risk customers
  → watchdog verifies, chases silence, re-plans on rejection, escalates on deadline
```

## Why it is more than a workflow

- **Closed loop:** act, wait, verify, re-plan. It does not stop after sending an email.
- **Real reasoning:** cost-versus-penalty trade-offs, supplier reliability, and partial-shipment options that a fixed rule engine cannot express.
- **Autonomous recovery:** if a supplier rejects, the system re-plans on its own.
- **Audit trail:** every decision is logged with its reasoning.

## Architecture

![Architecture](docs/architecture.png)

| Workflow | Role |
|---|---|
| `w1-intake` | Receives the notice, extracts facts with an LLM, validates, creates a case |
| `w2-analyst-agent` | AI agent with tools computes impact and picks a strategy |
| `w3-executor` | Parallel RFQs, wait for replies, parse quotes, approval, PO, customer notices |
| `w4-watchdog` | Scheduled: verify, chase, re-plan, escalate, close |
| `w5-supplier-simulator` | Simulated suppliers so the negotiation loop is demonstrable |

## Data flow diagrams

**Level 0 (context)**
![DFD Level 0](docs/dfd-level0.png)

**Level 1**
![DFD Level 1](docs/dfd-level1.png)

## Tech stack

n8n, Supabase (PostgreSQL), Gemini / Groq / OpenAI (JSON mode and tool calling), Telegram Bot API, Gmail (webhook fallback), static HTML dashboard.

## Repository structure

```
reroute/
├── README.md
├── docs/                 DFD, architecture, SQL schema
│   ├── src/              Graphviz sources for the diagrams
│   └── screenshots/      canvas and dashboard mockups
├── workflows/            importable n8n workflow skeletons (overview + W1 to W5)
├── data/                 simulated seed data and a sample supplier email
├── dashboard/            static dashboard (demo data)
├── prompts/              versioned LLM prompts
├── .env.example
└── LICENSE
```

## Running it

```bash
# 1. Start n8n
docker run -it --rm -p 5678:5678 -v n8n_data:/home/node/.n8n docker.n8n.io/n8nio/n8n

# 2. Open http://localhost:5678 and import every file in /workflows
#    (Workflows > Import from file)

# 3. Copy .env.example to .env and add your keys. Create the tables from docs/schema.sql
#    and load data/*.csv into Supabase.

# 4. Trigger the demo by POSTing the sample notice:
curl -X POST http://localhost:5678/webhook/reroute-intake \
  -H "Content-Type: application/json" \
  -d "{\"email_text\": \"$(cat data/sample_delay_notice.txt)\"}"
```

> The imported workflows are skeletons: the structure and node order are final, and the prompts, credentials and API calls are wired up during the build.

## Metrics we will demonstrate

| Metric | Manual | ReRoute target |
|---|---|---|
| Time from email to decision | about 3 hours | under 90 seconds |
| Human touches per incident | 6 or more | 0 to 1 |
| Orders protected | n/a | counted per case |
| Revenue protected | n/a | counted per case |

## Human-in-the-loop

A person is asked only when spend exceeds the limit, extraction confidence is low, or a case is still unresolved after two re-plans.

## Roadmap

ERP and Shopify connectors, live carrier and port-tracking APIs for proactive detection, learning supplier reliability over time, multi-case prioritisation over shared inventory, WhatsApp channel, multi-tenant SaaS.

## Team

Add your team name and members here.

## License

MIT
