DELS = $(wildcard *.out) $(wildcard *.aux)  $(wildcard *.log)  $(wildcard *.toc) $(wildcard admin/*.aux) $(wildcard user/*.aux) $(wildcard builder/*.aux) $(wildcard *.idx) $(wildcard *.ilg) $(wildcard *.ind) 

pdf:
	pdflatex handbook.tex
	pdflatex handbook.tex
	makeindex handbook.idx
	pdflatex handbook.tex
	pdflatex handbook.tex

clean:
	for i in $(DELS); do rm -v $$i ; done

sync:
	rsync -avHP --rsh="ssh -p 22222" handbook.pdf download.lesslinux.org:/var/www/handbook/LessLinux_handbook_current.pdf 
	

