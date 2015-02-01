paper = htm15

all:
	pdflatex $(paper).tex
	bibtex $(paper)
	pdflatex $(paper).tex

clean:
	rm $(paper).pdf *.aux *.log *.bbl *.blg
	