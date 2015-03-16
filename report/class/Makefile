FILE=report

all:
	pdflatex -shell-escape $(FILE).tex
	pdflatex -shell-escape $(FILE).tex
	bibtex $(FILE)
	pdflatex -shell-escape $(FILE)

clean:
	rm $(FILE).pdf *.aux *.log *.bbl 

