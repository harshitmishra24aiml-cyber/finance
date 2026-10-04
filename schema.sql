-- ReRoute database schema (Supabase / PostgreSQL)

create table suppliers (
  supplier_id text primary key,
  name text not null,
  role text check (role in ('primary','alternate')),
  skus_covered text[],
  unit_price_inr numeric,
  lead_time_days int,
  reliability_score numeric,
  min_order_qty int,
  email text
);

create table skus (
  sku text primary key,
  description text,
  primary_supplier_id text references suppliers(supplier_id),
  unit_cost_inr numeric
);

create table inventory (
  sku text primary key references skus(sku),
  on_hand int not null,
  daily_burn int not null,
  reorder_point int
);

create table orders (
  order_id text primary key,
  customer text,
  customer_email text,
  sku text references skus(sku),
  qty int,
  promised_date date,
  order_value_inr numeric,
  priority text check (priority in ('high','medium','low')),
  status text default 'open'  -- open | at_risk | protected | late
);

create table cases (
  case_id text primary key,
  created_at timestamptz default now(),
  status text default 'open',   -- open | sourcing | awaiting_approval | executing | verifying | closed | escalated
  supplier_id text references suppliers(supplier_id),
  sku text references skus(sku),
  extracted_facts jsonb,        -- sku, new_eta, delay_days, reason, partial_offer, confidence
  impact jsonb,                 -- stockout_date, orders_at_risk, revenue_exposure_inr
  plan jsonb,                   -- strategy, justification, rfq_targets
  replan_count int default 0,
  deadline timestamptz,
  human_touches int default 0,
  closed_at timestamptz
);

create table rfqs (
  rfq_id bigserial primary key,
  case_id text references cases(case_id),
  supplier_id text references suppliers(supplier_id),
  sent_at timestamptz default now(),
  status text default 'sent',   -- sent | quoted | rejected | no_response | chased
  quote jsonb,                  -- unit_price, qty, lead_time_days, conditions
  resume_url text
);

create table actions_log (
  log_id bigserial primary key,
  case_id text references cases(case_id),
  ts timestamptz default now(),
  actor text,                   -- agent | watchdog | human | simulator
  action text,
  reasoning text
);
