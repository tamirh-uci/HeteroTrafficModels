FILE=report

all:
	pdflatex $(FILE).tex
	pdflatex $(FILE).tex
	bibtex $(FILE)
	pdflatex $(FILE)

clean:
	rm $(FILE).pdf *.aux *.log *.bbl 

