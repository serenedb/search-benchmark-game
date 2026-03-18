CORPUS := $(shell pwd)/corpus.json
export

WIKI_SRC = "https://www.dropbox.com/s/wwnfnu441w1ec9p/wiki-articles.json.bz2"

COMMANDS ?= TOP_100_COUNT TOP_100 COUNT

ENGINES ?= tantivy-0.25 lucene-10.3.0 iresearch
PORT ?= 8080
WARMUP_TIME ?= 60
NUM_ITER ?= 10
SERVE_TYPE ?= serve

help:
	@grep '^[^#[:space:]].*:' Makefile

all: index

corpus:
	@echo "--- Downloading $(WIKI_SRC) ---"
	@curl -# -L "$(WIKI_SRC)" | bunzip2 -c | python3 corpus_transform.py > $(CORPUS)

clean:
	@echo "--- Cleaning directories ---"
	@rm -fr results
	@for engine in $(ENGINES); do cd ${shell pwd}/engines/$$engine && make clean ; done

index:
	@echo "--- Indexing corpus ---"
	@for engine in $(ENGINES); do cd ${shell pwd}/engines/$$engine && make index ; done

bench:
	@echo "--- Benchmarking ---"
	@python3 src/client.py queries.txt $(ENGINES)

merge:
	@echo "--- Merging results ---"
	@python3 src/client.py --merge

compile:
	@echo "--- Compiling binaries ---"
	@for engine in $(ENGINES); do cd ${shell pwd}/engines/$$engine && make compile ; done

serve:
	@echo "--- Serving results ---"
	@cp results.json web/build/results.json
	@cd web/build && python3 ../../web/serve.py $(PORT)
