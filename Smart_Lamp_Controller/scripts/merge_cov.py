import os
import csv
from collections import defaultdict
from bs4 import BeautifulSoup
from itertools import product

coverage_root = "../project_1/project_1.sim/sim_1/behav/regression_coverage"
output_file = "../project_1/project_1.sim/sim_1/behav/regression_coverage/merged_cov.csv"

hits = defaultdict(int)
covergroup_bins = defaultdict(set)

def split_cross_value(value):
    value = value.strip()

    if value.startswith("(") and value.endswith(")"):
        value = value[1:-1]

    parts = [v.strip() for v in value.split(",") if v.strip()]
    return parts if parts else [value]

def get_covergroup_name(cp_div):
    text = cp_div.find_previous("button", class_="collapsible").get_text(" ", strip=True)
    cg_name = text.replace("Group -", "").strip()

    if "::" in cg_name:
        cg_name = cg_name.split("::")[-1].strip()

    return cg_name

for root, _, files in os.walk(coverage_root):
    if ".reportStyles" in root:
        continue

    for file in files:
        if not file.endswith(".html"):
            continue

        if not file.startswith("grp"):
            continue

        path = os.path.join(root, file)

        with open(path, "r", encoding="utf-8", errors="ignore") as f:
            soup = BeautifulSoup(f.read(), "html.parser")

        for cp in soup.find_all("div", class_="cpcontent"):
            title = cp.find("span")
            if not title:
                continue

            covergroup = get_covergroup_name(cp)
            coverpoint = title.get_text(strip=True).replace("Summary of Cover Point -", "").strip()

            for bin_div in cp.find_all(
                "div",
                class_=lambda cls: cls and any("bintablecontent" in c for c in cls.split())
            ):
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

                                full_bin_name = f"{covergroup}.{coverpoint}.{bin_name}"

                                hits[full_bin_name] += hit_count
                                covergroup_bins[covergroup].add(full_bin_name)

                    # NORMAL COVERPOINT
                    else:
                        if len(cols) >= 2 and cols[1].isdigit():
                            bin_name = cols[0].strip()
                            hit_count = int(cols[1].strip())

                            full_bin_name = f"{covergroup}.{coverpoint}.{bin_name}"

                            hits[full_bin_name] += hit_count
                            covergroup_bins[covergroup].add(full_bin_name)

if os.path.exists(output_file):
    os.remove(output_file)

with open(output_file, "w", newline="", encoding="utf-8") as f:
    writer = csv.writer(f)
    writer.writerow(["bin", "total_hits", "status"])

    for bin_name, total in sorted(hits.items()):
        status = "HIT" if total > 0 else "MISS"
        writer.writerow([bin_name, total, status])

print(f"Result saved in: {output_file}")

print("\nCOVERGROUP COVERAGE:")

total_bins = 0
total_hit_bins = 0

for covergroup, bins in sorted(covergroup_bins.items()):
    bins_count = len(bins)
    hit_bins = sum(1 for b in bins if hits[b] > 0)

    coverage = 100.0 * hit_bins / bins_count if bins_count else 0.0

    total_bins += bins_count
    total_hit_bins += hit_bins

    print(f"  {covergroup}: {coverage:.2f}% ({hit_bins}/{bins_count})")

total_coverage = 100.0 * total_hit_bins / total_bins if total_bins else 0.0

print(f"\nTOTAL COVERAGE: {total_coverage:.2f}% ({total_hit_bins}/{total_bins})")

misses = [b for b, h in hits.items() if h == 0]

if misses:
    print("\nUNCOVERED BINS:")
    for b in sorted(misses):
        print(f"  {b}")
else:
    print("\nALL BINS HAVE BEEN COVERED.")