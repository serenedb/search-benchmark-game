CORPUS := $(shell pwd)/marco.corpus.json
export

WIKI_SRC = "https://www.dropbox.com/s/wwnfnu441w1ec9p/wiki-articles.json.bz2"
MSMARCO_SRC = "https://msmarco.z22.web.core.windows.net/msmarcoranking/collection.tar.gz"

COMMANDS ?= TOP_10 TOP_100

# ENGINES ?= tantivy-0.13 lucene-8.4.0 pisa-0.8.2 rucene-0.1 bleve-0.8.0-scorch rucene-0.1 tantivy-0.11 tantivy-0.14 tantivy-0.15 tantivy-0.16 tantivy-0.17 tantivy-0.18 tantivy-0.19
# ENGINES ?= tantivy-0.16 lucene-8.10.1 pisa-0.8.2 bleve-0.8.0-scorch bluge-0.2.2 rucene-0.1
# ENGINES ?= tantivy-0.16 tantivy-0.17 tantivy-0.18 tantivy-0.19
# ENGINES ?= tantivy-0.22 tantivy-0.24 tantivy-0.25 tantivy-main lucene-10.3.0 lucene-10.3.0-bp
ENGINES ?= iresearch-26.03.1
PORT ?=9876 
WARMUP_TIME ?= 20
NUM_ITER ?= 10

help:
	@grep '^[^#[:space:]].*:' Makefile

all: index

corpus:
	@echo "--- Downloading $(WIKI_SRC) ---"
	@curl -# -L "$(WIKI_SRC)" | bunzip2 -c | python3 corpus_transform.py wiki > $(CORPUS)

corpus-msmarco:
	@echo "--- Downloading $(MSMARCO_SRC) ---"
	@curl -# -L "$(MSMARCO_SRC)" | tar -xzO collection.tsv | python3 corpus_transform.py marco > $(CORPUS)

clean:
	@echo "--- Cleaning directories ---"
	@rm -fr results
	@for engine in $(ENGINES); do cd ${shell pwd}/engines/$$engine && make clean ; done

index:
	@echo "--- Indexing corpus ---"
	@for engine in $(ENGINES); do cd ${shell pwd}/engines/$$engine && make index ; done

bench:
	@echo "--- Benchmarking ---"
	@rm -fr results
	@mkdir results
	@python3 src/client.py queries.txt $(ENGINES)

compile:
	@echo "--- Compiling binaries ---"
	@for engine in $(ENGINES); do cd ${shell pwd}/engines/$$engine && make compile ; done

serve:
	@echo "--- Serving results ---"
	@cp results.json web/build/results.json
	@cd web/build && python3 -m http.server $(PORT)
