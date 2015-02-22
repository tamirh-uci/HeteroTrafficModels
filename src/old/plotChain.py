import sys
import networkx as nx
import pygraphviz as pgv
import scipy.io
import matplotlib.pyplot as plt

def main(args):
	pi = scipy.io.loadmat(args[1])
	dims = scipy.io.loadmat(args[2])

	total = 1
	for i in range(len(dims["dims"][0])):
		total = total * dims["dims"][0][i]

	# Debug
	print dims["dims"]
	print total
	print pi["pi"]

	# chain = nx.Graph() 
	chain = pgv.AGraph(directed=True)
	for i in range(total):
		for j in range(total):
			wt = pi["pi"][i][j]
			if (wt > 0):
				chain.add_edge(i + 1, j + 1, weight=wt)
				edge = chain.get_edge(i + 1, j + 1)
				edge.attr['label'] = wt

	pos = nx.circular_layout(chain)
	# pos = nx.shell_layout(chain)
	# nx.draw_networkx_edge_labels(chain, pos, edge_labels = edgeLabels, label_pos = 0.3)
	# nx.draw_networkx_labels(chain, pos, nodeLabels, font_size = 12)
	# nx.draw(chain)

	chain.layout(prog='dot')
	chain.draw('chain.png')

	# plt.savefig("chain.png") # save as png
	# plt.show()

if __name__ == "__main__":
	main(sys.argv)
