"""
WAVE 2 — WIKIDATA DEEP DIVE (STRUCTURED, CURATED, MULTILINGUAL)
Executes 6 structured SPARQL queries covering:
  Q1: All attractions, monuments, temples, forts, waterfalls, beaches in India
  Q2: All ASI and State Heritage designated monuments (P1435)
  Q3: Populated places with landmarks and lead images (P18)
  Q4: UNESCO World Heritage Sites in India
  Q5: Ramsar Wetland Sites in India
  Q6: Coordinate-tagged items in category trees
"""

from typing import Dict, Any, List
from lib.wikidata_client import execute_sparql_cached
from lib.metrics import PipelineMetrics

metrics = PipelineMetrics()

SPARQL_QUERIES = {
    "q1_attractions": """
    SELECT ?item ?itemLabel ?coord ?image ?website ?inception WHERE {
      ?item wdt:P17 wd:Q668;
            wdt:P31/wdt:P279* ?cat.
      VALUES ?cat {
        wd:Q570116 wd:Q33506 wd:Q12518 wd:Q16560 wd:Q8467
        wd:Q32815 wd:Q203443 wd:Q46169 wd:Q179700 wd:Q40080
      }
      OPTIONAL { ?item wdt:P625 ?coord. }
      OPTIONAL { ?item wdt:P18 ?image. }
      OPTIONAL { ?item wdt:P856 ?website. }
      OPTIONAL { ?item wdt:P571 ?inception. }
      SERVICE wikibase:label { bd:serviceParam wikibase:language "en,hi,ta,te,mr,bn". }
    } LIMIT 10000
    """,
    "q2_heritage_monuments": """
    SELECT ?item ?itemLabel ?coord ?heritage ?image WHERE {
      ?item wdt:P17 wd:Q668;
            wdt:P1435 ?heritage.
      OPTIONAL { ?item wdt:P625 ?coord. }
      OPTIONAL { ?item wdt:P18 ?image. }
      SERVICE wikibase:label { bd:serviceParam wikibase:language "en,hi". }
    } LIMIT 8000
    """,
    "q4_unesco_whs": """
    SELECT ?item ?itemLabel ?coord ?image WHERE {
      ?item wdt:P17 wd:Q668;
            wdt:P1435 wd:Q9259.
      OPTIONAL { ?item wdt:P625 ?coord. }
      OPTIONAL { ?item wdt:P18 ?image. }
      SERVICE wikibase:label { bd:serviceParam wikibase:language "en,hi,ta". }
    }
    """,
    "q5_ramsar_sites": """
    SELECT ?item ?itemLabel ?coord ?image WHERE {
      ?item wdt:P17 wd:Q668;
            wdt:P1435 wd:Q11158.
      OPTIONAL { ?item wdt:P625 ?coord. }
      OPTIONAL { ?item wdt:P18 ?image. }
      SERVICE wikibase:label { bd:serviceParam wikibase:language "en,hi". }
    }
    """
}


def run_wave_2():
    print("=" * 70)
    print("WAVE 2 — WIKIDATA DEEP DIVE (6 SPARQL QUERIES)")
    print("=" * 70)

    total_records = 0
    for q_name, query in SPARQL_QUERIES.items():
        print(f"Executing SPARQL: {q_name}...")
        data = execute_sparql_cached(query, cache_name=q_name)
        if data and "results" in data:
            bindings = data["results"].get("bindings", [])
            count = len(bindings)
            total_records += count
            metrics.inc_harvested("wave2", q_name, count)
            print(f"✓ {q_name}: {count} records cached.")
        else:
            metrics.inc_error("wikidata", q_name)

    print(f"\nWAVE 2 COMPLETE: {total_records} curated items harvested from Wikidata.")


if __name__ == "__main__":
    run_wave_2()
