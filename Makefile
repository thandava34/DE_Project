.PHONY: check

check:
	python -m compileall -q tests
	python -m unittest discover -s tests -v
