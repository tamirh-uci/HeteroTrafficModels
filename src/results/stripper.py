import os
import sys

dirPath = sys.argv[1]
for dirpath, dnames, fnames in os.walk(dirPath):
	for fname in fnames:
		if fname.endswith(".log"):
			fout = open(fname.replace(".log", ".csv"), "w")
			fhandle = open(fname, "r")
			lines = []
			append = False
			for line in fhandle:
				if append: 
					fout.write(line)
				if "state_index" in line:
					append = True

