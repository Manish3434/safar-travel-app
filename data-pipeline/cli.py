#!/usr/bin/env python3
"""
CLI Entrypoint for Safar India-Wide Travel Spots Pipeline (v0.6).
Provides commands for running, monitoring, retrying, reporting, and automated 3-district smoke testing.
"""

import sys
import argparse
from pathlib import Path

# Add data-pipeline root to Python path
sys.path.insert(0, str(Path(__file__).resolve().parent))

from config.settings import SWEEP_ORDER_FILE, DATA_DIR, REPORT_DIR
from config.sweep_order import generate_sweep_order_yaml
from core.database import db_manager
from core.models import DistrictRunStatus
from core.logger import logger
from agents.coordinator import coordinator


def handle_sweep(args):
    """Regenerates sweep_order.yaml based on direction."""
    d_csv = DATA_DIR / "districts.csv"
    order = args.order or "south_to_north"
    out = generate_sweep_order_yaml(d_csv, SWEEP_ORDER_FILE, direction=order)
    logger.success(f"Sweep order updated -> {out}")


def handle_status(args):
    """Displays telemetry summary across all states and districts."""
    db_manager.init_db()
    summary = db_manager.get_status_summary()
    counts = summary["counts"]

    print("\n" + "=" * 65)
    print(" SAFAR TRAVEL DATA PIPELINE — NATIONAL PROGRESS STATUS (v0.6)")
    print("=" * 65)
    print(f" Active Storage Backend:      {summary['backend']}")
    print(f" Total Districts in Scope:    {counts['total']}")
    print("-" * 65)
    print(f"  • Completed (DONE):         {counts['done']}")
    print(f"  • Images Pending:           {counts['images_pending']}")
    print(f"  • Below Target (8 passes):  {counts['below_target']}")
    print(f"  • Needs Review (flagged):   {counts['needs_review']}")
    print(f"  • Running:                  {counts['running']}")
    print(f"  • Failed:                   {counts['failed']}")
    print(f"  • Pending:                  {counts['pending']}")
    print("-" * 65)
    print(f" Total Spots Verified:        {summary['total_spots_verified']}")
    print(f" Total Licensed Photos:       {summary['total_images_collected']}")
    print("=" * 65 + "\n")


def handle_run(args):
    """Runs the pipeline sweep according to flags."""
    coordinator.bootstrap()

    if args.district:
        try:
            dist_id = int(args.district)
            status = coordinator.run_district(dist_id, force=True)
            if status:
                print(f"\nDistrict {dist_id} finished with status: {status.value.upper()}")
        except ValueError:
            logger.error("District code must be an integer LGD code (e.g. 586, 601, 593).")
    elif args.next:
        coordinator.run_next()
    elif args.all:
        coordinator.run_all()
    elif args.state:
        target_state = args.state.upper()
        states = coordinator.sweep_data.get("states", [])
        matched = [s for s in states if s["state_code"] == target_state]
        if not matched:
            logger.error(f"State code '{target_state}' not found in sweep order.")
            return

        s = matched[0]
        s_pos = s["state_position"]
        s_total = len(states)
        for d in s.get("districts", []):
            coordinator.process_district(
                state_pos=s_pos, state_total=s_total,
                state_code=s["state_code"], state_name=s["state_name"],
                dist_pos=d["district_position"], dist_total=len(s["districts"]),
                dist_id=d["district_id"], district_name=d["district_name"],
            )
        coordinator.write_state_summary_report(s["state_code"], s["state_name"], s_pos, s_total, s["districts"])
    else:
        logger.info("Specify --all, --next, --state <CODE>, or --district <LGD_CODE>. Use --help for usage.")


def handle_retry(args):
    """Retries failed and needs_review districts."""
    coordinator.retry_failed()


def handle_report(args):
    """Generates markdown summary report for a specific state."""
    target_state = args.state.upper()
    states = coordinator.sweep_data.get("states", [])
    matched = [s for s in states if s["state_code"] == target_state]
    if not matched:
        logger.error(f"State code '{target_state}' not found in sweep order.")
        return

    s = matched[0]
    coordinator.write_state_summary_report(
        s["state_code"], s["state_name"], s["state_position"], len(states), s.get("districts", [])
    )
    report_file = REPORT_DIR / f"state_{target_state}_summary.md"
    print(f"\nReport generated: {report_file}")
    if report_file.exists():
        with open(report_file, "r", encoding="utf-8") as f:
            print(f.read())


