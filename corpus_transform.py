import argparse
import json
import random
import re
import sys

PTN = re.compile("[^a-zA-Z]+")


def transform(text):
    return PTN.sub(" ", text.lower())


def iter_wiki(stream):
    for line in stream:
        try:
            doc = json.loads(line)
        except ValueError:
            continue

        if doc.get("url", "") == "":
            continue

        yield doc["url"], doc["body"]


def iter_marco(stream):
    for line in stream:
        line = line.rstrip("\n")
        if not line:
            continue

        parts = line.split("\t", 1)
        if len(parts) != 2:
            continue

        pid, passage = parts
        if not passage:
            continue

        yield pid, passage


SOURCES = {
    "wiki": iter_wiki,
    "marco": iter_marco,
}


def main():
    parser = argparse.ArgumentParser(
        description="Transform a raw corpus into the benchmark JSON format."
    )
    parser.add_argument(
        "source",
        choices=sorted(SOURCES.keys()),
        help="Input corpus format: 'wiki' (JSON lines with url/body) or 'marco' (TSV pid\\tpassage).",
    )
    args = parser.parse_args()

    random.seed(42)

    for doc_id, body in SOURCES[args.source](sys.stdin):
        out = {
            "id": doc_id,
            "text": transform(body),
            "sort_field": random.randint(0, 2**32 - 1),
        }
        print(json.dumps(out))


if __name__ == "__main__":
    main()
