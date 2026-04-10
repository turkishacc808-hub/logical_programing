PYTHON := python3

.PHONY: all experiments react report clean

all: report

experiments:
	$(PYTHON) scripts/run_experiments.py

react:
	$(PYTHON) scripts/react_cycle.py

report: experiments react
	cd report && xelatex -interaction=nonstopmode report.tex
	cd report && xelatex -interaction=nonstopmode report.tex
	cp report/report.pdf lab3_report.pdf

clean:
	rm -f report/*.aux report/*.log report/*.out
