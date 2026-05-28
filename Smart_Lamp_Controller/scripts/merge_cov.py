import os
import csv
from collections import defaultdict
from bs4 import BeautifulSoup
from itertools import product

coverage_root = "../smart_lamp_controller.sim/sim_1/behav/regression_coverage"
output_file = "../smart_lamp_controller.sim/sim_1/behav/regression_coverage/merged_cov.csv"

hits = defaultdict(int)

def split_cross_value(value):
    value = value.strip()

    if value.startswith("(") and value.endswith(")"):
        value = value[1:-1]

    parts = [v.strip() for v in value.split(",") if v.strip()]
    return parts if parts else [value]

for root, _, files in os.walk(coverage_root):
    for file in files:
        if not file.endswith(".html"):
            continue

        path = os.path.join(root, file)
        
        with open(path, "r", encoding="utf-8", errors="ignore") as f:
            soup = BeautifulSoup(f.read(), "html.parser")

        for cp in soup.find_all("div", class_="cpcontent"):
            title = cp.find("span")
            if not title:
                continue

            coverpoint = title.get_text(strip=True).replace("Summary of Cover Point -", "").strip()

            for bin_div in cp.find_all("div", class_=lambda cls: cls and any("bintablecontent" in c for c in cls.split())):
                table = bin_div.find("table")
                if not table:
                     continue

                rows = table.find_all("tr")

                for row in rows[1:]:
                    cols = [c.get_text(" ", strip=True) for c in row.find_all("td")]

                    # CROSS
                    if "crosstable" in table.get("class", []):
                        if len(cols) >= 4 and cols[-2].isdigit():

                            cross_values = cols[:-2]
                            hit_count = int(cols[-2])

                            split_values = [split_cross_value(v) for v in cross_values]

                            for combination in product(*split_values):
                                bin_name = " x ".join(combination)
                                if "*" in bin_name:
                                    continue
                                hits[f"{coverpoint}.{bin_name}"] += hit_count

                    # COVERPOINT NORMAL
                    else:
                        if len(cols) >= 2 and cols[1].isdigit():

                            bin_name = cols[0].strip()
                            hit_count = int(cols[1].strip())

                            hits[f"{coverpoint}.{bin_name}"] += hit_count

if os.path.exists(output_file):
    os.remove(output_file)

with open(output_file, "w", newline="", encoding="utf-8") as f:
    writer = csv.writer(f)
    writer.writerow(["bin", "total_hits", "status"])

    for bin_name, total in sorted(hits.items()):
        status = "HIT" if total > 0 else "MISS"
        writer.writerow([bin_name, total, status])

misses = [b for b, h in hits.items() if h == 0]

print(f"Result saved in: {output_file}")

if misses:
    print("\nUNCOVERED BINS:")
    for b in sorted(misses):
        print(f"  {b}")
else:
    print("\nALL BINS HAVE BEEN COVERED.")