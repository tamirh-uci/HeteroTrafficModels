import sys
import networkx as nx
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

	nodeLabels = {}
	for i in range(total):
		nodeLabels[i] = str(i) # make this the N-dimension label that's needed

	chain = nx.Graph() 
	for i in range(total):
		for j in range(total):
			wt = pi["pi"][i][j]
			if (wt > 0):
				chain.add_edge(i, j, weight=wt)

	edgeLabels = dict([((u,v,), d['weight'])
	for u,v,d in chain.edges(data=True)])

	pos = nx.circular_layout(chain)
	nx.draw(chain)
	nx.draw_networkx_edge_labels(chain, pos, edge_labels = edgeLabels, font_size = 12)
	# nx.draw_networkx_labels(chain, pos, nodeLabels, font_size = 12)

	plt.savefig("chain.png") # save as png
	plt.show()

if __name__ == "__main__":
	main(sys.argv)