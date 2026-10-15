#!/usr/bin/env python3
"""Explainable, offline analysis for Battery Brain CSV exports; standard library only."""
from __future__ import annotations

import argparse
import csv
import json
import statistics
import sys
from datetime import datetime
from pathlib import Path
from typing import Any

REQUIRED = {"timestamp", "level_percent", "plugged"}
MAX_GAP_MINUTES = 180


def parse_timestamp(value: str) -> datetime:
    return datetime.fromisoformat(value.strip().replace("Z", "+00:00"))


def load_samples(path: Path) -> list[dict[str, Any]]:
    with path.open("r", newline="", encoding="utf-8-sig") as handle:
        reader = csv.DictReader(handle)
        if not reader.fieldnames or not REQUIRED.issubset(set(reader.fieldnames)):
            raise ValueError("CSV is missing required columns: " + ", ".join(sorted(REQUIRED)))
        samples = []
        for line_no, row in enumerate(reader, start=2):
            try:
                timestamp = parse_timestamp(row["timestamp"])
                level = float(row["level_percent"])
                if not 0 <= level <= 100:
                    raise ValueError("level outside 0..100")
                plugged = str(row["plugged"]).strip().lower() in {"1", "true", "yes"}
                temp = optional_float(row.get("temperature_c"))
                samples.append({
                    "timestamp": timestamp,
                    "level_percent": level,
                    "plugged": plugged,
                    "temperature_c": temp,
                    "status": (row.get("status") or "unknown").strip().lower(),
                    "voltage_mv": optional_float(row.get("voltage_mv")),
                    "current_now_ua": optional_float(row.get("current_now_ua")),
                })
            except (ValueError, TypeError, KeyError) as exc:
                print(f"Warning: skipped malformed CSV row {line_no}: {exc}", file=sys.stderr)
        samples.sort(key=lambda item: item["timestamp"])
        return samples


def optional_float(value: Any) -> float | None:
    if value is None or str(value).strip() == "":
        return None
    try:
        return float(value)
    except (ValueError, TypeError):
        return None


def analyze(samples: list[dict[str, Any]]) -> dict[str, Any]:
    if not samples:
        raise ValueError("No valid samples found. Capture samples over time and export again.")

    start, end = samples[0], samples[-1]
    span_hours = max(0.0, (end["timestamp"] - start["timestamp"]).total_seconds() / 3600.0)
    rates = []
    for previous, current in zip(samples, samples[1:]):
        elapsed_minutes = (current["timestamp"] - previous["timestamp"]).total_seconds() / 60.0
        if elapsed_minutes <= 0 or elapsed_minutes > MAX_GAP_MINUTES:
            continue
        if previous["plugged"] or current["plugged"]:
            continue
        # Only count drain; charging/refill periods and small level increases are not discharge.
        drop = previous["level_percent"] - current["level_percent"]
        if drop > 0:
            rates.append(drop / (elapsed_minutes / 60.0))

    total_discharged = sum(
        max(0.0, a["level_percent"] - b["level_percent"])
        for a, b in zip(samples, samples[1:])
        if not a["plugged"] and not b["plugged"]
        and 0 < (b["timestamp"] - a["timestamp"]).total_seconds() <= MAX_GAP_MINUTES * 60
    )
    temperatures = [s["temperature_c"] for s in samples if s["temperature_c"] is not None]
    latest_temp = end["temperature_c"]
    median_rate = statistics.median(rates) if rates else None
    high_rate_threshold = max(5.0, (median_rate or 0.0) * 2.0)
    high_drain_intervals = sum(rate >= high_rate_threshold for rate in rates) if rates else 0

    recommendations = []
    if span_hours < 2:
        recommendations.append("Collect data for at least 2–4 hours (ideally a full day) before judging drain; short windows are noisy.")
    if len(samples) < 8:
        recommendations.append("Keep background sampling enabled and capture a few manual samples. More samples improve confidence.")
    if rates:
        avg_rate = statistics.mean(rates)
        recommendations.append(f"Observed unplugged discharge across eligible adjacent samples: {avg_rate:.2f} percentage points/hour on average. This is an estimate, not a battery health diagnosis.")
        if avg_rate >= 5:
            recommendations.append("Drain is high in this sample set. Compare screen time, mobile signal, hotspot/GPS use, sync and recently installed apps in Android Settings → Battery before changing anything.")
        elif avg_rate <= 1.5:
            recommendations.append("Observed discharge is relatively low during measured intervals. Avoid aggressive background-killing tweaks; keep the current setup and compare another day.")
        else:
            recommendations.append("Compare another day with similar usage before changing several settings at once.")
    else:
        recommendations.append("No usable unplugged discharge interval found. Leave the charger disconnected for a while and collect at least two readings.")
    if high_drain_intervals:
        recommendations.append(f"{high_drain_intervals} interval(s) had a higher-than-baseline drain rate. They may reflect usage changes or coarse battery percentages; they do not identify an app by themselves.")
    if latest_temp is not None and latest_temp >= 40:
        recommendations.append(f"Latest reported battery temperature is {latest_temp:.1f} °C. Reduce demanding use and charging heat; let the device cool naturally.")
    elif temperatures and max(temperatures) >= 40:
        recommendations.append(f"At least one sample reached {max(temperatures):.1f} °C. Check when that occurred and avoid sustained heat.")
    else:
        recommendations.append("No sample reached 40 °C; the sampled values alone cannot rule out brief temperature spikes.")
    if end["level_percent"] <= 20:
        recommendations.append("Charge is at or below 20%. Enable Android Battery Saver if you need the remaining charge to last.")
    if any(s["health"] == "overheat" for s in samples):
        recommendations.append("Android reported battery health as overheat at least once. Stop heavy use/charging and investigate if it persists.")
    return {
        "sample_count": len(samples),
        "start": start["timestamp"].isoformat(),
        "end": end["timestamp"].isoformat(),
        "span_hours": round(span_hours, 2),
        "start_percent": start["level_percent"],
        "end_percent": end["level_percent"],
        "estimated_unplugged_drop_percent_points": round(total_discharged, 2),
        "discharge_rate_percent_points_per_hour_mean": round(statistics.mean(rates), 2) if rates else None,
        "discharge_rate_percent_points_per_hour_median": round(median_rate, 2) if median_rate is not None else None,
        "max_temperature_c": round(max(temperatures), 1) if temperatures else None,
        "high_drain_interval_count": high_drain_intervals,
        "recommendations": recommendations,
        "limitations": [
            "Android may delay WorkManager runs; timestamps are observations, not guaranteed fixed-interval measurements.",
            "Battery percentage is coarse and varies with load; rate estimates can be noisy.",
            "This CSV does not include screen-on time or reliable per-app power attribution.",
            "Current and charge-counter fields may be unavailable on this kernel/build.",
            "This tool recommends changes only; it does not modify Android settings or kill apps."
        ]
    }