def handle_smoke_test(args):
    """
    Executes automated end-to-end smoke test across 3 distinct archetypes:
      1. South Goa (GA, LGD 586): High-density coastal & heritage district
      2. Ariyalur (TN, LGD 601): Rural district with Gangaikonda Cholapuram & fossils
      3. Nicobar (AN, LGD 593): Remote island district testing Rule 8 sensitive masking
    """
    print("\n" + "=" * 70)
    print(" EXECUTING AUTOMATED 3-DISTRICT ARCHETYPE SMOKE TEST (v0.6)")
    print("=" * 70)

    coordinator.bootstrap()

    test_targets = [
        {"name": "South Goa", "state": "GA", "lgd": 586, "archetype": "High Density Coastal"},
        {"name": "Ariyalur", "state": "TN", "lgd": 601, "archetype": "Rural Heritage / Fossil"},
        {"name": "Nicobar", "state": "AN", "lgd": 593, "archetype": "Remote Island / Sensitive"},
    ]

    results = []

    for target in test_targets:
        print(f"\n--- Testing Archetype: {target['archetype']} ({target['name']}, LGD {target['lgd']}) ---")
        st = coordinator.run_district(target["lgd"], force=True)
        runs_in_state = db_manager.get_districts_in_state(target["state"])
        matched = [r for r in runs_in_state if target["name"].lower() in r.district_name.lower()]
        run_record = matched[0] if matched else None
        spots = run_record.spots_verified if run_record else 0
        images = run_record.images_collected if run_record else 0
        status_str = st.value.upper() if st else "FAILED"
        results.append({
            "name": target["name"],
            "lgd": target["lgd"],
            "archetype": target["archetype"],
            "status": status_str,
            "spots": spots,
            "images": images,
        })

    print("\n" + "=" * 70)
    print(" 3-DISTRICT SMOKE TEST AUDIT REPORT")
    print("=" * 70)
    print(f"{'District':<14} {'LGD':<6} {'Archetype':<24} {'Status':<14} {'Spots':<7} {'Photos'}")
    print("-" * 70)
    all_passed = True
    for r in results:
        passed = r["status"] in ("DONE", "IMAGES_PENDING", "BELOW_TARGET") and r["spots"] > 0
        status_flag = "✓ PASS" if passed else "✗ FAIL"
        if not passed:
            all_passed = False
        print(f"{r['name']:<14} {r['lgd']:<6} {r['archetype']:<24} {r['status']:<14} {r['spots']:<7} {r['images']} {status_flag}")
    print("=" * 70)

    if all_passed:
        print("★ ALL 3 ARCHETYPE SMOKE TESTS PASSED CLEANLY! ★\n")
        return 0
    else:
        print("⚠ SOME SMOKE TESTS FLAGGED ISSUES — CHECK LOGS ABOVE.\n")
        return 1


def main():
    parser = argparse.ArgumentParser(description="Safar India Travel Spots Data Pipeline CLI (v0.6)")
    subparsers = parser.add_subparsers(dest="command")

    # sweep
    p_sweep = subparsers.add_parser("sweep", help="Recompute and inspect geographic sweep order")
    p_sweep.add_argument("--order", choices=["south_to_north", "north_to_south"], default="south_to_north")

    # status
    subparsers.add_parser("status", help="Show nationwide harvest progress summary")

    # run
    p_run = subparsers.add_parser("run", help="Execute harvesting sweep")
    p_run.add_argument("--all", action="store_true", help="Run full nationwide continuous sweep")
    p_run.add_argument("--next", action="store_true", help="Process exactly the next pending district")
    p_run.add_argument("--state", type=str, help="Process all districts of a specific state (e.g. GA, TN)")
    p_run.add_argument("--district", type=int, help="Process a single district by LGD code (e.g. 586, 601, 593)")

    # retry
    subparsers.add_parser("retry", help="Retry all failed or needs_review districts")

    # report
    p_rep = subparsers.add_parser("report", help="Generate and view state summary report")
    p_rep.add_argument("--state", type=str, required=True, help="State code (e.g. GA, TN, AN)")

    # test-smoke
    subparsers.add_parser("test-smoke", help="Run automated end-to-end smoke test on 3 archetypes (South Goa, Ariyalur, Nicobar)")

    args = parser.parse_args()
    if not args.command:
        parser.print_help()
        sys.exit(1)

    if args.command == "sweep":
        handle_sweep(args)
    elif args.command == "status":
        handle_status(args)
    elif args.command == "run":
        handle_run(args)
    elif args.command == "retry":
        handle_retry(args)
    elif args.command == "report":
        handle_report(args)
    elif args.command == "test-smoke":
        code = handle_smoke_test(args)
        sys.exit(code or 0)


if __name__ == "__main__":
    main()
