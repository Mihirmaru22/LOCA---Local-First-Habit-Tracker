import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type, x-pluto-alpha-token",
};

interface IngestPayload {
  tester_id: string;
  tester_name?: string;
  device_name?: string;
  device_model?: string;
  macos_version?: string;
  app_version: string;
  session_id: string;
  session_started_at?: string;
  session_ended_at?: string;
  events?: Array<{
    event_id: string;
    event_name: string;
    timestamp: string;
    properties: Record<string, unknown>;
  }>;
  snapshots?: Array<{
    snapshot_id: string;
    timestamp: string;
    snapshot_json: Record<string, unknown>;
  }>;
  crashes?: Array<{
    session_id?: string;
    timestamp: string;
    app_version: string;
    macos_version: string;
    current_screen?: string;
    exception_name?: string;
    exception_reason?: string;
    stack_trace?: string;
    breadcrumbs?: Array<unknown>;
    metadata?: Record<string, unknown>;
  }>;
  performance?: Array<{
    session_id?: string;
    trace_name: string;
    duration_ms: number;
    timestamp: string;
    metadata?: Record<string, unknown>;
  }>;
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // 1. Ingestion Token Check (X-Pluto-Alpha-Token)
    const alphaToken = req.headers.get("x-pluto-alpha-token");
    const expectedToken = Deno.env.get("PLUTO_ALPHA_SECRET_TOKEN");
    if (expectedToken && alphaToken !== expectedToken) {
      return new Response(JSON.stringify({ error: "Unauthorized ingestion token" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // 2. Validate payload size (< 1MB)
    const rawBody = await req.text();
    if (rawBody.length > 1_048_576) {
      return new Response(JSON.stringify({ error: "Payload exceeds 1MB limit" }), {
        status: 413,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const payload: IngestPayload = JSON.parse(rawBody);

    if (!payload.tester_id || !payload.session_id || !payload.app_version) {
      return new Response(JSON.stringify({ error: "Missing required fields (tester_id, session_id, app_version)" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // 3. Initialize Supabase Admin Client (service_role)
    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

    // 4. Upsert Tester
    await supabaseAdmin.from("alpha_testers").upsert(
      {
        tester_id: payload.tester_id,
        tester_name: payload.tester_name ?? payload.tester_id,
        device_name: payload.device_name ?? "Mac",
        device_model: payload.device_model ?? "MacBook",
        macos_version: payload.macos_version ?? "macOS",
        app_version: payload.app_version,
        last_seen_at: new Date().toISOString(),
      },
      { onConflict: "tester_id" }
    );

    // 5. Upsert Session
    await supabaseAdmin.from("alpha_sessions").upsert(
      {
        tester_id: payload.tester_id,
        session_id: payload.session_id,
        started_at: payload.session_started_at ?? new Date().toISOString(),
        ended_at: payload.session_ended_at,
        app_version: payload.app_version,
      },
      { onConflict: "session_id" }
    );

    // 6. Ingest Events (Idempotent on event_id)
    const acceptedEventIds: string[] = [];
    if (payload.events && payload.events.length > 0) {
      const formattedEvents = payload.events.slice(0, 200).map((ev) => ({
        tester_id: payload.tester_id,
        session_id: payload.session_id,
        event_id: ev.event_id,
        event_name: ev.event_name,
        timestamp: ev.timestamp,
        properties_json: ev.properties ?? {},
        app_version: payload.app_version,
      }));

      const { error: eventErr } = await supabaseAdmin
        .from("alpha_events")
        .upsert(formattedEvents, { onConflict: "event_id", ignoreDuplicates: true });

      if (!eventErr) {
        acceptedEventIds.push(...payload.events.map((e) => e.event_id));
      }
    }

    // 7. Ingest Snapshots
    const acceptedSnapshotIds: string[] = [];
    if (payload.snapshots && payload.snapshots.length > 0) {
      const formattedSnaps = payload.snapshots.map((s) => ({
        tester_id: payload.tester_id,
        snapshot_id: s.snapshot_id,
        timestamp: s.timestamp,
        snapshot_json: s.snapshot_json,
        app_version: payload.app_version,
      }));

      const { error: snapErr } = await supabaseAdmin
        .from("alpha_state_snapshots")
        .upsert(formattedSnaps, { onConflict: "snapshot_id", ignoreDuplicates: true });

      if (!snapErr) {
        acceptedSnapshotIds.push(...payload.snapshots.map((s) => s.snapshot_id));
      }
    }

    // 8. Ingest Crashes & Performance
    if (payload.crashes && payload.crashes.length > 0) {
      const formattedCrashes = payload.crashes.map((c) => ({
        tester_id: payload.tester_id,
        session_id: c.session_id ?? payload.session_id,
        timestamp: c.timestamp,
        app_version: c.app_version,
        macos_version: c.macos_version,
        current_screen: c.current_screen,
        exception_name: c.exception_name,
        exception_reason: c.exception_reason,
        stack_trace: c.stack_trace,
        breadcrumbs_json: c.breadcrumbs ?? [],
        diagnostic_metadata_json: c.metadata ?? {},
      }));
      await supabaseAdmin.from("alpha_crashes").insert(formattedCrashes);
    }

    if (payload.performance && payload.performance.length > 0) {
      const formattedPerf = payload.performance.map((p) => ({
        tester_id: payload.tester_id,
        session_id: p.session_id ?? payload.session_id,
        trace_name: p.trace_name,
        duration_ms: p.duration_ms,
        timestamp: p.timestamp,
        metadata_json: p.metadata ?? {},
      }));
      await supabaseAdmin.from("alpha_performance").insert(formattedPerf);
    }

    return new Response(
      JSON.stringify({
        status: "success",
        accepted_event_ids: acceptedEventIds,
        accepted_snapshot_ids: acceptedSnapshotIds,
        server_time: new Date().toISOString(),
      }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err: any) {
    return new Response(JSON.stringify({ error: err?.message ?? "Internal Server Error" }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