def render_report(result: dict[str, Any]) -> str:
    lines = [
        "BATTERY BRAIN — LOCAL BATTERY REPORT",
        "=" * 42,
        f"Samples: {result['sample_count']}",
        f"Window: {result['span_hours']} hours",
        f"First / last charge: {result['start_percent']:.0f}% / {result['end_percent']:.0f}%",
        f"Estimated unplugged drop: {result['estimated_unplugged_drop_percent_points']:.1f} percentage points",
        f"Mean estimated unplugged drain: {result['discharge_rate_percent_points_per_hour_mean'] if result['discharge_rate_percent_points_per_hour_mean'] is not None else 'not enough data'} %/hour",
        f"Median interval drain: {result['discharge_rate_percent_points_per_hour_median'] if result['discharge_rate_percent_points_per_hour_median'] is not None else 'not enough data'} %/hour",
        f"Maximum sampled battery temperature: {result['max_temperature_c'] if result['max_temperature_c'] is not None else 'unavailable'} °C",
        "",
        "RECOMMENDATIONS",
    ]
    lines.extend(f"{index}. {text}" for index, text in enumerate(result["recommendations"], 1))
    lines.extend(["", "LIMITATIONS"])
    lines.extend(f"- {item}" for item in result["limitations"])
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("csv_file", type=Path, help="Battery Brain CSV exported from the Android app")
    parser.add_argument("--json", action="store_true", help="Print machine-readable JSON instead of a text report")
    parser.add_argument("--out", type=Path, help="Optional path to save a report")
    args = parser.parse_args()
    try:
        result = analyze(load_samples(args.csv_file))
    except (OSError, ValueError, csv.Error) as exc:
        print(f"Battery analysis failed: {exc}", file=sys.stderr)
        return 2
    output = json.dumps(result, indent=2, ensure_ascii=False) if args.json else render_report(result)
    print(output)
    if args.out:
        try:
            args.out.write_text(output + "\n", encoding="utf-8")
        except OSError as exc:
            print(f"Could not write report: {exc}", file=sys.stderr)
            return 2
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
